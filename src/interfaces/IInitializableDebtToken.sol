// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {ILendingPool} from "./ILendingPool.sol";
import {IIncentivesController} from "./IIncentivesController.sol";

interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated lending pool
     * @param incentivesController The address of the incentives controller for this kToken
     * @param debtTokenDecimals the decimals of the debt token
     * @param debtTokenName the name of the debt token
     * @param debtTokenSymbol the symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @dev Initializes the debt token.
     * @param pool The address of the lending pool where this kToken will be used
     * @param underlyingAsset The address of the underlying asset of this kToken (E.g. WETH for kWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     */
    function initialize(
        ILendingPool pool,
        address underlyingAsset,
        IIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}
