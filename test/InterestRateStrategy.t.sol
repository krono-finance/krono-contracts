// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/InterestRateStrategy.sol";

contract InterestRateStrategyTest is Test {
    InterestRateStrategy interestRateStrategy;

    uint256 internal constant RAY = 1e27;

    InterestRateStrategy.InterestRateParams params;

    function setUp() public {
        interestRateStrategy = new InterestRateStrategy();

        params = InterestRateStrategy.InterestRateParams({
            optimalUtilizationRate: 8e26, // 80% in ray
            baseRate: 1e25, // 1% in ray
            slope1: 4e25, // 4% in ray
            slope2: 75e25 // 75% in ray
        });
    }

    function test_zero_utilization() public view {
        uint256 availableLiquidity = 1000 ether;
        uint256 totalBorrowed = 0;

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(availableLiquidity, totalBorrowed, params);

        console.log("Liquidity Rate: ", liquidityRate);
        console.log("Borrow Rate: ", borrowRate);

        assertEq(
            liquidityRate,
            0,
            "Liquidity rate should be 0 when nothing is borrowed"
        );
        assertEq(
            borrowRate,
            params.baseRate,
            "Borrow rate should equal base rate when nothing is borrowed"
        );
    }

    function test_below_optimal_utilization() public view {
        uint256 availableLiquidity = 800 ether;
        uint256 totalBorrowed = 200 ether;
        // Utilization: 20%

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(availableLiquidity, totalBorrowed, params);

        // Expected borrow rate: baseRate + (slope1 * utilizationRate) / optimalUtilizationRate
        // = 1e25 + (4e25 * 2e26) / 8e26 = 1e25 + 1e25 = 2e25 (2%)
        uint256 expectedBorrowRate = 2e25;

        // Expected liquidity rate: borrowRate * utilizationRate / RAY
        // = 2e25 * 2e26 / 1e27 = 4e24 (0.4%)
        uint256 expectedLiquidityRate = 4e24;

        console.log(expectedLiquidityRate);
        console.log(liquidityRate);
        console.log(expectedBorrowRate);
        console.log(borrowRate);

        assertApproxEqAbs(
            borrowRate,
            expectedBorrowRate,
            1e15,
            "Borrow rate incorrect for below optimal utilization"
        );
        assertApproxEqAbs(
            liquidityRate,
            expectedLiquidityRate,
            1e15,
            "Liquidity rate incorrect for below optimal utilization"
        );
    }

    function test_at_optimal_utilization() public view {
        uint256 availableLiquidity = 200 ether;
        uint256 totalBorrowed = 800 ether;
        // Utilization: 80% (at optimal)

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(availableLiquidity, totalBorrowed, params);

        // Expected borrow rate: baseRate + (slope1 * utilizationRate) / optimalUtilizationRate
        // = 1e25 + (4e25 * 8e26) / 8e26 = 1e25 + 4e25 = 5e25 (5%)
        uint256 expectedBorrowRate = 5e25;

        // Expected liquidity rate: borrowRate * utilizationRate / RAY
        // = 5e25 * 8e26 / 1e27 = 4e25 (4%)
        uint256 expectedLiquidityRate = 4e25;

        console.log(expectedLiquidityRate);
        console.log(liquidityRate);
        console.log(expectedBorrowRate);
        console.log(borrowRate);

        assertApproxEqAbs(
            borrowRate,
            expectedBorrowRate,
            1e15,
            "Borrow rate incorrect at optimal utilization"
        );
        assertApproxEqAbs(
            liquidityRate,
            expectedLiquidityRate,
            1e15,
            "Liquidity rate incorrect at optimal utilization"
        );
    }

    function test_above_optimal_utilization() public view {
        uint256 availableLiquidity = 100 ether;
        uint256 totalBorrowed = 900 ether;
        // Utilization: 90% (above optimal)

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(availableLiquidity, totalBorrowed, params);

        // Expected borrow rate calculations:
        // excessUtilization = utilizationRate - optimalUtilizationRate = 9e26 - 8e26 = 1e26
        // excessRatio = RAY - optimalUtilizationRate = 1e27 - 8e26 = 2e26
        // borrowRate = baseRate + slope1 + (slope2 * excessUtilization) / excessRatio
        // = 1e25 + 4e25 + (75e25 * 1e26) / 2e26 = 5e25 + 37.5e25 = 42.5e25 (42.5%)
        uint256 expectedBorrowRate = 425e24;

        // Expected liquidity rate: borrowRate * utilizationRate / RAY
        // = 42.5e25 * 9e26 / 1e27 = 38.25e25 (38.25%)
        uint256 expectedLiquidityRate = 3825e23;

        console.log(expectedLiquidityRate);
        console.log(liquidityRate);
        console.log(expectedBorrowRate);
        console.log(borrowRate);

        assertEq(
            borrowRate,
            expectedBorrowRate,
            "Borrow rate incorrect above optimal utilization"
        );
        assertEq(
            liquidityRate,
            expectedLiquidityRate,
            "Liquidity rate incorrect above optimal utilization"
        );
    }

    function test_full_utilization() public view {
        uint256 availableLiquidity = 0;
        uint256 totalBorrowed = 1000 ether;
        // Utilization: 100%

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(availableLiquidity, totalBorrowed, params);

        // Expected borrow rate calculations:
        // excessUtilization = utilizationRate - optimalUtilizationRate = 1e27 - 8e26 = 2e26
        // excessRatio = RAY - optimalUtilizationRate = 1e27 - 8e26 = 2e26
        // borrowRate = baseRate + slope1 + (slope2 * excessUtilization) / excessRatio
        // = 1e25 + 4e25 + (75e25 * 2e26) / 2e26 = 5e25 + 75e25 = 80e25
        uint256 expectedBorrowRate = 80e25;

        // Expected liquidity rate: borrowRate * utilizationRate / RAY
        // = 80e25 * 1e27 / 1e27 = 80e25
        uint256 expectedLiquidityRate = 80e25;

        assertApproxEqAbs(
            borrowRate,
            expectedBorrowRate,
            1e15,
            "Borrow rate incorrect at full utilization"
        );
        assertApproxEqAbs(
            liquidityRate,
            expectedLiquidityRate,
            1e15,
            "Liquidity rate incorrect at full utilization"
        );
    }

    function test_fuzz_interest_rate_calculation(
        uint256 availableLiquidity,
        uint256 totalBorrowed
    ) public view {
        // Constrain inputs to reasonable values
        availableLiquidity = bound(availableLiquidity, 0, 1e30);
        totalBorrowed = bound(totalBorrowed, 0, 1e30);

        // Skip if we might have overflow
        if (availableLiquidity + totalBorrowed > type(uint256).max / RAY) {
            return;
        }

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(availableLiquidity, totalBorrowed, params);

        // Basic sanity checks
        if (totalBorrowed == 0) {
            assertEq(
                liquidityRate,
                0,
                "Liquidity rate should be 0 when nothing is borrowed"
            );
            assertEq(
                borrowRate,
                params.baseRate,
                "Borrow rate should equal base rate when nothing is borrowed"
            );
        } else {
            // Calculate utilization rate manually
            uint256 total = availableLiquidity + totalBorrowed;
            uint256 utilizationRate = (totalBorrowed * RAY) / total;

            // Verify liquidity rate formula
            uint256 calculatedLiquidityRate = (borrowRate * utilizationRate) /
                RAY;
            assertEq(
                liquidityRate,
                calculatedLiquidityRate,
                "Liquidity rate calculation mismatch"
            );

            // Borrow rate should never be less than base rate
            assertGe(
                borrowRate,
                params.baseRate,
                "Borrow rate should never be less than base rate"
            );

            // If utilization > optimal, borrow rate should be at least baseRate + slope1
            if (utilizationRate > params.optimalUtilizationRate) {
                assertGe(
                    borrowRate,
                    params.baseRate + params.slope1,
                    "Borrow rate should include at least slope1 when above optimal"
                );
            }
        }
    }

    function test_different_parameters() public view {
        // Test with different interest rate parameters
        InterestRateStrategy.InterestRateParams
            memory newParams = InterestRateStrategy.InterestRateParams({
                optimalUtilizationRate: 5 * 1e26, // 50% in ray
                baseRate: 2 * 1e25, // 2% in ray
                slope1: 6 * 1e25, // 6% in ray
                slope2: 100 * 1e25 // 100% in ray
            });

        uint256 availableLiquidity = 500 ether;
        uint256 totalBorrowed = 500 ether;
        // Utilization: 50% (at optimal for these params)

        (uint256 liquidityRate, uint256 borrowRate) = interestRateStrategy
            .calculateInterestRates(
                availableLiquidity,
                totalBorrowed,
                newParams
            );

        // Expected borrow rate: baseRate + (slope1 * utilizationRate) / optimalUtilizationRate
        // = 2e25 + (6e25 * 5e26) / 5e26 = 2e25 + 6e25 = 8e25 (8%)
        uint256 expectedBorrowRate = 8e25;

        // Expected liquidity rate: borrowRate * utilizationRate / RAY
        // = 8e25 * 5e26 / 1e27 = 4e25 (4%)
        uint256 expectedLiquidityRate = 4e25;

        assertApproxEqAbs(
            borrowRate,
            expectedBorrowRate,
            1e15,
            "Borrow rate incorrect with custom parameters"
        );
        assertApproxEqAbs(
            liquidityRate,
            expectedLiquidityRate,
            1e15,
            "Liquidity rate incorrect with custom parameters"
        );
    }
}
