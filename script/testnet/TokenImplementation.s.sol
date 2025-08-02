// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import {KToken} from "../../src/tokenization/KToken.sol";
import {VariableDebtToken} from "../../src/tokenization/VariableDebtToken.sol";
import {StableDebtToken} from "../../src/tokenization/StableDebtToken.sol";
import {ERC20} from "../../src/dependencies/openzeppelin/contracts/ERC20.sol";
import {DefaultReserveInterestRateStrategy} from "../../src/DefaultReserveInterestRateStrategy.sol";
import {LendingPoolAddressesProvider} from "../../src/configuration/LendingPoolAddressesProvider.sol";
import {LendingPoolConfigurator} from "../../src/LendingPoolConfigurator.sol";
import {LendingRateOracle} from "../../src/mocks/LendingRateOracle.sol";
import {ILendingPoolConfigurator} from "../../src/interfaces/ILendingPoolConfigurator.sol";
import {ILendingPool} from "../../src/interfaces/ILendingPool.sol";

contract DeployTokenImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start Deployments
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Token Implementation
        // 1. KToken
        // 2. VariableDebtToken
        // 3. StableDebtToken
        KToken kTokenImpl = new KToken();
        VariableDebtToken variableDebtTokenImpl = new VariableDebtToken();
        StableDebtToken stableDebtTokenImpl = new StableDebtToken();

        // Log deployed contract addresses
        console.log("KToken Implementation:", address(kTokenImpl));
        console.log("Variable Debt Token Implementation:", address(variableDebtTokenImpl));
        console.log("Stable Debt Token Implementation:", address(stableDebtTokenImpl));

        vm.stopBroadcast();
    }
}
