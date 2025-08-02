// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract DeployMockERC20 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        MockERC20 wbtc = new MockERC20("Wrapped BTC", "WBTC", 8);
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);
        MockERC20 usdt = new MockERC20("Tether USD", "USDT", 6);

        wbtc.mint(msg.sender, 1e27);
        usdc.mint(msg.sender, 1e27);
        usdt.mint(msg.sender, 1e27);

        // Log deployed contract addresses
        console.log("WBTC:", address(wbtc));
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));

        vm.stopBroadcast();
    }
}
