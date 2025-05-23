// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {UserConfiguration} from "./libraries/UserConfiguration.sol";
import {ReserveConfiguration} from "./libraries/ReserveConfiguration.sol";
import {ReserveLogic} from "./libraries/logic/ReserveLogic.sol";
import {ILendingPoolAddressesProvider} from "./interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "./libraries/DataTypes.sol";

contract LendingPoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    ILendingPoolAddressesProvider internal _addressesProvider;

    mapping(address => DataTypes.ReserveData) internal _reserves;
    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    // the list of the available reserves, structured as a mapping for gas savings reasons
    mapping(uint256 => address) internal _reservesList;

    uint256 internal _reservesCount;

    bool internal _paused;

    uint256 internal _maxStableRateBorrowSizePercent;

    uint256 internal _flashLoanPremiumTotal;

    uint256 internal _maxNumberOfReserves;
}
