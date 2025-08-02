// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {KToken} from "../../src/tokenization/KToken.sol";
import {VariableDebtToken} from "../../src/tokenization/VariableDebtToken.sol";
import {StableDebtToken} from "../../src/tokenization/StableDebtToken.sol";
import {ERC20} from "../../src/dependencies/openzeppelin/contracts/ERC20.sol";
import {DefaultReserveInterestRateStrategy} from "../../src/DefaultReserveInterestRateStrategy.sol";
import {LendingPoolAddressesProvider} from "../../src/configuration/LendingPoolAddressesProvider.sol";
import {LendingPoolConfigurator} from "../../src/LendingPoolConfigurator.sol";
import {LendingRateOracle} from "../../src/mocks/LendingRateOracle.sol";
import {ILendingPoolConfigurator} from "../../src/interfaces/ILendingPoolConfigurator.sol";
import {ILendingPool} from "../../src/interfaces/ILendingPool.sol";

contract DeployConfigureInitReserve is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Lisk Provider
        address liskAddressesProvider = 0x677A0269eaB64FAc76158541899ca49551C81394;

        LendingPoolAddressesProvider addressesProvider = LendingPoolAddressesProvider(
            liskAddressesProvider
        );

        // Lisk Token Addresses
        address WETH9 = 0x4200000000000000000000000000000000000006;
        address IDRX = 0x18Bc5bcC660cf2B9cE3cd51a404aFe1a0cBD3C22;
        address USDC = 0xF242275d3a6527d877f2c927a82D9b057609cc71;

        // Lisk Interest Rate Strategy
        address wethStrategy = 0xF9889cf9C371CCcca3AaD8dDb17d88E378F26b05;
        address idrxStrategy = 0x1F4D06Cb9991Bf87e71AB8B4e22e063296e3b8A8;
        address usdcStrategy = 0x5ee199851e21B321F079288d648E885eCDBb1427;

        // Krono Token Implementation
        address kTokenImpl = 0xA98373C90cC3879985D90a0ad94d7514F4fD2cd4;
        address variableDebtTokenImpl = 0x415205e6D0e0f5335fc25e4B117863769ef9b494;
        address stableDebtTokenImpl = 0xee6cB032769B7B76aaB233f7E068903B573249E5;

        address configurator = addressesProvider.getLendingPoolConfigurator();
        address lendingRateOracle = addressesProvider.getLendingRateOracle();
        address lendingPool = addressesProvider.getLendingPool();

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Initialize Reserve and Tokens
        LendingPoolConfigurator.InitReserveInput[]
            memory inputs = new LendingPoolConfigurator.InitReserveInput[](3);

        // WETH
        inputs[0] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: kTokenImpl,
            stableDebtTokenImpl: stableDebtTokenImpl,
            variableDebtTokenImpl: variableDebtTokenImpl,
            underlyingAssetDecimals: 18,
            interestRateStrategyAddress: wethStrategy,
            underlyingAsset: WETH9,
            treasury: deployer,
            incentivesController: address(0), // Optional
            underlyingAssetName: "WETH",
            kTokenName: "Krono Lisk WETH",
            kTokenSymbol: "kLiskWETH",
            stableDebtTokenName: "Krono Lisk Stable Debt WETH",
            stableDebtTokenSymbol: "stableDebtLiskWETH",
            variableDebtTokenName: "Krono Lisk Variable Debt WETH",
            variableDebtTokenSymbol: "variableDebtLiskWETH",
            params: ""
        });

        // IDRX
        inputs[1] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: kTokenImpl,
            stableDebtTokenImpl: stableDebtTokenImpl,
            variableDebtTokenImpl: variableDebtTokenImpl,
            underlyingAssetDecimals: 2,
            interestRateStrategyAddress: idrxStrategy,
            underlyingAsset: IDRX,
            treasury: deployer,
            incentivesController: address(0), // Optional
            underlyingAssetName: "IDRX",
            kTokenName: "Krono Lisk IDRX",
            kTokenSymbol: "kLiskIDRX",
            stableDebtTokenName: "Krono Lisk Stable Debt IDRX",
            stableDebtTokenSymbol: "stableDebtLiskIDRX",
            variableDebtTokenName: "Krono Lisk Variable Debt IDRX",
            variableDebtTokenSymbol: "variableDebtLiskIDRX",
            params: ""
        });

        // USDC
        inputs[2] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: kTokenImpl,
            stableDebtTokenImpl: stableDebtTokenImpl,
            variableDebtTokenImpl: variableDebtTokenImpl,
            underlyingAssetDecimals: 6,
            interestRateStrategyAddress: usdcStrategy,
            underlyingAsset: USDC,
            treasury: deployer,
            incentivesController: address(0), // Optional
            underlyingAssetName: "USDC",
            kTokenName: "Krono Lisk USDC",
            kTokenSymbol: "kLiskUSDC",
            stableDebtTokenName: "Krono Lisk Stable Debt USDC",
            stableDebtTokenSymbol: "stableDebtLiskUSDC",
            variableDebtTokenName: "Krono Lisk Variable Debt USDC",
            variableDebtTokenSymbol: "variableDebtLiskUSDC",
            params: ""
        });

        LendingPoolConfigurator(configurator).batchInitReserve(inputs);

        // Configure Reserve As Collateral
        // (Asset, LTV, Liqudation Threshold, Liqudation Bonus)
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(WETH9, 8200, 8500, 10500); // prettier-ignore
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(IDRX, 7500, 8000, 10500); // prettier-ignore
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(USDC, 8000, 8500, 10500); // prettier-ignore

        // Enable Borrowing on Reserve
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(WETH9, false);
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(IDRX, false);
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(USDC, false);

        // Set Reserve Factor
        // This is for platform fee
        LendingPoolConfigurator(configurator).setReserveFactor(WETH9, 1000);
        LendingPoolConfigurator(configurator).setReserveFactor(IDRX, 1500);
        LendingPoolConfigurator(configurator).setReserveFactor(USDC, 1000);

        // LendingRateOracle
        // Not really used, only for compatibility
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(WETH9, 1e26);
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(IDRX, 1e26);
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(USDC, 1e26);

        address kTokenWETH = ILendingPool(lendingPool).getReserveData(WETH9).kTokenAddress;
        address variableDebtWETH = ILendingPool(lendingPool).getReserveData(WETH9).variableDebtTokenAddress; // prettier-ignore
        address stableDebtWETH = ILendingPool(lendingPool).getReserveData(WETH9).stableDebtTokenAddress; // prettier-ignore

        address kTokenIDRX = ILendingPool(lendingPool).getReserveData(IDRX).kTokenAddress;
        address variableDebtIDRX = ILendingPool(lendingPool).getReserveData(IDRX).variableDebtTokenAddress; // prettier-ignore
        address stableDebtIDRX = ILendingPool(lendingPool).getReserveData(IDRX).stableDebtTokenAddress; // prettier-ignore

        address kTokenUSDC = ILendingPool(lendingPool).getReserveData(USDC).kTokenAddress;
        address variableDebtUSDC = ILendingPool(lendingPool).getReserveData(USDC).variableDebtTokenAddress; // prettier-ignore
        address stableDebtUSDC = ILendingPool(lendingPool).getReserveData(USDC).stableDebtTokenAddress; // prettier-ignore

        // Log deployed contract addresses
        console.log("kToken WETH:", kTokenWETH);
        console.log("Variable Debt WETH:", variableDebtWETH);
        console.log("Stable Debt WETH:", stableDebtWETH);

        console.log("kToken IDRX:", kTokenIDRX);
        console.log("Variable Debt IDRX:", variableDebtIDRX);
        console.log("Stable Debt IDRX:", stableDebtIDRX);

        console.log("kToken USDC:", kTokenUSDC);
        console.log("Variable Debt USDC:", variableDebtUSDC);
        console.log("Stable Debt USDC:", stableDebtUSDC);

        vm.stopBroadcast();
    }
}
