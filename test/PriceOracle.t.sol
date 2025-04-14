// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/mocks/MockPriceOracle.sol";

contract PriceOracleTest is Test {
    MockPriceOracle oracle;

    bytes32 ETH = bytes32("ETH");

    function setUp() public {
        oracle = new MockPriceOracle();
        oracle.setMockValue(1600e8);
    }

    function testGetLatestEthPrice() public view {
        uint256 ethPrice = oracle.getLatestPrice(ETH);
        console.log(ethPrice);
        assertGt(ethPrice, 0);
    }
}
