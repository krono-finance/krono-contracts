// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "../dependencies/openzeppelin/contracts/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint amount) external {
        _mint(account, amount);
    }
}
