// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@redstone-finance/evm-connector/contracts/data-services/RapidDemoConsumerBase.sol";

contract PriceOracle is RapidDemoConsumerBase {
    mapping(address => bytes32) public assetToDataFeedId;
    mapping(address => uint256) private assetPrices;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function getLatestPrice(bytes32 dataFeedId) public view returns (uint256) {
        return getOracleNumericValueFromTxMsg(dataFeedId);
    }

    function setAssetPrice(address asset, uint256 value) external onlyOwner {
        assetPrices[asset] = value;
    }

    function getAssetPrice(address asset) public view returns (uint256) {
        return assetPrices[asset];
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }
}
