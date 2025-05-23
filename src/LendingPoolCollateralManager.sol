// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {IERC20} from "./dependencies/openzeppelin/contracts//IERC20.sol";
import {IKToken} from "./interfaces/IKToken.sol";
import {IStableDebtToken} from "./interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "./interfaces/IVariableDebtToken.sol";
import {IPriceOracleGetter} from "./interfaces/IPriceOracleGetter.sol";
import {ILendingPoolCollateralManager} from "./interfaces/ILendingPoolCollateralManager.sol";
import {VersionedInitializable} from "./libraries/upgradeability/VersionedInitializable.sol";
import {GenericLogic} from "./libraries/logic/GenericLogic.sol";
import {Helpers} from "./libraries/Helpers.sol";
import {WadRayMath} from "./libraries/math/WadRayMath.sol";
import {PercentageMath} from "./libraries/math/PercentageMath.sol";
import {SafeERC20} from "./dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {ValidationLogic} from "./libraries/logic/ValidationLogic.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {LendingPoolStorage} from "./LendingPoolStorage.sol";
import {UserConfiguration} from "./libraries/UserConfiguration.sol";
import {ReserveConfiguration} from "./libraries/ReserveConfiguration.sol";
import {ReserveLogic} from "./libraries/logic/ReserveLogic.sol";

contract LendingPoolCollateralManager is
    ILendingPoolCollateralManager,
    VersionedInitializable,
    LendingPoolStorage
{
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    uint256 internal constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5000;

    struct LiquidationCallLocalVars {
        uint256 userCollateralBalance;
        uint256 userStableDebt;
        uint256 userVariableDebt;
        uint256 maxLiquidatableDebt;
        uint256 actualDebtToLiquidate;
        uint256 liquidationRatio;
        uint256 maxAmountCollateralToLiquidate;
        uint256 userStableRate;
        uint256 maxCollateralToLiquidate;
        uint256 debtAmountNeeded;
        uint256 healthFactor;
        uint256 liquidatorPreviousKTokenBalance;
        IKToken collateralKtoken;
        bool isCollateralEnabled;
        DataTypes.InterestRateMode borrowRateMode;
        uint256 errorCode;
        string errorMsg;
    }

    /**
     * @dev As thIS contract extends the VersionedInitializable contract to match the state
     * of the LendingPool contract, the getRevision() function is needed, but the value is not
     * important, as the initialize() function will never be called here
     */
    function getRevision() internal pure override returns (uint256) {
        return 0;
    }

    /**
     * @dev Function to liquidate a position if its Health Factor drops below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveKToken `true` if the liquidators wants to receive the collateral kTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveKToken
    ) external override returns (uint256, string memory) {
        DataTypes.ReserveData storage collateralReserve = _reserves[collateralAsset];
        DataTypes.ReserveData storage debtReserve = _reserves[debtAsset];
        DataTypes.UserConfigurationMap storage userConfig = _usersConfig[user];

        LiquidationCallLocalVars memory vars;

        (, , , , vars.healthFactor) = GenericLogic.calculateUserAccountData(
            user,
            _reserves,
            userConfig,
            _reservesList,
            _reservesCount,
            _addressesProvider.getPriceOracle()
        );

        (vars.userStableDebt, vars.userVariableDebt) = Helpers.getUserCurrentDebt(
            user,
            debtReserve
        );

        (vars.errorCode, vars.errorMsg) = ValidationLogic.validateLiquidationCall(
            collateralReserve,
            debtReserve,
            userConfig,
            vars.healthFactor,
            vars.userStableDebt,
            vars.userVariableDebt
        );

        if (
            Errors.CollateralManagerErrors(vars.errorCode) !=
            Errors.CollateralManagerErrors.NO_ERROR
        ) {
            return (vars.errorCode, vars.errorMsg);
        }

        vars.collateralKtoken = IKToken(collateralReserve.kTokenAddress);

        vars.userCollateralBalance = vars.collateralKtoken.balanceOf(user);

        vars.maxLiquidatableDebt = (vars.userStableDebt + vars.userVariableDebt).percentMul(
            LIQUIDATION_CLOSE_FACTOR_PERCENT
        );

        vars.actualDebtToLiquidate = debtToCover > vars.maxLiquidatableDebt
            ? vars.maxLiquidatableDebt
            : debtToCover;

        (
            vars.maxCollateralToLiquidate,
            vars.debtAmountNeeded
        ) = _calculateAvailableCollateralToLiquidate(
            collateralReserve,
            debtReserve,
            collateralAsset,
            debtAsset,
            vars.actualDebtToLiquidate,
            vars.userCollateralBalance
        );

        // If debtAmountNeeded < actualDebtToLiquidate, there isn't enough
        // collateral to cover the actual amount that is being liquidated, hence we liquidate
        // a smaller amount

        if (vars.debtAmountNeeded < vars.actualDebtToLiquidate) {
            vars.actualDebtToLiquidate = vars.debtAmountNeeded;
        }

        // If the liquidator reclaims the underlying asset, we make sure there is enough available liquidity in the
        // collateral reserve
        if (!receiveKToken) {
            uint256 currentAvailableCollateral = IERC20(collateralAsset).balanceOf(
                address(vars.collateralKtoken)
            );
            if (currentAvailableCollateral < vars.maxCollateralToLiquidate) {
                return (
                    uint256(Errors.CollateralManagerErrors.NOT_ENOUGH_LIQUIDITY),
                    Errors.LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE
                );
            }
        }

        debtReserve.updateState();

        if (vars.userVariableDebt >= vars.actualDebtToLiquidate) {
            IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
                user,
                vars.actualDebtToLiquidate,
                debtReserve.variableBorrowIndex
            );
        } else {
            // If the user doesn't have variable debt, no need to try to burn variable debt tokens
            if (vars.userVariableDebt > 0) {
                IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
                    user,
                    vars.userVariableDebt,
                    debtReserve.variableBorrowIndex
                );
            }
            IStableDebtToken(debtReserve.stableDebtTokenAddress).burn(
                user,
                vars.actualDebtToLiquidate - vars.userVariableDebt
            );
        }

        debtReserve.updateInterestRates(
            debtAsset,
            debtReserve.kTokenAddress,
            vars.actualDebtToLiquidate,
            0
        );

        if (receiveKToken) {
            vars.liquidatorPreviousKTokenBalance = IERC20(vars.collateralKtoken).balanceOf(
                msg.sender
            );
            vars.collateralKtoken.transferOnLiquidation(
                user,
                msg.sender,
                vars.maxCollateralToLiquidate
            );

            if (vars.liquidatorPreviousKTokenBalance == 0) {
                DataTypes.UserConfigurationMap storage liquidatorConfig = _usersConfig[msg.sender];
                liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
                emit ReserveUsedAsCollateralEnabled(collateralAsset, msg.sender);
            }
        } else {
            collateralReserve.updateState();
            collateralReserve.updateInterestRates(
                collateralAsset,
                address(vars.collateralKtoken),
                0,
                vars.maxCollateralToLiquidate
            );

            // Burn the equivalent amount of kToken, sending the underlying to the liquidator
            vars.collateralKtoken.burn(
                user,
                msg.sender,
                vars.maxCollateralToLiquidate,
                collateralReserve.liquidityIndex
            );
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.maxCollateralToLiquidate == vars.userCollateralBalance) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit ReserveUsedAsCollateralDisabled(collateralAsset, user);
        }

        // Transfers the debt asset being repaid to the kToken, where the liquidity is kept
        IERC20(debtAsset).safeTransferFrom(
            msg.sender,
            debtReserve.kTokenAddress,
            vars.actualDebtToLiquidate
        );

        emit LiquidationCall(
            collateralAsset,
            debtAsset,
            user,
            vars.actualDebtToLiquidate,
            vars.maxCollateralToLiquidate,
            msg.sender,
            receiveKToken
        );

        return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.LPCM_NO_ERRORS);
    }

    struct AvailableCollateralToLiquidateLocalVars {
        uint256 userCompoundedBorrowBalance;
        uint256 liquidationBonus;
        uint256 collateralPrice;
        uint256 debtAssetPrice;
        uint256 maxAmountCollateralToLiquidate;
        uint256 debtAssetDecimals;
        uint256 collateralDecimals;
    }

    /**
     * @dev Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * - This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param debtReserve The data of the debt reserve
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
     * @return collateralAmount: The maximum amount that is possible to liquidate given all the liquidation constraints
     *                           (user balance, close factor)
     *         debtAmountNeeded: The amount to repay with the liquidation
     **/
    function _calculateAvailableCollateralToLiquidate(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveData storage debtReserve,
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover,
        uint256 userCollateralBalance
    ) internal view returns (uint256, uint256) {
        uint256 collateralAmount = 0;
        uint256 debtAmountNeeded = 0;
        IPriceOracleGetter oracle = IPriceOracleGetter(_addressesProvider.getPriceOracle());

        AvailableCollateralToLiquidateLocalVars memory vars;

        vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
        vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);

        (, , vars.liquidationBonus, vars.collateralDecimals, ) = collateralReserve
            .configuration
            .getParams();
        vars.debtAssetDecimals = debtReserve.configuration.getDecimals();

        // This is the maximum possible amount of the selected collateral that can be liquidated, given the
        // max amount of liquidatable debt
        vars.maxAmountCollateralToLiquidate =
            (
                (vars.debtAssetPrice * debtToCover * (10 ** vars.collateralDecimals)).percentMul(
                    vars.liquidationBonus
                )
            ) /
            (vars.collateralPrice * (10 ** vars.debtAssetDecimals));

        if (vars.maxAmountCollateralToLiquidate > userCollateralBalance) {
            collateralAmount = userCollateralBalance;
            debtAmountNeeded = ((vars.collateralPrice *
                collateralAmount *
                (10 ** vars.debtAssetDecimals)) /
                (vars.debtAssetPrice * (10 ** vars.collateralDecimals))).percentDiv(
                    vars.liquidationBonus
                );
        } else {
            collateralAmount = vars.maxAmountCollateralToLiquidate;
            debtAmountNeeded = debtToCover;
        }
        return (collateralAmount, debtAmountNeeded);
    }
}
