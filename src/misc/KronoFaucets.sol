// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";

contract KronoFaucets is Ownable {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant IDRX = 0xD63029C1a3dA68b51c67c6D1DeC3DEe50D681661;
    address public constant WBTC = 0xee6cB032769B7B76aaB233f7E068903B573249E5;
    address public constant USDC = 0xddb0c6b66Cf2BaCB6FB835a74c33be8ad728e596;
    address public constant USDT = 0x814c5aeA0dcEaF6b334499d080630071F0A336EF;

    uint256 public constant ETH_AMOUNT = 0.0005 ether;
    uint256 public constant IDRX_AMOUNT = 1000 * (10 ** 2);
    uint256 public constant WBTC_AMOUNT = 1 * (10 ** 8);
    uint256 public constant USDC_AMOUNT = 100000 * (10 ** 6);
    uint256 public constant USDT_AMOUNT = 100000 * (10 ** 6);

    uint256 public constant COOLDOWN_PERIOD = 1 days;

    mapping(address => mapping(address => uint256)) public lastClaimTime;

    // Claim a single token
    function claimToken(address token) external {
        uint256 amount;
        if (token == ETH) {
            amount = ETH_AMOUNT;
            require(address(this).balance >= amount, "Faucet empty");
            payable(msg.sender).transfer(amount);
        } else {
            if (token == IDRX) amount = IDRX_AMOUNT;
            else if (token == WBTC) amount = WBTC_AMOUNT;
            else if (token == USDC) amount = USDC_AMOUNT;
            else if (token == USDT) amount = USDT_AMOUNT;
            else revert("Unsupported token");

            require(IERC20(token).balanceOf(address(this)) >= amount, "Faucet empty");
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }

        lastClaimTime[token][msg.sender] = block.timestamp;
    }

    // Batch claim multiple tokens
    function batchClaim(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(
                block.timestamp >= lastClaimTime[token][msg.sender] + COOLDOWN_PERIOD,
                "Cooldown not passed"
            );

            uint256 amount;
            if (token == ETH) {
                amount = ETH_AMOUNT;
                require(address(this).balance >= amount, "Faucet empty");
                payable(msg.sender).transfer(amount);
            } else {
                if (token == IDRX) amount = IDRX_AMOUNT;
                else if (token == WBTC) amount = WBTC_AMOUNT;
                else if (token == USDC) amount = USDC_AMOUNT;
                else if (token == USDT) amount = USDT_AMOUNT;
                else revert("Unsupported token");

                require(IERC20(token).balanceOf(address(this)) >= amount, "Faucet empty");
                require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
            }

            lastClaimTime[token][msg.sender] = block.timestamp;
        }
    }

    // Owner functions to withdraw funds
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        if (token == ETH) {
            payable(msg.sender).transfer(amount);
        } else {
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }
    }

    // Receive ETH
    receive() external payable {}
}
