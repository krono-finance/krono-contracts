// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "../dependencies/openzeppelin/contracts/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _setupDecimals(decimals_);
    }

    function mint(address account, uint amount) external {
        _mint(account, amount);
    }
}
