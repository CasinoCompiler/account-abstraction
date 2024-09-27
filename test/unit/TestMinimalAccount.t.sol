// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract TestMinimalAccount is Test {
    DeployMinimalAccount deployMinimal;
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;

    address randomuser = makeAddr("randomUser");

    uint256 constant AMOUNT = 1e18;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        deployMinimal = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
    }

    /*//////////////////////////////////////////////////////////////
                                WORKFLOW
    //////////////////////////////////////////////////////////////*/

    function test_OwnerCanExecute() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address targetContractAddress = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(targetContractAddress, value, functionData);

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function test_NonOwnerCannotExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address targetContractAddress = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // Act
        vm.prank(randomuser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(targetContractAddress, value, functionData);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNT ABSTRACTION
    //////////////////////////////////////////////////////////////*/
}