// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {LendingPoolConfigurator} from "../src/LendingPoolConfigurator.sol";
import {LendingPoolCollateralManager} from "../src/LendingPoolCollateralManager.sol";
import {PriceOracle} from "../src/PriceOracle.sol";
import {LendingPoolAddressesProvider} from "../src/configuration/LendingPoolAddressesProvider.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Market ID for the lending pool
        string memory marketId = "Krono Finance Market";

        // Deploy LendingPoolAddressesProvider
        LendingPoolAddressesProvider addressesProvider = new LendingPoolAddressesProvider(marketId);

        // Set admin addresses
        address deployer = vm.addr(deployerPrivateKey);
        addressesProvider.setPoolAdmin(deployer);
        addressesProvider.setEmergencyAdmin(deployer);

        // Deploy PriceOracle
        PriceOracle priceOracle = new PriceOracle();
        addressesProvider.setPriceOracle(address(priceOracle));

        // Deploy LendingPool
        LendingPool lendingPool = new LendingPool();
        addressesProvider.setLendingPoolImpl(address(lendingPool));

        // Initialize LendingPool
        lendingPool.initialize(addressesProvider);

        // Deploy LendingPoolConfigurator
        LendingPoolConfigurator configurator = new LendingPoolConfigurator();
        addressesProvider.setLendingPoolConfiguratorImpl(address(configurator));

        // Initialize LendingPoolConfigurator
        configurator.initialize(addressesProvider);

        // Deploy LendingPoolCollateralManager
        LendingPoolCollateralManager collateralManager = new LendingPoolCollateralManager();
        addressesProvider.setLendingPoolCollateralManager(address(collateralManager));

        // Log the deployed addresses
        console.log("======= Deployment Summary =======");
        console.log("Market ID:", marketId);
        console.log("LendingPoolAddressesProvider:", address(addressesProvider));
        console.log("LendingPool:", address(addressesProvider.getLendingPool()));
        console.log(
            "LendingPoolConfigurator:",
            address(addressesProvider.getLendingPoolConfigurator())
        );
        console.log(
            "LendingPoolCollateralManager:",
            address(addressesProvider.getLendingPoolCollateralManager())
        );
        console.log("PriceOracle:", address(addressesProvider.getPriceOracle()));

        vm.stopBroadcast();
    }
}
