// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {LendingPoolAddressesProvider} from "../../src/configuration/LendingPoolAddressesProvider.sol";
import {WETHGateway} from "../../src/misc/WETHGateway.sol";

contract DeployWETHGateway is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Lisk Provider
        address liskAddressesProvider = 0x677A0269eaB64FAc76158541899ca49551C81394;

        LendingPoolAddressesProvider addressesProvider = LendingPoolAddressesProvider(
            liskAddressesProvider
        );
        address lendingPool = addressesProvider.getLendingPool();
        address WETH9 = 0x4200000000000000000000000000000000000006;

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WETHGateway contract
        WETHGateway wethGateway = new WETHGateway(WETH9);

        // Infinite approves lending pool
        wethGateway.authorizeLendingPool(lendingPool);

        // Log deployed contract addresses
        console.log("WETHGateway:", address(wethGateway));

        vm.stopBroadcast();
    }
}
