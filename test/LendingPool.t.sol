// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/LendingPool.sol";
import "../src/LendingPoolConfigurator.sol";
import "../src/LendingPoolCollateralManager.sol";
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
    LendingPoolCollateralManager public collateralManager;
    LendingPoolAddressesProvider public addressesProvider;
    MockPriceOracle public priceOracle;
    LendingRateOracle public lendingRateOracle;

    // Tokens
    MockERC20 public usdc;
    MockERC20 public usdt;
    KToken public kUSDC;
    KToken public kUSDT;
    VariableDebtToken public variableDebtUSDC;
    VariableDebtToken public variableDebtUSDT;
    StableDebtToken public stableDebtUSDC;
    StableDebtToken public stableDebtUSDT;

    // Interest rate strategies
    DefaultReserveInterestRateStrategy public usdcStrategy;
    DefaultReserveInterestRateStrategy public usdtStrategy;

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
        collateralManager = new LendingPoolCollateralManager();
        priceOracle = new MockPriceOracle();
        lendingRateOracle = new LendingRateOracle();

        addressesProvider.setLendingPoolImpl(address(lendingPool));
        addressesProvider.setLendingPoolConfiguratorImpl(address(configurator));
        addressesProvider.setLendingPoolCollateralManager(address(collateralManager));
        addressesProvider.setPriceOracle(address(priceOracle));
        addressesProvider.setPoolAdmin(ADMIN);
        addressesProvider.setLendingRateOracle(address(lendingRateOracle));

        // Deploy tokens
        usdc = new MockERC20("USD Coin", "USDC", 6);
        usdt = new MockERC20("Tether", "USDT", 6);
        kUSDC = new KToken();
        kUSDT = new KToken();
        variableDebtUSDC = new VariableDebtToken();
        variableDebtUSDT = new VariableDebtToken();
        stableDebtUSDC = new StableDebtToken();
        stableDebtUSDT = new StableDebtToken();

        usdc.mint(ADMIN, 10000000000e18);
        usdt.mint(ADMIN, 10000000000e18);

        address priceOracleProxy = addressesProvider.getPriceOracle();
        MockPriceOracle(priceOracleProxy).setAssetPrice(address(usdc), 1e8);
        MockPriceOracle(priceOracleProxy).setAssetPrice(address(usdt), 1e8);

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
            memory inputs = new LendingPoolConfigurator.InitReserveInput[](2);

        inputs[0] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: address(kUSDC),
            stableDebtTokenImpl: address(stableDebtUSDC),
            variableDebtTokenImpl: address(variableDebtUSDC),
            underlyingAssetDecimals: 6,
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

        inputs[1] = ILendingPoolConfigurator.InitReserveInput({
            kTokenImpl: address(kUSDT),
            stableDebtTokenImpl: address(stableDebtUSDT),
            variableDebtTokenImpl: address(variableDebtUSDT),
            underlyingAssetDecimals: 6,
            interestRateStrategyAddress: address(usdcStrategy),
            underlyingAsset: address(usdt),
            treasury: msg.sender,
            incentivesController: address(0), // Optional
            underlyingAssetName: "USDT",
            kTokenName: "Krono USDT",
            kTokenSymbol: "kUSDT",
            stableDebtTokenName: "Krono Stable Debt USDT",
            stableDebtTokenSymbol: "stableDebtUSDT",
            variableDebtTokenName: "Krono Variable Debt USDT",
            variableDebtTokenSymbol: "variableDebtUSDT",
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
        LendingPoolConfigurator(configuratorProxy).configureReserveAsCollateral(
            address(usdt),
            8000, // 80% LTV
            8500, // 85% Liquidation Threshold
            10500 // 5% Liquidation Bonus
        );
        LendingPoolConfigurator(configuratorProxy).enableBorrowingOnReserve(address(usdc), false);
        LendingPoolConfigurator(configuratorProxy).enableBorrowingOnReserve(address(usdt), false);

        // This is just for compatibility (Stable rate mode won't be used in production)
        LendingRateOracle(lendingRateProxy).setMarketBorrowRate(
            address(usdc),
            90000000000000000000000000
        );
        LendingRateOracle(lendingRateProxy).setMarketBorrowRate(
            address(usdt),
            90000000000000000000000000
        );

        // Fund test users
        usdc.transfer(ALICE, 10000 * (10 ** usdc.decimals()));
        usdc.transfer(BOB, 10000 * (10 ** usdc.decimals()));
        usdt.transfer(ALICE, 10000 * (10 ** usdc.decimals()));
        usdt.transfer(BOB, 10000 * (10 ** usdc.decimals()));

        vm.stopPrank();
    }

    function testInitialization() public view {
        address lendingPoolProxy = addressesProvider.getLendingPool();
        assertEq(
            address(LendingPool(lendingPoolProxy).getAddressesProvider()),
            address(addressesProvider)
        );
    }

    function testDeposit() public {
        uint256 depositAmount = 1000 * (10 ** usdc.decimals());

        // ALICE USDC
        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address kUSDCProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .kTokenAddress;

        assertEq(KToken(kUSDCProxy).balanceOf(ALICE), 0, "Should be 0 KToken USDC");

        usdc.approve(address(lendingPoolProxy), depositAmount);
        LendingPool(lendingPoolProxy).deposit(address(usdc), depositAmount, ALICE, 0);

        assertEq(
            KToken(kUSDCProxy).balanceOf(ALICE),
            depositAmount,
            "KToken USDC Amount not match"
        );
        vm.stopPrank();

        // BOB USDT
        vm.startPrank(BOB);

        address kUSDTProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdt))
            .kTokenAddress;
        assertEq(KToken(kUSDTProxy).balanceOf(BOB), 0, "Should be 0 KToken USDT");

        usdt.approve(address(lendingPoolProxy), depositAmount);
        LendingPool(lendingPoolProxy).deposit(address(usdt), depositAmount, BOB, 0);

        assertEq(KToken(kUSDTProxy).balanceOf(BOB), depositAmount, "KToken USDT Amount not match");
        vm.stopPrank();
    }

    function testWithdraw() public {
        // First set up by depositing
        testDeposit();

        uint256 withdrawAmount = 500 * (10 ** usdc.decimals());

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address kUSDCProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .kTokenAddress;

        vm.startPrank(ALICE);

        console.log("Before Withdraw:", KToken(kUSDCProxy).balanceOf(ALICE));

        // Withdraw tokens
        LendingPool(lendingPoolProxy).withdraw(address(usdc), withdrawAmount, ALICE);

        console.log("After Withdraw:", KToken(kUSDCProxy).balanceOf(ALICE));

        assertEq(KToken(kUSDCProxy).balanceOf(ALICE), withdrawAmount);

        vm.stopPrank();
    }

    function testBorrow() public {
        // First set up by depositing collateral
        testDeposit();

        uint256 borrowAmount = 500 * (10 ** usdc.decimals());

        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address variableDebtProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdt))
            .variableDebtTokenAddress;
        address kUSDCProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .kTokenAddress;

        console.log("Alice kUSDC", KToken(kUSDCProxy).balanceOf(ALICE));

        // Enable collateral
        LendingPool(lendingPoolProxy).setUserUseReserveAsCollateral(address(usdc), true);

        // Borrow tokens
        LendingPool(lendingPoolProxy).borrow(address(usdt), borrowAmount, 2, 0, ALICE);

        // Assertions
        assertEq(usdt.balanceOf(ALICE), 10000 * (10 ** usdc.decimals()) + borrowAmount);
        assertEq(VariableDebtToken(variableDebtProxy).balanceOf(ALICE), borrowAmount);

        vm.stopPrank();
    }

    function testRepay() public {
        // First set up by borrowing
        testBorrow(); // borrow 500

        uint256 repayAmount = 200 * (10 ** usdc.decimals());

        vm.startPrank(ALICE);

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address variableDebtProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdt))
            .variableDebtTokenAddress;

        // Approve tokens for repayment
        usdt.approve(address(lendingPoolProxy), repayAmount);

        // Repay tokens
        LendingPool(lendingPoolProxy).repay(address(usdt), repayAmount, 2, ALICE);

        // Assertions
        assertEq(
            VariableDebtToken(variableDebtProxy).balanceOf(ALICE),
            300 * (10 ** usdc.decimals())
        );

        vm.stopPrank();
    }

    function testLiquidation() public {
        uint256 liquidationAmount = 500 * (10 ** usdc.decimals());

        address lendingPoolProxy = addressesProvider.getLendingPool();
        address kUSDCProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdc))
            .kTokenAddress;
        address variableDebtProxy = LendingPool(lendingPoolProxy)
            .getReserveData(address(usdt))
            .variableDebtTokenAddress;

        (, , , , , uint256 healthFactor) = LendingPool(lendingPoolProxy).getUserAccountData(ALICE);
        console.log("Health Factor Before:", healthFactor);

        testBorrow();

        // Change asset price to trigger liquidation
        vm.startPrank(ADMIN);
        address priceOracleProxy = addressesProvider.getPriceOracle();
        MockPriceOracle(priceOracleProxy).setAssetPrice(address(usdc), 0.15e5);
        vm.stopPrank();

        uint256 aliceDebtBefore = VariableDebtToken(variableDebtProxy).balanceOf(ALICE);
        uint256 aliceCollateralBefore = KToken(kUSDCProxy).balanceOf(ALICE);
        uint256 bobBalanceBefore = usdc.balanceOf(BOB);

        (, , , , , uint256 facor) = LendingPool(lendingPoolProxy).getUserAccountData(ALICE);
        console.log("Health Factor:", facor);

        vm.startPrank(BOB);

        // Approve tokens for liquidation
        usdt.approve(address(lendingPoolProxy), liquidationAmount);

        // Liquidate position
        LendingPool(lendingPoolProxy).liquidationCall(
            address(usdc),
            address(usdt),
            ALICE,
            liquidationAmount,
            false
        );

        vm.stopPrank();

        uint256 aliceDebtAfter = VariableDebtToken(variableDebtProxy).balanceOf(ALICE);
        uint256 aliceCollateralAfter = KToken(kUSDCProxy).balanceOf(ALICE);
        uint256 bobBalanceAfter = usdc.balanceOf(BOB);

        assertLt(aliceDebtAfter, aliceDebtBefore, "ALICE's debt should be partially repaid");
        assertLt(
            aliceCollateralAfter,
            aliceCollateralBefore,
            "ALICE's collateral should be seized"
        );
        assertGt(
            bobBalanceAfter,
            bobBalanceBefore,
            "BOB should receive liquidation bonus in collateral"
        );
    }
}
