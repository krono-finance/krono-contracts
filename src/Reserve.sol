// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InterestRateStrategy.sol";

contract Reserve {
    IERC20 public immutable asset;
    InterestRateStrategy public immutable strategy;

    // Configurable params
    InterestRateStrategy.InterestRateParams public rateParams;

    // Reserve data
    uint256 public totalSupplied;
    uint256 public totalBorrowed;

    uint256 public liquidityRate; // interest to suppliers
    uint256 public borrowRate; // interest to borrowers

    constructor(
        address _asset,
        address _strategy,
        InterestRateStrategy.InterestRateParams memory _params
    ) {
        asset = IERC20(_asset);
        strategy = InterestRateStrategy(_strategy);
        rateParams = _params;
    }

    function updateInterestRates() public {
        (uint256 newLiquidityRate, uint256 newBorrowRate) = strategy
            .calculateInterestRates(
                asset.balanceOf(address(this)),
                totalBorrowed,
                rateParams
            );

        liquidityRate = newLiquidityRate;
        borrowRate = newBorrowRate;
    }

    // called by LendingPool after a supply/deposit
    function increaseSupply(uint256 amount) external {
        totalSupplied += amount;
        updateInterestRates();
    }

    // called by LendingPool after a borrow
    function increaseBorrow(uint256 amount) external {
        totalBorrowed += amount;
        updateInterestRates();
    }

    // called by LendingPool after a repay
    function decreaseBorrow(uint256 amount) external {
        totalBorrowed -= amount;
        updateInterestRates();
    }

    // called by LendingPool after a withdraw
    function decreaseSupply(uint256 amount) external {
        totalSupplied -= amount;
        updateInterestRates();
    }
}
