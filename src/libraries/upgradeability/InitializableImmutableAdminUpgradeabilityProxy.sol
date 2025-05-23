// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {InitializableUpgradeabilityProxy} from "../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol";
import {Proxy} from "../../dependencies/openzeppelin/upgradeability/Proxy.sol";
import {BaseImmutableAdminUpgradeabilityProxy} from "./BaseImmutableAdminUpgradeabilityProxy.sol";

contract InitializableImmutableAdminUpgradeabilityProxy is
    BaseImmutableAdminUpgradeabilityProxy,
    InitializableUpgradeabilityProxy
{
    /**
     * @dev Constructor.
     * @param admin The address of the admin
     */
    constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {
        // Intentionally left blank
    }

    /// @inheritdoc BaseImmutableAdminUpgradeabilityProxy
    function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
        BaseImmutableAdminUpgradeabilityProxy._willFallback();
    }
}
