// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {PriceOracle} from "../../src/PriceOracle.sol";
import {LendingRateOracle} from "../../src/mocks/LendingRateOracle.sol";
import {LendingPoolAddressesProvider} from "../../src/configuration/LendingPoolAddressesProvider.sol";

contract DeployOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Lisk Provider
        address liskAddressesProvider = 0x677A0269eaB64FAc76158541899ca49551C81394;

        LendingPoolAddressesProvider addressesProvider = LendingPoolAddressesProvider(
            liskAddressesProvider
        );

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Oracles
        // 1. PriceOracle
        // 2. LendingRateOracle
        PriceOracle priceOracle = new PriceOracle();
        LendingRateOracle lendingRateOracle = new LendingRateOracle();

        // Set Implementation
        addressesProvider.setPriceOracle(address(priceOracle));
        addressesProvider.setLendingRateOracle(address(lendingRateOracle));

        // Log deployed contract addresses
        console.log("PriceOracleImpl:", address(priceOracle));
        console.log("LendingRateOracleImpl:", address(lendingRateOracle));

        vm.stopBroadcast();
    }
}
