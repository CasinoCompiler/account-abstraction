// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {DeployMinimalAccount} from "../../script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract TestMinimalAccount is Test {
    DeployMinimalAccount deployMinimal;
    HelperConfig helperConfig;
    MinimalAccount minimalAccount;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setup() public {
        deployMinimal = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployMinimal.deployMinimalAccount();
    }

    /*//////////////////////////////////////////////////////////////
                                WORKFLOW
    //////////////////////////////////////////////////////////////*/

    function testOwnerCanExecute() public {
        
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNT ABSTRACTION
    //////////////////////////////////////////////////////////////*/
}