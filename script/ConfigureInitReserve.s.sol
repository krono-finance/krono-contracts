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

contract DeployConfigureInitReserve is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Lisk Sepolia Token Addresses
        address WETH9 = 0x4200000000000000000000000000000000000006;
        address IDRX = 0xD63029C1a3dA68b51c67c6D1DeC3DEe50D681661;
        address mockWBTC = 0xee6cB032769B7B76aaB233f7E068903B573249E5;
        address mockUSDC = 0xddb0c6b66Cf2BaCB6FB835a74c33be8ad728e596;
        address mockUSDT = 0x814c5aeA0dcEaF6b334499d080630071F0A336EF;

        // Lisk Sepolia Interest Rate Strategy
        address wethStrategy = 0x63D41662484d665B657Fe7Ccec19B17540C75cf1;
        address idrxStrategy = 0xecd44a2A08F3cedd1CCf09c28756861EE28F630e;
        address wbtcStrategy = 0x47359a64E686b1664Daa4Fc4b97D288cde4d7381;
        address usdcStrategy = 0x2cabcc96e0F478F13738364192c6C3c9EA80451e;
        address usdtStrategy = 0xa279884F378a0Bab98Fc00Da57d2Acd56a068119;

        // Krono Token Implementation
        address kTokenImpl = 0x1F4D06Cb9991Bf87e71AB8B4e22e063296e3b8A8;
        address variableDebtTokenImpl = 0x5ee199851e21B321F079288d648E885eCDBb1427;
        address stableDebtTokenImpl = 0x0Fa988bD73851cFAac48dde4E53fe09739A7D840;

        // Lisk Sepolia Provider
        LendingPoolAddressesProvider addressesProvider = LendingPoolAddressesProvider(
            0x35C6f8D689527EaF42c6911BDc9B1Ba209Bb3C0b
        );
        address configurator = addressesProvider.getLendingPoolConfigurator();
        address lendingRateOracle = addressesProvider.getLendingRateOracle();
        address lendingPool = addressesProvider.getLendingPool();

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Initialize Reserve and Tokens
        LendingPoolConfigurator.InitReserveInput[]
            memory inputs = new LendingPoolConfigurator.InitReserveInput[](5);

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

        // WBTC
        inputs[2] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: kTokenImpl,
            stableDebtTokenImpl: stableDebtTokenImpl,
            variableDebtTokenImpl: variableDebtTokenImpl,
            underlyingAssetDecimals: 8,
            interestRateStrategyAddress: wbtcStrategy,
            underlyingAsset: mockWBTC,
            treasury: deployer,
            incentivesController: address(0), // Optional
            underlyingAssetName: "WBTC",
            kTokenName: "Krono Lisk WBTC",
            kTokenSymbol: "kLiskWBTC",
            stableDebtTokenName: "Krono Lisk Stable Debt WBTC",
            stableDebtTokenSymbol: "stableDebtLiskWBTC",
            variableDebtTokenName: "Krono Lisk Variable Debt WBTC",
            variableDebtTokenSymbol: "variableDebtLiskWBTC",
            params: ""
        });

        // USDC
        inputs[3] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: kTokenImpl,
            stableDebtTokenImpl: stableDebtTokenImpl,
            variableDebtTokenImpl: variableDebtTokenImpl,
            underlyingAssetDecimals: 6,
            interestRateStrategyAddress: usdcStrategy,
            underlyingAsset: mockUSDC,
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

        // USDT
        inputs[4] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: kTokenImpl,
            stableDebtTokenImpl: stableDebtTokenImpl,
            variableDebtTokenImpl: variableDebtTokenImpl,
            underlyingAssetDecimals: 6,
            interestRateStrategyAddress: usdtStrategy,
            underlyingAsset: mockUSDT,
            treasury: deployer,
            incentivesController: address(0), // Optional
            underlyingAssetName: "USDT",
            kTokenName: "Krono Lisk USDT",
            kTokenSymbol: "kLiskUSDT",
            stableDebtTokenName: "Krono Lisk Stable Debt USDT",
            stableDebtTokenSymbol: "stableDebtLiskUSDT",
            variableDebtTokenName: "Krono Lisk Variable Debt USDT",
            variableDebtTokenSymbol: "variableDebtLiskUSDT",
            params: ""
        });

        LendingPoolConfigurator(configurator).batchInitReserve(inputs);

        // Configure Reserve As Collateral
        // (Asset, LTV, Liqudation Threshold, Liqudation Bonus)
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(WETH9, 8200, 8500, 10500); // prettier-ignore
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(IDRX, 7500, 8000, 10500); // prettier-ignore
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(mockWBTC, 7000, 7500, 11000); // prettier-ignore
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(mockUSDC, 8000, 8500, 10500); // prettier-ignore
        LendingPoolConfigurator(configurator).configureReserveAsCollateral(mockUSDT, 8000, 8500, 10500); // prettier-ignore

        // Enable Borrowing on Reserve
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(WETH9, false);
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(IDRX, false);
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(mockWBTC, false);
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(mockUSDC, false);
        LendingPoolConfigurator(configurator).enableBorrowingOnReserve(mockUSDT, false);

        // Set Reserve Factor
        // This is for platform fee
        LendingPoolConfigurator(configurator).setReserveFactor(WETH9, 1000);
        LendingPoolConfigurator(configurator).setReserveFactor(IDRX, 1500);
        LendingPoolConfigurator(configurator).setReserveFactor(mockWBTC, 2000);
        LendingPoolConfigurator(configurator).setReserveFactor(mockUSDC, 1000);
        LendingPoolConfigurator(configurator).setReserveFactor(mockUSDT, 1000);

        // LendingRateOracle
        // Not really used, only for compatibility
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(WETH9, 1e26);
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(IDRX, 1e26);
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(mockWBTC, 1e26);
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(mockUSDC, 1e26);
        LendingRateOracle(lendingRateOracle).setMarketBorrowRate(mockUSDT, 1e26);

        address kTokenWETH = ILendingPool(lendingPool).getReserveData(WETH9).kTokenAddress;
        address variableDebtWETH = ILendingPool(lendingPool).getReserveData(WETH9).variableDebtTokenAddress; // prettier-ignore
        address stableDebtWETH = ILendingPool(lendingPool).getReserveData(WETH9).stableDebtTokenAddress; // prettier-ignore

        address kTokenIDRX = ILendingPool(lendingPool).getReserveData(IDRX).kTokenAddress;
        address variableDebtIDRX = ILendingPool(lendingPool).getReserveData(IDRX).variableDebtTokenAddress; // prettier-ignore
        address stableDebtIDRX = ILendingPool(lendingPool).getReserveData(IDRX).stableDebtTokenAddress; // prettier-ignore

        address kTokenWBTC = ILendingPool(lendingPool).getReserveData(mockWBTC).kTokenAddress;
        address variableDebtWBTC = ILendingPool(lendingPool).getReserveData(mockWBTC).variableDebtTokenAddress; // prettier-ignore
        address stableDebtWBTC = ILendingPool(lendingPool).getReserveData(mockWBTC).stableDebtTokenAddress; // prettier-ignore

        address kTokenUSDC = ILendingPool(lendingPool).getReserveData(mockUSDC).kTokenAddress;
        address variableDebtUSDC = ILendingPool(lendingPool).getReserveData(mockUSDC).variableDebtTokenAddress; // prettier-ignore
        address stableDebtUSDC = ILendingPool(lendingPool).getReserveData(mockUSDC).stableDebtTokenAddress; // prettier-ignore

        address kTokenUSDT = ILendingPool(lendingPool).getReserveData(mockUSDT).kTokenAddress;
        address variableDebtUSDT = ILendingPool(lendingPool).getReserveData(mockUSDT).variableDebtTokenAddress; // prettier-ignore
        address stableDebtUSDT = ILendingPool(lendingPool).getReserveData(mockUSDT).stableDebtTokenAddress; // prettier-ignore

        // Log deployed contract addresses
        console.log("kToken WETH:", kTokenWETH);
        console.log("Variable Debt WETH:", variableDebtWETH);
        console.log("Stable Debt WETH:", stableDebtWETH);

        console.log("kToken IDRX:", kTokenIDRX);
        console.log("Variable Debt IDRX:", variableDebtIDRX);
        console.log("Stable Debt IDRX:", stableDebtIDRX);

        console.log("kToken WBTC:", kTokenWBTC);
        console.log("Variable Debt WBTC:", variableDebtWBTC);
        console.log("Stable Debt WBTC:", stableDebtWBTC);

        console.log("kToken USDC:", kTokenUSDC);
        console.log("Variable Debt USDC:", variableDebtUSDC);
        console.log("Stable Debt USDC:", stableDebtUSDC);

        console.log("kToken USDT:", kTokenUSDT);
        console.log("Variable Debt USDT:", variableDebtUSDT);
        console.log("Stable Debt USDT:", stableDebtUSDT);

        vm.stopBroadcast();
    }
}
