// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

interface ILendingPoolAddressesProviderRegistry {
    event AddressesProviderRegistered(address indexed newAddress);
    event AddressesProviderUnregistered(address indexed newAddress);

    function getAddressesProvidersList() external view returns (address[] memory);

    function getAddressesProviderIdByAddress(
        address addressesProvider
    ) external view returns (uint256);

    function registerAddressesProvider(address provider, uint256 id) external;

    function unregisterAddressesProvider(address provider) external;
}
