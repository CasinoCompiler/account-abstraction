// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "lib/forge-std/src/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 public constant ARBITRUM_MAINNET_CHAIN_ID = 42_161;
    uint256 public constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    address public constant BURNER_WALLET = 0x9E68306A94f08bcB91F4d2fE3F39CD54eB6E067B;
    address public constant ANVIL_WALLET = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZKSyncSepoliaConfig();
    }

    function getConfig() public view returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns(NetworkConfig memory){
        if (chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilConfig();
        } else if (networkConfigs[chainId].account != address(0)){
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        return (
            NetworkConfig({
                entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
                account: BURNER_WALLET
            })
        ); 
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return (
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                account: BURNER_WALLET
            })
        ); 
    }

    function getZKSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return (
            NetworkConfig({
                entryPoint: address(0),
                account: BURNER_WALLET
            })
        ); 
    }

    function getOrCreateAnvilConfig() public view returns (NetworkConfig memory anvilConfig) {

        // Ensure an anvil mock address hasn't already been deployed. if it has, return existing config.
        if (activeNetworkConfig.account != address(0)) {
            return (anvilConfig);
        }
    }
}