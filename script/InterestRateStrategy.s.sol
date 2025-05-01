// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {KToken} from "../src/tokenization/KToken.sol";
import {VariableDebtToken} from "../src/tokenization/VariableDebtToken.sol";
import {StableDebtToken} from "../src/tokenization/StableDebtToken.sol";
import {ERC20} from "../src/dependencies/openzeppelin/contracts/ERC20.sol";
import {DefaultReserveInterestRateStrategy} from "../src/DefaultReserveInterestRateStrategy.sol";
import {LendingPoolAddressesProvider} from "../src/configuration/LendingPoolAddressesProvider.sol";
import {LendingPoolConfigurator} from "../src/LendingPoolConfigurator.sol";
import {LendingRateOracle} from "../src/mocks/LendingRateOracle.sol";
import {ILendingPoolConfigurator} from "../src/interfaces/ILendingPoolConfigurator.sol";
import {ILendingPool} from "../src/interfaces/ILendingPool.sol";

contract DeployInterestRateStrategy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Lisk Sepolia Provider
        LendingPoolAddressesProvider addressesProvider = LendingPoolAddressesProvider(
            0xDB573BeF789dd06FC4b89B9Ac2F79430b6677d48
        );

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Interest Rate Strategy for each Tokens
        // WETH
        DefaultReserveInterestRateStrategy wethStrategy = new DefaultReserveInterestRateStrategy(
            addressesProvider,
            8e26, // Optimal 80%
            1e25, // Base Variable 1%
            4e25, // variableSlope1 4%
            8e26, // variableSlope2 80%
            4e25, // stableSlope1 4%
            8e26 // stableSlope2 80%
        );

        // IDRX
        DefaultReserveInterestRateStrategy idrxStrategy = new DefaultReserveInterestRateStrategy(
            addressesProvider,
            8e26, // Optimal 80%
            1e25, // Base Variable 1%
            4e25, // variableSlope1 4%
            1e27, // variableSlope2 100%
            4e25, // stableSlope1 4%
            8e26 // stableSlope2 80%
        );

        // WBTC
        DefaultReserveInterestRateStrategy wbtcStrategy = new DefaultReserveInterestRateStrategy(
            addressesProvider,
            7e26, // Optimal 70%
            0, // Base Variable 0
            4e25, // variableSlope1 4%
            3e27, // variableSlope2 300%
            4e25, // stableSlope1 4%
            8e26 // stableSlope2 80%
        );

        // USDC
        DefaultReserveInterestRateStrategy usdcStrategy = new DefaultReserveInterestRateStrategy(
            addressesProvider,
            8e26, // Optimal 80%
            0, // Base Variable 0
            125e24, // variableSlope1 12.5%
            6e26, // variableSlope2 60%
            4e25, // stableSlope1 4%
            8e26 // stableSlope2 80%
        );

        // USDT
        DefaultReserveInterestRateStrategy usdtStrategy = new DefaultReserveInterestRateStrategy(
            addressesProvider,
            8e26, // Optimal 80%
            0, // Base Variable 0
            125e24, // variableSlope1 12.5%
            6e26, // variableSlope2 60%
            4e25, // stableSlope1 4%
            8e26 // stableSlope2 80%
        );

        // Log deployed contract addresses
        console.log("Interest Rate Strategy WETH:", address(wethStrategy));
        console.log("Interest Rate Strategy IDRX:", address(idrxStrategy));
        console.log("Interest Rate Strategy WBTC:", address(wbtcStrategy));
        console.log("Interest Rate Strategy USDC:", address(usdcStrategy));
        console.log("Interest Rate Strategy USDT:", address(usdtStrategy));

        vm.stopBroadcast();
    }
}
