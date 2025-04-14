// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Reserve.sol";
import "./UserConfiguration.sol";
import "./PriceOracle.sol";

contract LendingPool is Ownable {
    InterestRateStrategy public immutable strategy;
    UserConfiguration public userConfig;
    PriceOracle public priceOracle;

    struct ReserveData {
        Reserve reserve;
        bool isActive;
    }

    mapping(address => ReserveData) public reserves;
    mapping(address => mapping(address => uint256)) public userBalances;
    mapping(address => mapping(address => uint256)) public userBorrows;

    constructor(address _userConfig, address _priceOracle) Ownable(msg.sender) {
        userConfig = UserConfiguration(_userConfig);
        priceOracle = PriceOracle(_priceOracle);
    }

    modifier onlyActiveReserve(address asset) {
        require(reserves[asset].isActive, "Asset not supported");
        _;
    }

    function addReserve(address asset, address reserveAddress) external {
        reserves[asset] = ReserveData({
            reserve: Reserve(reserveAddress),
            isActive: true
        });
    }

    // Supply / Collateral
    function supply(
        address asset,
        uint256 amount
    ) external onlyActiveReserve(asset) {
        userBalances[msg.sender][asset] += amount;
        reserves[asset].reserve.increaseSupply(amount);
        IERC20(asset).transferFrom(
            msg.sender,
            address(reserves[asset].reserve),
            amount
        );
    }

    // Withdraw
    function withdraw(
        address asset,
        uint256 amount
    ) external onlyActiveReserve(asset) {
        require(
            userBalances[msg.sender][asset] >= amount,
            "Insufficient balance"
        );
        userBalances[msg.sender][asset] -= amount;
        reserves[asset].reserve.decreaseSupply(amount);
        IERC20(asset).transfer(msg.sender, amount);
    }

    // Borrow
    function borrow(
        address asset,
        uint256 amount
    ) external onlyActiveReserve(asset) {
        require(
            _isCollateralized(msg.sender, amount, asset),
            "Undercollateralized"
        );
        reserves[asset].reserve.increaseBorrow(amount);
        userBorrows[msg.sender][asset] += amount;
        IERC20(asset).transfer(msg.sender, amount);
    }

    // Repay
    function repay() external {}

    // Enable/disable supplied assets as collateral
    function toggleCollateral() external {}

    // Liquidate
    function liquidate() external {}

    // isCollateralEnabled check
    function _isCollateralized(
        address user,
        uint256 borrowAmount,
        address borrowAsset
    ) internal view returns (bool) {}
}
