// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title
 * @author 
 * @notice 
 * @dev 
 */

/** Imports */
// @Order Imports, Interfaces, Libraries, Contracts
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";

contract MinimalAccount is IAccount, Ownable {

    /** Errors */
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    /** Type Declarations */

    /** State Variables */
    IEntryPoint private immutable i_entryPoint;

    /** Events */

    /** Constructor */
    constructor(address entryPointContractAddress) Ownable(msg.sender){
        i_entryPoint = IEntryPoint(entryPointContractAddress);
    }

    /** Modifiers */
    modifier requireFromEntryPoint() {
        if (msg.sender != getEntryPoint()){
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != getEntryPoint() && msg.sender != owner()){
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }        
        _;
    }

    /** Functions */
    // @Order recieve, fallback, external, public, internal, private
    receive() external payable {}

    function execute(address targetContractAddress, uint256 value, bytes calldata functionData) external requireFromEntryPointOrOwner{
        (bool success, bytes memory result) = targetContractAddress.call{value: value}(functionData);
        if (!success){
            revert MinimalAccount__CallFailed(result);
        }
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external  requireFromEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _payAccount(missingAccountFunds);
    }

    function _validateSignature (PackedUserOperation calldata _userOp, bytes32 _userOpHash) internal view returns(uint256 _validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(_userOpHash);
        (address _signer,,) = ECDSA.tryRecover(ethSignedMessageHash, _userOp.signature);
        if (_signer != owner()){
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;

    }

    function _payAccount(uint256 _missingAccountFunds) internal {
        if (_missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: _missingAccountFunds, gas: type(uint256).max}("");
            success;
        }
    }
    /** Getter Functions */
    function getEntryPoint() public view returns(address){
        return address(i_entryPoint);
    }
}