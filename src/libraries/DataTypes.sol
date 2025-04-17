// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title DataTypes library
 * @notice Defines the data structures used in the Krono lending protocol
 */
library DataTypes {
    // User configuration for collaterals and borrowing
    struct UserConfigurationMap {
        uint256 data;
    }

    // Reserve configuration parameters
    struct ReserveConfigurationMap {
        uint256 data;
    }

    // Reserve data structure
    struct ReserveData {
        // Reserve configuration
        ReserveConfigurationMap configuration;
        // Liquidity index, expressed in ray. Increases over time as interest accrues
        uint128 liquidityIndex;
        // Variable borrow index, expressed in ray. Increases over time as interest accrues
        uint128 variableBorrowIndex;
        // Current supply rate, expressed in ray
        uint128 currentLiquidityRate;
        // Current variable borrow rate, expressed in ray
        uint128 currentVariableBorrowRate;
        // Last updated timestamp for the indices
        uint40 lastUpdateTimestamp;
        // ID of reserve. Starts from 0
        uint16 id;
        // Address of the kToken contract for this asset
        address kTokenAddress;
        // Address of the variable debt token for this asset
        address variableDebtTokenAddress;
        // Address of the interest rate strategy
        address interestRateStrategyAddress;
    }

    // Reserve parameters used for initialization
    struct InitReserveParams {
        address asset;
        address kTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxReservesCount;
    }

    // Protocol fee parameters
    struct ProtocolFees {
        // Fee percentage, expressed in basis points
        uint256 flashLoanFeePercentage;
        // Percentage of the fee sent to protocol treasury, expressed in basis points
        uint256 protocolFeePercentage;
    }

    // Interest rate parameters
    struct InterestRateParams {
        uint256 optimalUtilizationRate;
        uint256 baseRate;
        uint256 slope1;
        uint256 slope2;
    }
}
