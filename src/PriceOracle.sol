// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

contract PriceOracle is RapidDemoConsumerBase {
    mapping(address => bytes32) public assetToDataFeedId;

    function getLatestPrice(bytes32 dataFeedId) public view returns (uint256) {
        return getOracleNumericValueFromTxMsg(dataFeedId);
    }

    function setAssetSource(address asset, bytes32 dataFeedId) external {
        assetToDataFeedId[asset] = dataFeedId;
    }

    function getAssetPrice(address asset) public view virtual returns (uint256) {
        bytes32 feedId = assetToDataFeedId[asset];
        require(feedId != bytes32(0), "No data feed for asset");
        return getOracleNumericValueFromTxMsg(feedId);
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }
}
