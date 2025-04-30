// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MockPriceOracle {
    mapping(address => uint256) private assetPrices;

    function setAssetPrice(address asset, uint256 value) external {
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
