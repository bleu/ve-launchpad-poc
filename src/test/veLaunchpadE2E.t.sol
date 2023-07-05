// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../MyToken.sol";
import "../RewardDistributor.sol";
import "../IBleuVotingEscrow.sol";
import "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPoolFactory.sol";
import "lib/balancer-v2-monorepo/pkg/vault/contracts/Vault.sol";
import "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/test/MockBasicAuthorizer.sol";
import "lib/balancer-v2-monorepo/pkg/standalone-utils/contracts/ProtocolFeePercentagesProvider.sol";
import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "lib/balancer-v2-monorepo/pkg/pool-utils/contracts/test/MockRateProvider.sol";
import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-utils/IRateProvider.sol";
import "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPool.sol";
import "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/helpers/ERC20Helpers.sol";
import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";

abstract contract HelperContract is Test {
    MyToken _poolToken;
    MyToken _wETH;

    WeightedPool internal _weightedPool;

    VyperDeployer internal _vyperDeployer = new VyperDeployer();

    // IVault internal _vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    // IWeightedPoolFactory internal _weightedPoolFactory =
    //     IWeightedPoolFactory(0x5Dd94Da3644DDD055fcf6B3E1aa310Bb7801EB8b);

    RewardDistributor _rewardDistributor;

    IBleuVotingEscrow _votingEscrow;
    WeightedPoolFactory _weightedPoolFactory;
    MockBasicAuthorizer _authorizer;
    Vault _vault;
    ProtocolFeePercentagesProvider _protocolFeeProvider;

    constructor() {
        _poolToken = new MyToken("Voting Escrowed Test Token", "veTEST");
        _wETH = new MyToken("Wrapped ETH", "WETH");

        _votingEscrow = IBleuVotingEscrow(
            _vyperDeployer.deployContract(
                "VotingEscrow", abi.encode(_poolToken, "Voting Escrowed Test Token", "veTEST")
            )
        );

        _rewardDistributor = new RewardDistributor(_votingEscrow, 604800);
        _authorizer = new MockBasicAuthorizer();
        _vault = new Vault(_authorizer, IWETH(0), 0, 0);
        _protocolFeeProvider = new ProtocolFeePercentagesProvider(_vault, 1e18, 1e18);
        _weightedPoolFactory = new WeightedPoolFactory(_vault, _protocolFeeProvider, 0, 0);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(_poolToken);
        tokens[1] = IERC20(_wETH);

        uint256[] memory weights = new uint256[](2);
        weights[0] = 20e16;
        weights[1] = 80e16;

        IRateProvider[] memory rateProviders = new IRateProvider[](2);
        rateProviders[0] = new MockRateProvider();
        rateProviders[1] = new MockRateProvider();

        bytes32 salt = bytes32(0);
        address weightedPoolAddress =
            _weightedPoolFactory.create("Test Pool", "TEST", tokens, weights, rateProviders, 1e12, address(this), salt);

        _weightedPool = WeightedPool(weightedPoolAddress);

        assertEq(keccak256(abi.encodePacked(_weightedPool.name())), keccak256(abi.encodePacked("Test Pool")));
        assertEq(keccak256(abi.encodePacked(_weightedPool.symbol())), keccak256(abi.encodePacked("TEST")));
        assertEq(_weightedPool.getOwner(), address(this));
        assertEq(_weightedPool.totalSupply(), 0);

        // Add initial liquidity
        _poolToken.mint(address(this), 1000e18);
        _wETH.mint(address(this), 1000e18);

        _poolToken.approve(address(_vault), 1000e18);
        _wETH.approve(address(_vault), 1000e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000e18;
        amounts[1] = 1000e18;

        bytes32 poolId = _weightedPool.getPoolId();
        (IERC20[] memory poolTokens,,) = _vault.getPoolTokens(poolId);

        _vault.joinPool(
            _weightedPool.getPoolId(),
            address(this),
            address(this),
            IVault.JoinPoolRequest({
                assets: _asIAsset(poolTokens),
                maxAmountsIn: amounts,
                userData: abi.encode(WeightedPoolUserData.JoinKind.INIT, amounts, 1e18),
                fromInternalBalance: false
            })
        );
    }
}

contract veLaunchPadE2E is Test, HelperContract {
    function testVeToken() public {
        address val = _votingEscrow.token();

        assertEq(val, address(_poolToken));
    }

    function testVeTokenName() public {
        assertEq(
            keccak256(abi.encodePacked(_votingEscrow.name())), keccak256(abi.encodePacked("Voting Escrowed Test Token"))
        );
    }

    function testVeTokenSymbol() public {
        assertEq(keccak256(abi.encodePacked(_votingEscrow.symbol())), keccak256(abi.encodePacked("veTEST")));
    }

    function testVeAdmin() public {
        address val = _votingEscrow.admin();

        assertEq(val, address(_vyperDeployer));
    }

    function testCreateLock() public {
        uint256 amount = 1e18;
        uint256 year = 365 * 86400;
        assertEq(_votingEscrow.totalSupply(), 0);
        assertEq(_poolToken.balanceOf(address(this)), 0);
        assertEq(_poolToken.totalSupply(), 0);
        assertEq(_votingEscrow.epoch(), 0);

        _poolToken.mint(address(this), amount);
        _poolToken.approve(address(_votingEscrow), amount);
        assertEq(_poolToken.balanceOf(address(this)), amount);

        _votingEscrow.create_lock(amount, block.timestamp + year);
        assertEq(_poolToken.balanceOf(address(this)), 0);
        assertEq(_votingEscrow.epoch(), 1);

        assertGt(_votingEscrow.totalSupply(), 0);
        assertEq(_votingEscrow.totalSupply(block.timestamp + year), 0);
    }

    function testIncreaseLockAmount() public {
        uint256 amount = 1e18;
        uint256 year = 365 * 86400;
        _poolToken.mint(address(this), amount);
        _poolToken.approve(address(_votingEscrow), amount);
        _votingEscrow.create_lock(amount / 2, block.timestamp + year);
        uint256 amountBefore = _votingEscrow.totalSupply();
        _votingEscrow.increase_amount(amount / 2);
        uint256 amountAfter = _votingEscrow.totalSupply();
        assertGt(amountAfter, amountBefore);
    }

    function testFeeDistributor() public {
        uint256 amount = 10e18;
        uint256 year = 365 * 86400;

        assertEq(_votingEscrow.totalSupply(), 0);
        assertEq(_poolToken.balanceOf(address(this)), 0);
        assertEq(_poolToken.totalSupply(), 0);
        assertEq(_votingEscrow.epoch(), 0);

        _poolToken.mint(address(this), amount);
        assertEq(_poolToken.balanceOf(address(this)), amount);

        _poolToken.approve(address(_votingEscrow), 1e18);
        _votingEscrow.create_lock(1e18, block.timestamp + year);

        assertEq(_poolToken.balanceOf(address(this)), 9e18);
        assertEq(_votingEscrow.epoch(), 1);

        assertGt(_votingEscrow.totalSupply(), 0);
        assertEq(_votingEscrow.totalSupply(block.timestamp + year), 0);

        // assertEq(_rewardDistributor.getVotingEscrow(), _votingEscrow);

        vm.warp(604801);

        _poolToken.approve(address(_rewardDistributor), 2e18);
        _rewardDistributor.depositToken(_poolToken, 2e18);
        assertEq(_rewardDistributor.getTokenLastBalance(_poolToken), 2e18);

        // assertEq(_rewardDistributor.getTotalSupplyAtTimestamp(604800), _votingEscrow.totalSupply(604800));
        assertEq(_rewardDistributor.getUserTokenTimeCursor(address(this), _poolToken), 604800);

        _rewardDistributor.checkpoint();
        _rewardDistributor.checkpointUser(address(this));
        _rewardDistributor.checkpointToken(_poolToken);

        vm.warp(604802);

        assertEq(_rewardDistributor.getUserBalanceAtTimestamp(address(this), 604800), 978082191757238400);
        assertEq(_rewardDistributor.getTotalSupplyAtTimestamp(604800), 978082191757238400);

        vm.warp(604800 * 2);

        _rewardDistributor.claimToken(address(this), _poolToken);
        assertEq(_poolToken.balanceOf(address(this)), 9e18);
    }

    function testE2E() public {
        // On Helper Contract initialization:
        // Deploy 2 ERC20 -> BAL, WETH;
        // Deploy Voting Escrow;
        // Deploy RewardDistributor;
        // Mint 1000 BAL, 1000 WETH;
        // Deploy Weighted Pool factory;
        // Deploy 80/20 Pool;

        // Declare 2 users;
        address alice = address(1);
        address bob = address(2);

        // Mint 100 BAL to A;
        _poolToken.mint(alice, 100e18);
        // User A to join pool with 100 BAL;
        // User A to lock pool BPT in Voting Escrow;

        // Mint 200 BAL to B;
        _poolToken.mint(bob, 200e18);
        // User B to join pool with 200 BAL;
        // User B to lock pool BPT in Voting Escrow;

        // Admin deposits 90 BAL in RewardDistributor;
        _poolToken.approve(address(_rewardDistributor), 90e18);

        vm.warp(604801);
        _rewardDistributor.depositToken(_poolToken, 90e18);

        // User A claims 30 BAL from RewardDistributor;
        _rewardDistributor.claimToken(alice, _poolToken);

        // User B claims 60 BAL from RewardDistributor;
        _rewardDistributor.claimToken(bob, _poolToken);
    }
}
