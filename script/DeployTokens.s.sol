// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KToken} from "../src/tokenization/KToken.sol";
import {StableDebtToken} from "../src/tokenization/StableDebtToken.sol";
import {VariableDebtToken} from "../src/tokenization/VariableDebtToken.sol";
import {DefaultReserveInterestRateStrategy} from "../src/DefaultReserveInterestRateStrategy.sol";
import {LendingPoolAddressesProvider} from "../src/configuration/LendingPoolAddressesProvider.sol";
import {LendingPoolConfigurator} from "../src/LendingPoolConfigurator.sol";
import {ILendingPoolConfigurator} from "../src/interfaces/ILendingPoolConfigurator.sol";
import {ILendingPool} from "../src/interfaces/ILendingPool.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract DeployAsset is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        LendingPoolAddressesProvider provider = LendingPoolAddressesProvider(
            0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
        );
        LendingPoolConfigurator configurator = LendingPoolConfigurator(
            provider.getLendingPoolConfigurator()
        );

        // Deploy Mock ERC20 Token
        MockERC20 asset = new MockERC20("Wrapped ETH", "WETH");

        // Deploy kToken, stableDebt, and variableDebt
        KToken kToken = new KToken();
        StableDebtToken stableDebtToken = new StableDebtToken();
        VariableDebtToken variableDebtToken = new VariableDebtToken();

        // Deploy Interest Rate Strategy
        uint256 optimalUtilizationRate = 0.65e27; // 65%
        uint256 baseVariableBorrowRate = 0e27; // 0
        uint256 variableRateSlope1 = 0.08e27; // 8%
        uint256 variableRateSlope2 = 1e27; // 100%
        uint256 stableRateSlope1 = 0.1e27; // 10%
        uint256 stableRateSlope2 = 1e27; // 100%

        DefaultReserveInterestRateStrategy strategy = new DefaultReserveInterestRateStrategy(
            provider,
            optimalUtilizationRate,
            baseVariableBorrowRate,
            variableRateSlope1,
            variableRateSlope2,
            stableRateSlope1,
            stableRateSlope2
        );

        LendingPoolConfigurator.InitReserveInput[]
            memory inputs = new LendingPoolConfigurator.InitReserveInput[](1);

        inputs[0] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: address(kToken),
            stableDebtTokenImpl: address(stableDebtToken),
            variableDebtTokenImpl: address(variableDebtToken),
            underlyingAssetDecimals: 18,
            interestRateStrategyAddress: address(strategy),
            underlyingAsset: address(asset),
            treasury: msg.sender,
            incentivesController: address(0), // Optional
            underlyingAssetName: "WETH",
            kTokenName: "Krono WETH",
            kTokenSymbol: "kWETH",
            stableDebtTokenName: "Krono Stable Debt WETH",
            stableDebtTokenSymbol: "sdWETH",
            variableDebtTokenName: "Krono Variable Debt WETH",
            variableDebtTokenSymbol: "vdWETH",
            params: ""
        });

        configurator.batchInitReserve(inputs);

        console.log("Underlying asset:", address(asset));
        console.log("KToken Impl:", address(kToken));
        console.log("Stable Debt Impl:", address(stableDebtToken));
        console.log("Variable Debt Impl:", address(variableDebtToken));
        console.log("Rate Strategy:", address(strategy));

        vm.stopBroadcast();
    }
}
