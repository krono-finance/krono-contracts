// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MockPriceOracle} from "../src/mocks/MockPriceOracle.sol";
import {LendingRateOracle} from "../src/mocks/LendingRateOracle.sol";
import {LendingPoolAddressesProvider} from "../src/configuration/LendingPoolAddressesProvider.sol";

contract DeployOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LendingPoolAddressesProvider addressesProvider = LendingPoolAddressesProvider(
            0xDB573BeF789dd06FC4b89B9Ac2F79430b6677d48
        );

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Oracles
        // 1. MockPriceOracle
        // 2. LendingRateOracle
        MockPriceOracle mockPriceOracle = new MockPriceOracle();
        LendingRateOracle lendingRateOracle = new LendingRateOracle();

        // Set Implementation
        addressesProvider.setPriceOracle(address(mockPriceOracle));
        addressesProvider.setLendingRateOracle(address(lendingRateOracle));

        // Log deployed contract addresses
        console.log("MockPriceOracleImpl:", address(mockPriceOracle));
        console.log("LendingRateOracleImpl:", address(lendingRateOracle));

        vm.stopBroadcast();
    }
}
