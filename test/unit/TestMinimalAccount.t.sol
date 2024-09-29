// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestMinimalAccount is Test {
    using MessageHashUtils for bytes32;

    DeployMinimalAccount deployMinimal;
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    address entryPointAddress;

    address randomuser = payable(makeAddr("randomUser"));

    uint256 constant AMOUNT = 1e18;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        deployMinimal = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();

        entryPointAddress = helperConfig.getConfig().entryPoint;
    }

    /*//////////////////////////////////////////////////////////////
                                EXECUTE
    //////////////////////////////////////////////////////////////*/

    function test_OwnerCanExecute() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address targetContractAddress = address(usdc);
        uint256 ethValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(targetContractAddress, ethValue, functionData);

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function test_NonOwnerCannotExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address targetContractAddress = address(usdc);
        uint256 ethValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // Act
        vm.prank(randomuser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(targetContractAddress, ethValue, functionData);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNT ABSTRACTION
    //////////////////////////////////////////////////////////////*/

    function test_RecoverSignedOp() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address targetContractAddress = address(usdc);
        uint256 ethValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData =
            abi.encodeWithSelector(minimalAccount.execute.selector, targetContractAddress, ethValue, functionData);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));
        bytes32 userOperationHash = IEntryPoint(entryPointAddress).getUserOpHash(packedUserOp);

        // Act
        address signer = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);
        // Assert
        assertEq(signer, minimalAccount.owner());
    }

    function test_ValidationOfUserOps() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address targetContractAddress = address(usdc);
        uint256 ethValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData =
            abi.encodeWithSelector(minimalAccount.execute.selector, targetContractAddress, ethValue, functionData);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));
        bytes32 userOperationHash = IEntryPoint(entryPointAddress).getUserOpHash(packedUserOp);

        uint256 missingAccountFunds = 1e18;

        // Act
        vm.prank(entryPointAddress);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecute() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address targetContractAddress = address(usdc);
        uint256 ethValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData =
            abi.encodeWithSelector(minimalAccount.execute.selector, targetContractAddress, ethValue, functionData);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));
        // bytes32 userOperationHash = IEntryPoint(entryPointAddress).getUserOpHash(packedUserOp);

        vm.deal(address(minimalAccount), 1 ether);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        // Act
        vm.deal(randomuser, 1 ether);
        vm.deal(address(minimalAccount), 1 ether);
        vm.prank(randomuser);
        IEntryPoint(entryPointAddress).handleOps(ops, payable(randomuser));
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
