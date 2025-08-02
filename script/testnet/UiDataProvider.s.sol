// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {LendingPoolAddressesProvider} from "../../src/configuration/LendingPoolAddressesProvider.sol";
import {UiPoolDataProvider} from "../../src/misc/UiPoolDataProvider.sol";
import {WalletBalanceProvider} from "../../src/misc/WalletBalanceProvider.sol";
import {MockPriceOracle} from "../../src/mocks/MockPriceOracle.sol";

contract DeployUiDataProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        MockPriceOracle mockPriceOracle = MockPriceOracle(
            0x1c87da7d4d385999De062e9daDD8e5FE03802269
        );

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WETHGateway contract
        UiPoolDataProvider poolDataProvider = new UiPoolDataProvider(mockPriceOracle);
        WalletBalanceProvider walletBalanceProvider = new WalletBalanceProvider();

        // Log deployed contract addresses
        console.log("UiPoolDataProvider:", address(poolDataProvider));
        console.log("WalletBalanceProvider:", address(walletBalanceProvider));

        vm.stopBroadcast();
    }
}
