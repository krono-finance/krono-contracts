// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {IReserveInterestRateStrategy} from "./interfaces/IReserveInterestRateStrategy.sol";
import {WadRayMath} from "./libraries/math/WadRayMath.sol";
import {PercentageMath} from "./libraries/math/PercentageMath.sol";
import {ILendingPoolAddressesProvider} from "./interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingRateOracle} from "./interfaces/ILendingRateOracle.sol";
import {IERC20} from "./dependencies/openzeppelin/contracts/IERC20.sol";

contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    /**
     * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
     * Expressed in ray
     **/
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;

    /**
     * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
     * 1-optimal utilization rate. Added as a constant here for gas optimizations.
     * Expressed in ray
     **/

    uint256 public immutable EXCESS_UTILIZATION_RATE;

    ILendingPoolAddressesProvider public immutable addressesProvider;

    // Base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _stableRateSlope1;

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _stableRateSlope2;

    constructor(
        ILendingPoolAddressesProvider provider,
        uint256 optimalUtilizationRate,
        uint256 kbaseVariableBorrowRate,
        uint256 kvariableRateSlope1,
        uint256 kvariableRateSlope2,
        uint256 kstableRateSlope1,
        uint256 kstableRateSlope2
    ) {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        EXCESS_UTILIZATION_RATE = WadRayMath.ray() - optimalUtilizationRate;
        addressesProvider = provider;
        _baseVariableBorrowRate = kbaseVariableBorrowRate;
        _variableRateSlope1 = kvariableRateSlope1;
        _variableRateSlope2 = kvariableRateSlope2;
        _stableRateSlope1 = kstableRateSlope1;
        _stableRateSlope2 = kstableRateSlope2;
    }

    function variableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    function variableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    function stableRateSlope1() external view returns (uint256) {
        return _stableRateSlope1;
    }

    function stableRateSlope2() external view returns (uint256) {
        return _stableRateSlope2;
    }

    function baseVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate;
    }

    function getMaxVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations
     * @param reserve The address of the reserve
     * @param liquidityAdded The liquidity added during the operation
     * @param liquidityTaken The liquidity taken during the operation
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param averageStableBorrowRate The weighted average of all the stable rate loans
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate, the stable borrow rate and the variable borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        address kToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    ) external view override returns (uint256, uint256, uint256) {
        uint256 availableLiquidity = IERC20(reserve).balanceOf(kToken);
        //avoid stack too deep
        availableLiquidity = availableLiquidity + liquidityAdded - liquidityTaken;

        return
            calculateInterestRates(
                reserve,
                availableLiquidity,
                totalStableDebt,
                totalVariableDebt,
                averageStableBorrowRate,
                reserveFactor
            );
    }

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentStableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
     * New protocol implementation uses the new calculateInterestRates() interface
     * @param reserve The address of the reserve
     * @param availableLiquidity The liquidity available in the corresponding kToken
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param averageStableBorrowRate The weighted average of all the stable rate loans
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate, the stable borrow rate and the variable borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    ) public view override returns (uint256, uint256, uint256) {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = totalStableDebt + totalVariableDebt;
        vars.currentVariableBorrowRate = 0;
        vars.currentStableBorrowRate = 0;
        vars.currentLiquidityRate = 0;

        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity + vars.totalDebt);

        vars.currentStableBorrowRate = ILendingRateOracle(addressesProvider.getLendingRateOracle())
            .getMarketBorrowRate(reserve);

        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = (vars.utilizationRate - OPTIMAL_UTILIZATION_RATE)
                .rayDiv(EXCESS_UTILIZATION_RATE);

            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                _stableRateSlope1 +
                _stableRateSlope2.rayMul(excessUtilizationRateRatio);

            vars.currentVariableBorrowRate =
                _baseVariableBorrowRate +
                _variableRateSlope1 +
                _variableRateSlope2.rayMul(excessUtilizationRateRatio);
        } else {
            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                _stableRateSlope1.rayMul(vars.utilizationRate.rayDiv(OPTIMAL_UTILIZATION_RATE));
            vars.currentVariableBorrowRate =
                _baseVariableBorrowRate +
                vars.utilizationRate.rayMul(_variableRateSlope1).rayDiv(OPTIMAL_UTILIZATION_RATE);
        }

        vars.currentLiquidityRate = _getOverallBorrowRate(
            totalStableDebt,
            totalVariableDebt,
            vars.currentVariableBorrowRate,
            averageStableBorrowRate
        ).rayMul(vars.utilizationRate).percentMul(PercentageMath.PERCENTAGE_FACTOR - reserveFactor);

        return (
            vars.currentLiquidityRate,
            vars.currentStableBorrowRate,
            vars.currentVariableBorrowRate
        );
    }

    /**
     * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable debt
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param currentVariableBorrowRate The current variable borrow rate of the reserve
     * @param currentAverageStableBorrowRate The current weighted average of all the stable rate loans
     * @return The weighted averaged borrow rate
     **/
    function _getOverallBorrowRate(
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 currentVariableBorrowRate,
        uint256 currentAverageStableBorrowRate
    ) internal pure returns (uint256) {
        uint256 totalDebt = totalStableDebt + totalVariableDebt;

        if (totalDebt == 0) return 0;

        uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(
            currentVariableBorrowRate
        );

        uint256 weightedStableRate = totalStableDebt.wadToRay().rayMul(
            currentAverageStableBorrowRate
        );

        uint256 overallBorrowRate = (weightedVariableRate + weightedStableRate).rayDiv(
            totalDebt.wadToRay()
        );

        return overallBorrowRate;
    }
}
