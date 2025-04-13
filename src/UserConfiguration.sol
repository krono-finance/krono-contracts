// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract UserConfiguration {
    mapping(address => mapping(address => bool)) public userCollateralEnabled;

    function isCollateralEnabled(
        address user,
        address asset
    ) external view returns (bool) {
        return userCollateralEnabled[user][asset];
    }

    function setCollateralEnabled(
        address user,
        address asset,
        bool enabled
    ) external {
        // Only callable by LendingPool or trusted contract
        require(msg.sender == tx.origin, "Not authorized"); // TEMP: should restrict in prod
        userCollateralEnabled[user][asset] = enabled;
    }
}
