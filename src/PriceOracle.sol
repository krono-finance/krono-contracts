// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

contract PriceOracle is RapidDemoConsumerBase {
    function getLatestEthPrice() public view returns (uint256) {
        bytes32 dataFeedId = bytes32("ETH");
        return getOracleNumericValueFromTxMsg(dataFeedId);
    }
}
