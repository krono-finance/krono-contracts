// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {BaseUpgradeabilityProxy} from "../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol";

contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    address internal immutable _admin;

    /**
     * @dev Constructor.
     * @param adminAddress The address of the admin
     */
    constructor(address adminAddress) {
        _admin = adminAddress;
    }

    modifier ifAdmin() {
        if (msg.sender == _admin) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @notice Return the admin address
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return _admin;
    }

    /**
     * @notice Return the implementation address
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @notice Upgrade the backing implementation of the proxy.
     * @dev Only the admin can call this function.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @notice Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * @dev This is useful to initialize the proxied contract.
     * @param newImplementation The address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    ) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @notice Only fall back when the sender is not the admin.
     */
    function _willFallback() internal virtual override {
        require(msg.sender != _admin, "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }
}
