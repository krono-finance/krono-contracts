// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract InterestRateStrategy {
    struct InterestRateParams {
        uint256 optimalUtilizationRate; // in ray (1e27)
        uint256 baseRate; // in ray
        uint256 slope1; // in ray
        uint256 slope2; // in ray
    }

    uint256 internal constant RAY = 1e27;

    function calculateInterestRates(
        uint256 availableLiquidity,
        uint256 totalBorrowed,
        InterestRateParams memory params
    ) external pure returns (uint256 liquidityRate, uint256 borrowRate) {
        uint256 utilizationRate = _utilizationRate(
            availableLiquidity,
            totalBorrowed
        );

        if (utilizationRate < params.optimalUtilizationRate) {
            // Before optimal
            borrowRate =
                params.baseRate +
                (params.slope1 * utilizationRate) /
                params.optimalUtilizationRate;
        } else {
            // After optimal
            uint256 excessUtilization = utilizationRate -
                params.optimalUtilizationRate;
            uint256 excessRatio = RAY - params.optimalUtilizationRate;

            borrowRate =
                params.baseRate +
                params.slope1 +
                (params.slope2 * excessUtilization) /
                excessRatio;
        }

        // Simplified: liquidity rate = borrowRate * utilizationRate
        liquidityRate = (borrowRate * utilizationRate) / RAY;
    }

    function _utilizationRate(
        uint256 availableLiquidity,
        uint256 totalBorrowed
    ) internal pure returns (uint256) {
        if (totalBorrowed == 0) return 0;
        uint256 total = availableLiquidity + totalBorrowed;
        return (totalBorrowed * RAY) / total;
    }
}
