// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {KronoFaucets} from "../src/misc/KronoFaucets.sol";

contract DeployKronoFaucets is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        KronoFaucets kronoFaucets = new KronoFaucets();

        console.log("KronoFaucets:", address(kronoFaucets));

        vm.stopBroadcast();
    }
}
