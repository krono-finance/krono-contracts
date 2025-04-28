// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../src/LendingPoolConfigurator.sol";
import "../src/configuration/LendingPoolAddressesProvider.sol";
import "../src/tokenization/KToken.sol";
import "../src/tokenization/VariableDebtToken.sol";
import "../src/tokenization/StableDebtToken.sol";
import "../src/dependencies/openzeppelin/contracts/IERC20.sol";
import "../src/dependencies/openzeppelin/contracts/ERC20.sol";
import "../src/mocks/MockPriceOracle.sol";
import "../src/mocks/MockERC20.sol";
import "../src/DefaultReserveInterestRateStrategy.sol";
import "../src/interfaces/ILendingRateOracle.sol";
import "../src/mocks/LendingRateOracle.sol";

contract LendingPoolTest is Test {
    LendingPool public lendingPool;
    LendingPoolConfigurator public configurator;
    LendingPoolAddressesProvider public addressesProvider;
    MockPriceOracle public priceOracle;
    LendingRateOracle public lendingRateOracle;

    // Tokens
    MockERC20 public usdc;
    KToken public kUSDC;
    VariableDebtToken public variableDebtUSDC;
    StableDebtToken public stableDebtUSDC;

    // Interest rate strategies
    DefaultReserveInterestRateStrategy public idrxStrategy;
    DefaultReserveInterestRateStrategy public usdcStrategy;

    // Test accounts
    address public constant ADMIN = address(0x1);
    address public constant ALICE = address(0x2);
    address public constant BOB = address(0x3);

    // Constants for rate strategies
    uint256 public constant OPTIMAL_UTILIZATION_RATE = 0.8e27;
    uint256 public constant BASE_VARIABLE_BORROW_RATE = 0.01e27;
    uint256 public constant VARIABLE_RATE_SLOPE1 = 0.02e27;
    uint256 public constant VARIABLE_RATE_SLOPE2 = 0.75e27;
    uint256 public constant STABLE_RATE_SLOPE1 = 0.02e27;
    uint256 public constant STABLE_RATE_SLOPE2 = 0.75e27;
    uint256 public constant EXCESS_UTILIZATION_RATE = 0.2e27;

    function setUp() public {
        vm.startPrank(ADMIN);

        // Deploy core contracts
        addressesProvider = new LendingPoolAddressesProvider("Krono Market");
        lendingPool = new LendingPool();
        configurator = new LendingPoolConfigurator();
        priceOracle = new MockPriceOracle();
        lendingRateOracle = new LendingRateOracle();

        addressesProvider.setLendingPoolImpl(address(lendingPool));
        addressesProvider.setLendingPoolConfiguratorImpl(address(configurator));
        addressesProvider.setPriceOracle(address(priceOracle));
        addressesProvider.setPoolAdmin(ADMIN);
        addressesProvider.setLendingRateOracle(address(lendingRateOracle));

        lendingPool.initialize(addressesProvider);
        configurator.initialize(addressesProvider);

        priceOracle.setMockValue(1e8); // 1 USD

        // Deploy tokens
        usdc = new MockERC20("USD Coin", "USDC");
        kUSDC = new KToken();
        variableDebtUSDC = new VariableDebtToken();
        stableDebtUSDC = new StableDebtToken();

        usdc.mint(ADMIN, 10000000000e18);

        // Deploy interest rate strategies
        usdcStrategy = new DefaultReserveInterestRateStrategy(
            addressesProvider,
            OPTIMAL_UTILIZATION_RATE,
            BASE_VARIABLE_BORROW_RATE,
            VARIABLE_RATE_SLOPE1,
            VARIABLE_RATE_SLOPE2,
            STABLE_RATE_SLOPE1,
            STABLE_RATE_SLOPE2
        );

        // Initialize Reserve and Tokens
        LendingPoolConfigurator.InitReserveInput[]
            memory inputs = new LendingPoolConfigurator.InitReserveInput[](1);

        console.log(address(usdc));

        inputs[0] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: address(kUSDC),
            stableDebtTokenImpl: address(stableDebtUSDC),
            variableDebtTokenImpl: address(variableDebtUSDC),
            underlyingAssetDecimals: 18,
            interestRateStrategyAddress: address(usdcStrategy),
            underlyingAsset: address(usdc),
            treasury: msg.sender,
            incentivesController: address(0), // Optional
            underlyingAssetName: "USDC",
            kTokenName: "Krono USDC",
            kTokenSymbol: "kUSDC",
            stableDebtTokenName: "Krono Stable Debt USDC",
            stableDebtTokenSymbol: "stableDebtUSDC",
            variableDebtTokenName: "Krono Variable Debt USDC",
            variableDebtTokenSymbol: "variableDebtUSDC",
            params: ""
        });

        address configuratorProxy = addressesProvider.getLendingPoolConfigurator();
        address lendingRateProxy = addressesProvider.getLendingRateOracle();

        LendingPoolConfigurator(configuratorProxy).batchInitReserve(inputs);
        LendingPoolConfigurator(configuratorProxy).configureReserveAsCollateral(
            address(usdc),
            8000, // 80% LTV
            8500, // 85% Liquidation Threshold
            10500 // 5% Liquidation Bonus
        );
        LendingPoolConfigurator(configuratorProxy).enableBorrowingOnReserve(address(usdc), false);

        // This is just for compatibility (Stable rate mode won't be used in production)
        LendingRateOracle(lendingRateProxy).setMarketBorrowRate(
            address(usdc),
            90000000000000000000000000
        );

        // Fund test users
        usdc.transfer(ALICE, 10000e18);
        usdc.transfer(BOB, 10000e18);

        vm.stopPrank();
    }

    function testInitialization() public view {
        assertEq(address(lendingPool.getAddressesProvider()), address(addressesProvider));
    }

    function testDeposit() public {
        uint256 depositAmount = 1000e18;

        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address kUSDCProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .kTokenAddress;

        assertEq(KToken(kUSDCProxy).balanceOf(ALICE), 0);

        usdc.approve(address(lendingPoolProxy), depositAmount);
        LendingPool(lendingPoolProxy).deposit(address(usdc), depositAmount, ALICE, 0);

        assertEq(KToken(kUSDCProxy).balanceOf(ALICE), depositAmount);

        vm.stopPrank();
    }

    function testWithdraw() public {
        // First set up by depositing
        testDeposit();

        uint256 withdrawAmount = 500e18; // half

        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();

        // Withdraw tokens
        LendingPool(lendingPoolProxy).withdraw(address(usdc), withdrawAmount, ALICE);

        // Assertions
        address kUSDCProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .kTokenAddress;

        assertEq(KToken(kUSDCProxy).balanceOf(ALICE), withdrawAmount);

        vm.stopPrank();
    }

    function testBorrow() public {
        // First set up by depositing collateral
        testDeposit();

        uint256 borrowAmount = 500e18;

        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address variableDebtProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .variableDebtTokenAddress;

        // Enable collateral
        LendingPool(lendingPoolProxy).setUserUseReserveAsCollateral(address(usdc), true);

        // Borrow tokens
        LendingPool(lendingPoolProxy).borrow(address(usdc), borrowAmount, 2, 0, ALICE);

        // Assertions
        assertEq(usdc.balanceOf(ALICE), 9000e18 + borrowAmount);
        assertEq(VariableDebtToken(variableDebtProxy).balanceOf(ALICE), borrowAmount);

        vm.stopPrank();
    }

    function testRepay() public {
        // First set up by borrowing
        testBorrow(); // borrow 500e18

        uint256 repayAmount = 200e18;

        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address variableDebtProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .variableDebtTokenAddress;

        // Approve tokens for repayment
        usdc.approve(address(lendingPoolProxy), repayAmount);

        // Repay tokens
        LendingPool(lendingPoolProxy).repay(address(usdc), repayAmount, 2, ALICE);

        // Assertions
        assertEq(VariableDebtToken(variableDebtProxy).balanceOf(ALICE), 300e18);

        vm.stopPrank();
    }
}
