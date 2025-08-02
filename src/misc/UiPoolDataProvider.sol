// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {IUiPoolDataProvider} from "./interfaces/IUiPoolDataProvider.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {PriceOracle} from "../PriceOracle.sol";
import {IKToken} from "../interfaces/IKToken.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {IStableDebtToken} from "../interfaces/IStableDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "../libraries/ReserveConfiguration.sol";
import {UserConfiguration} from "../libraries/UserConfiguration.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {DefaultReserveInterestRateStrategy} from "../DefaultReserveInterestRateStrategy.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    address public constant USDC_ADDRESS = 0xF242275d3a6527d877f2c927a82D9b057609cc71;
    PriceOracle public immutable oracle;

    constructor(PriceOracle _oracle) {
        oracle = _oracle;
    }

    function getInterestRateStrategySlopes(
        DefaultReserveInterestRateStrategy interestRateStrategy
    ) internal view returns (uint256, uint256, uint256, uint256) {
        return (
            interestRateStrategy.variableRateSlope1(),
            interestRateStrategy.variableRateSlope2(),
            interestRateStrategy.stableRateSlope1(),
            interestRateStrategy.stableRateSlope2()
        );
    }

    function getReservesList(
        ILendingPoolAddressesProvider provider
    ) public view override returns (address[] memory) {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        return lendingPool.getReservesList();
    }

    function getSimpleReservesData(
        ILendingPoolAddressesProvider provider
    ) public view override returns (AggregatedReserveData[] memory, uint256) {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        address[] memory reserves = lendingPool.getReservesList();
        AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);

        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveData memory reserveData = reservesData[i];
            reserveData.underlyingAsset = reserves[i];

            // reserve current state
            DataTypes.ReserveData memory baseData = lendingPool.getReserveData(
                reserveData.underlyingAsset
            );

            reserveData.liquidityIndex = baseData.liquidityIndex;
            reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
            reserveData.liquidityRate = baseData.currentLiquidityRate;
            reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
            reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
            reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
            reserveData.kTokenAddress = baseData.kTokenAddress;
            reserveData.stableDebtTokenAddress = baseData.stableDebtTokenAddress;
            reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
            reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
            reserveData.priceInEth = oracle.getAssetPrice(reserveData.underlyingAsset);

            reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(
                reserveData.kTokenAddress
            );
            (
                reserveData.totalPrincipalStableDebt,
                ,
                reserveData.averageStableRate,
                reserveData.stableDebtLastUpdateTimestamp
            ) = IStableDebtToken(reserveData.stableDebtTokenAddress).getSupplyData();
            reserveData.totalScaledVariableDebt = IVariableDebtToken(
                reserveData.variableDebtTokenAddress
            ).scaledTotalSupply();

            // reserve configuration

            reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
            reserveData.name = IERC20Detailed(reserveData.underlyingAsset).name();

            (
                reserveData.baseLTVasCollateral,
                reserveData.reserveLiquidationThreshold,
                reserveData.reserveLiquidationBonus,
                reserveData.decimals,
                reserveData.reserveFactor
            ) = baseData.configuration.getParamsMemory();
            (
                reserveData.isActive,
                reserveData.isFrozen,
                reserveData.borrowingEnabled,
                reserveData.stableBorrowRateEnabled
            ) = baseData.configuration.getFlagsMemory();
            reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;
            (
                reserveData.variableRateSlope1,
                reserveData.variableRateSlope2,
                reserveData.stableRateSlope1,
                reserveData.stableRateSlope2
            ) = getInterestRateStrategySlopes(
                DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
            );
        }

        return (reservesData, oracle.getAssetPrice(USDC_ADDRESS));
    }

    function getUserReservesData(
        ILendingPoolAddressesProvider provider,
        address user
    ) external view override returns (UserReserveData[] memory) {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        address[] memory reserves = lendingPool.getReservesList();
        DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

        UserReserveData[] memory userReservesData = new UserReserveData[](
            user != address(0) ? reserves.length : 0
        );

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserves[i]);
            // user reserve data
            userReservesData[i].underlyingAsset = reserves[i];
            userReservesData[i].scaledATokenBalance = IKToken(baseData.kTokenAddress)
                .scaledBalanceOf(user);
            userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

            if (userConfig.isBorrowing(i)) {
                userReservesData[i].scaledVariableDebt = IVariableDebtToken(
                    baseData.variableDebtTokenAddress
                ).scaledBalanceOf(user);
                userReservesData[i].principalStableDebt = IStableDebtToken(
                    baseData.stableDebtTokenAddress
                ).principalBalanceOf(user);
                if (userReservesData[i].principalStableDebt != 0) {
                    userReservesData[i].stableBorrowRate = IStableDebtToken(
                        baseData.stableDebtTokenAddress
                    ).getUserStableRate(user);
                    userReservesData[i].stableBorrowLastUpdateTimestamp = IStableDebtToken(
                        baseData.stableDebtTokenAddress
                    ).getUserLastUpdated(user);
                }
            }
        }

        return userReservesData;
    }

    function getReservesData(
        ILendingPoolAddressesProvider provider,
        address user
    )
        external
        view
        override
        returns (AggregatedReserveData[] memory, UserReserveData[] memory, uint256)
    {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        address[] memory reserves = lendingPool.getReservesList();
        DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

        AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);
        UserReserveData[] memory userReservesData = new UserReserveData[](
            user != address(0) ? reserves.length : 0
        );

        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveData memory reserveData = reservesData[i];
            reserveData.underlyingAsset = reserves[i];

            // reserve current state
            DataTypes.ReserveData memory baseData = lendingPool.getReserveData(
                reserveData.underlyingAsset
            );
            reserveData.liquidityIndex = baseData.liquidityIndex;
            reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
            reserveData.liquidityRate = baseData.currentLiquidityRate;
            reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
            reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
            reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
            reserveData.kTokenAddress = baseData.kTokenAddress;
            reserveData.stableDebtTokenAddress = baseData.stableDebtTokenAddress;
            reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
            reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
            reserveData.priceInEth = oracle.getAssetPrice(reserveData.underlyingAsset);

            reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(
                reserveData.kTokenAddress
            );
            (
                reserveData.totalPrincipalStableDebt,
                ,
                reserveData.averageStableRate,
                reserveData.stableDebtLastUpdateTimestamp
            ) = IStableDebtToken(reserveData.stableDebtTokenAddress).getSupplyData();
            reserveData.totalScaledVariableDebt = IVariableDebtToken(
                reserveData.variableDebtTokenAddress
            ).scaledTotalSupply();

            // reserve configuration

            // we're getting this info from the aToken, because some of assets can be not compliant with ETC20Detailed
            reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
            reserveData.name = "";

            (
                reserveData.baseLTVasCollateral,
                reserveData.reserveLiquidationThreshold,
                reserveData.reserveLiquidationBonus,
                reserveData.decimals,
                reserveData.reserveFactor
            ) = baseData.configuration.getParamsMemory();
            (
                reserveData.isActive,
                reserveData.isFrozen,
                reserveData.borrowingEnabled,
                reserveData.stableBorrowRateEnabled
            ) = baseData.configuration.getFlagsMemory();
            reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;
            (
                reserveData.variableRateSlope1,
                reserveData.variableRateSlope2,
                reserveData.stableRateSlope1,
                reserveData.stableRateSlope2
            ) = getInterestRateStrategySlopes(
                DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
            );

            if (user != address(0)) {
                // user reserve data
                userReservesData[i].underlyingAsset = reserveData.underlyingAsset;
                userReservesData[i].scaledATokenBalance = IKToken(reserveData.kTokenAddress)
                    .scaledBalanceOf(user);
                userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(
                    i
                );

                if (userConfig.isBorrowing(i)) {
                    userReservesData[i].scaledVariableDebt = IVariableDebtToken(
                        reserveData.variableDebtTokenAddress
                    ).scaledBalanceOf(user);
                    userReservesData[i].principalStableDebt = IStableDebtToken(
                        reserveData.stableDebtTokenAddress
                    ).principalBalanceOf(user);
                    if (userReservesData[i].principalStableDebt != 0) {
                        userReservesData[i].stableBorrowRate = IStableDebtToken(
                            reserveData.stableDebtTokenAddress
                        ).getUserStableRate(user);
                        userReservesData[i].stableBorrowLastUpdateTimestamp = IStableDebtToken(
                            reserveData.stableDebtTokenAddress
                        ).getUserLastUpdated(user);
                    }
                }
            }
        }

        return (reservesData, userReservesData, oracle.getAssetPrice(USDC_ADDRESS));
    }
}
