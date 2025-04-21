// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IDelegationToken} from "../interfaces/IDelegationToken.sol";
import {Errors} from "../libraries/Errors.sol";
import {KToken} from "./KToken.sol";

contract DelegationAwareKToken is KToken {
    modifier onlyPoolAdmin() {
        require(
            _msgSender() == ILendingPool(_pool).getAddressesProvider().getPoolAdmin(),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev Delegates voting power of the underlying asset to a `delegatee` address
     * @param delegatee The address that will receive the delegation
     **/
    function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
        IDelegationToken(_underlyingAsset).delegate(delegatee);
    }
}
