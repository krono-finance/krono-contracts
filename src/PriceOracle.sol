// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

contract PriceOracle is RapidDemoConsumerBase {
    function getLatestPrice(bytes32 dataFeedId) public view returns (uint256) {
        return getOracleNumericValueFromTxMsg(dataFeedId);
    }
}
