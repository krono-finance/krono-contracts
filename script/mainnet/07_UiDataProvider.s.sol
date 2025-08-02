// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {LendingPoolAddressesProvider} from "../../src/configuration/LendingPoolAddressesProvider.sol";
import {UiPoolDataProvider} from "../../src/misc/UiPoolDataProvider.sol";
import {WalletBalanceProvider} from "../../src/misc/WalletBalanceProvider.sol";
import {PriceOracle} from "../../src/PriceOracle.sol";

contract DeployUiDataProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address oracleAddr = 0xddb0c6b66Cf2BaCB6FB835a74c33be8ad728e596;
        PriceOracle priceOracle = PriceOracle(oracleAddr);

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WETHGateway contract
        UiPoolDataProvider poolDataProvider = new UiPoolDataProvider(priceOracle);
        WalletBalanceProvider walletBalanceProvider = new WalletBalanceProvider();

        // Log deployed contract addresses
        console.log("UiPoolDataProvider:", address(poolDataProvider));
        console.log("WalletBalanceProvider:", address(walletBalanceProvider));

        vm.stopBroadcast();
    }
}
