// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {LendingPoolAddressesProvider} from "../src/configuration/LendingPoolAddressesProvider.sol";
import {LendingPoolConfigurator} from "../src/LendingPoolConfigurator.sol";
import {LendingPoolCollateralManager} from "../src/LendingPoolCollateralManager.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract DeployLendingPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 emergencyAdminPrivateKey = vm.envUint("EMERGENCY_ADMIN_PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);
        address emergencyAdmin = vm.addr(emergencyAdminPrivateKey);

        string memory marketId = "KronoLiskSepolia";

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Core Contracts
        // 1. LendingPoolAddressesProvider
        // 2. LendingPool
        // 3. LendingPoolConfigurator
        // 4. LendingPoolCollateralManager
        LendingPoolAddressesProvider addressesProvider = new LendingPoolAddressesProvider(marketId);
        LendingPool lendingPool = new LendingPool();
        LendingPoolConfigurator configurator = new LendingPoolConfigurator();
        LendingPoolCollateralManager collateralManager = new LendingPoolCollateralManager();

        // Set Implementations
        // This include initializing the contract implementation by LendingPoolAddressesProvider
        addressesProvider.setLendingPoolImpl(address(lendingPool));
        addressesProvider.setLendingPoolConfiguratorImpl(address(configurator));
        addressesProvider.setLendingPoolCollateralManager(address(collateralManager));

        // Set Admins
        addressesProvider.setPoolAdmin(deployer);
        addressesProvider.setEmergencyAdmin(emergencyAdmin);

        // Log deployed contract addresses
        console.log("LendingPoolAddressesProvider:", address(addressesProvider));
        console.log("LendingPoolImpl:", address(lendingPool));
        console.log("LendingPoolConfiguratorImpl:", address(configurator));
        console.log("LendingPoolCollateralManagerImpl:", address(collateralManager));
        console.log("LendingPoolProxy:", addressesProvider.getLendingPool());
        console.log("LendingPoolConfiguratorProxy:", addressesProvider.getLendingPoolConfigurator()); // prettier-ignore
        console.log("LendingPoolCollateralManagerProxy:", addressesProvider.getLendingPoolCollateralManager()); // prettier-ignore

        vm.stopBroadcast();
    }
}
