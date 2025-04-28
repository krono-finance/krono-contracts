// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../PriceOracle.sol";

contract MockPriceOracle is PriceOracle {
    uint256 private mockValue;

    function setMockValue(uint256 _value) external {
        mockValue = _value;
    }

    function getOracleNumericValueFromTxMsg(
        bytes32 /*dataFeedId*/
    ) internal view override returns (uint256) {
        return mockValue;
    }

    function getAssetPrice(address asset) public view override returns (uint256) {
        return mockValue;
    }
}
