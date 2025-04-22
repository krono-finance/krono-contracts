// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

interface IReserveInterestRateStrategy {
    function baseVariableBorrowRate() external view returns (uint256);

    function getMaxVariableBorrowRate() external view returns (uint256);

    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    ) external view returns (uint256, uint256, uint256);

    function calculateInterestRates(
        address reserve,
        address kToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor
    )
        external
        view
        returns (uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate);
}
