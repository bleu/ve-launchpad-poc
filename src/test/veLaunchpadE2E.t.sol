// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "./helpers/MyToken.sol";
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
    MyToken _rewardToken;

    uint256 public immutable YEAR = 365 * 86400;

    WeightedPool internal _weightedPool;

    VyperDeployer internal _vyperDeployer = new VyperDeployer();

    RewardDistributor _rewardDistributor;

    IBleuVotingEscrow _votingEscrow;
    WeightedPoolFactory _weightedPoolFactory;
    MockBasicAuthorizer _authorizer;
    Vault _vault;
    ProtocolFeePercentagesProvider _protocolFeeProvider;

    constructor() {
        _poolToken = new MyToken("Voting Escrowed Test Token", "veTEST");
        _wETH = new MyToken("Wrapped ETH", "WETH");
        _rewardToken = new MyToken("Reward Token", "REWARD");

        _authorizer = new MockBasicAuthorizer();
        _authorizer.grantRole(0x00, address(this));
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

        _votingEscrow = IBleuVotingEscrow(
            _vyperDeployer.deployContract(
                "VotingEscrow", abi.encode(_weightedPool, "Voting Escrowed Test Token", "vePOOL")
            )
        );

        _rewardDistributor = new RewardDistributor(_votingEscrow, 604800);

        assertEq(keccak256(abi.encodePacked(_weightedPool.name())), keccak256(abi.encodePacked("Test Pool")));
        assertEq(keccak256(abi.encodePacked(_weightedPool.symbol())), keccak256(abi.encodePacked("TEST")));
        assertEq(_weightedPool.getOwner(), address(this));
        assertEq(_weightedPool.totalSupply(), 0);

        // Add initial liquidity
        _poolToken.mint(address(this), 10_000e18);
        _wETH.mint(address(this), 10_000e18);

        _poolToken.approve(address(_vault), 10_000e18);
        _wETH.approve(address(_vault), 10_000e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2000e18;
        amounts[1] = 8000e18;

        bytes32 poolId = _weightedPool.getPoolId();
        (IERC20[] memory poolTokens,,) = _vault.getPoolTokens(poolId);

        joinPoolHelper(
            address(this), poolTokens, amounts, abi.encode(WeightedPoolUserData.JoinKind.INIT, amounts, 1e18)
        );
    }

    function joinPoolHelper(address to, IERC20[] memory tokens, uint256[] memory amounts, bytes memory userData)
        public
    {
        _vault.joinPool(
            _weightedPool.getPoolId(),
            address(this),
            to,
            IVault.JoinPoolRequest({
                assets: _asIAsset(tokens),
                maxAmountsIn: amounts,
                userData: userData,
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
        uint256 YEAR = 365 * 86400;
        assertEq(_votingEscrow.totalSupply(), 0);
        assertEq(_poolToken.balanceOf(address(this)), 0);
        assertEq(_poolToken.totalSupply(), 0);
        assertEq(_votingEscrow.epoch(), 0);

        _poolToken.mint(address(this), amount);
        _poolToken.approve(address(_votingEscrow), amount);
        assertEq(_poolToken.balanceOf(address(this)), amount);

        _votingEscrow.create_lock(amount, block.timestamp + YEAR);
        assertEq(_poolToken.balanceOf(address(this)), 0);
        assertEq(_votingEscrow.epoch(), 1);

        assertGt(_votingEscrow.totalSupply(), 0);
        assertEq(_votingEscrow.totalSupply(block.timestamp + YEAR), 0);
    }

    function testIncreaseLockAmount() public {
        uint256 amount = 1e18;
        uint256 YEAR = 365 * 86400;
        _poolToken.mint(address(this), amount);
        _poolToken.approve(address(_votingEscrow), amount);
        _votingEscrow.create_lock(amount / 2, block.timestamp + YEAR);
        uint256 amountBefore = _votingEscrow.totalSupply();
        _votingEscrow.increase_amount(amount / 2);
        uint256 amountAfter = _votingEscrow.totalSupply();
        assertGt(amountAfter, amountBefore);
    }

    function testFeeDistributor() public {
        uint256 amount = 10e18;
        uint256 YEAR = 365 * 86400;

        assertEq(_votingEscrow.totalSupply(), 0);
        assertEq(_poolToken.balanceOf(address(this)), 0);
        assertEq(_poolToken.totalSupply(), 0);
        assertEq(_votingEscrow.epoch(), 0);

        _poolToken.mint(address(this), amount);
        assertEq(_poolToken.balanceOf(address(this)), amount);

        _poolToken.approve(address(_votingEscrow), 1e18);
        _votingEscrow.create_lock(1e18, block.timestamp + YEAR);

        assertEq(_poolToken.balanceOf(address(this)), 9e18);
        assertEq(_votingEscrow.epoch(), 1);

        assertGt(_votingEscrow.totalSupply(), 0);
        assertEq(_votingEscrow.totalSupply(block.timestamp + YEAR), 0);

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
        // Deploy 2 ERC20 -> RewardToken, WETH;
        // Deploy Voting Escrow;
        // Deploy RewardDistributor;
        // Mint 1000 RewardToken, 1000 WETH;
        // Deploy Weighted Pool factory;
        // Deploy 80/20 Pool;

        // Declare 2 users;
        address alice = address(1);
        address bob = address(2);

        // Mint 100 RewardToken to A;
        // _poolToken.mint(alice, 100e18);
        // _poolToken.approve(address(_vault), 100e18);

        IERC20[] memory toDepositTokens = new IERC20[](2);
        toDepositTokens[0] = _poolToken;
        toDepositTokens[1] = _wETH;

        uint256[] memory aliceAmounts = new uint256[](2);
        aliceAmounts[0] = 100e18;
        aliceAmounts[1] = 400e18;

        joinPoolHelper(
            alice,
            toDepositTokens,
            aliceAmounts,
            abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, aliceAmounts, 1e18)
        );

        uint256 aliceBPTAmount = _weightedPool.balanceOf(address(alice));

        vm.startPrank(alice);
        _weightedPool.approve(address(_votingEscrow), aliceBPTAmount);
        _votingEscrow.create_lock(aliceBPTAmount, block.timestamp + YEAR);
        vm.stopPrank();

        assertEq(_votingEscrow.balanceOf(address(alice)), _votingEscrow.totalSupply());

        uint256[] memory bobAmounts = new uint256[](2);
        bobAmounts[0] = 200e18;
        bobAmounts[1] = 800e18;

        joinPoolHelper(
            bob,
            toDepositTokens,
            bobAmounts,
            abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, bobAmounts, 1e18)
        );

        uint256 bobBPTAmount = _weightedPool.balanceOf(address(bob));

        vm.startPrank(bob);
        _weightedPool.approve(address(_votingEscrow), bobBPTAmount);
        _votingEscrow.create_lock(bobBPTAmount, block.timestamp + YEAR);
        vm.stopPrank();

        // // Admin deposits 90 RewardToken in RewardDistributor;
        vm.warp(604801);

        _rewardToken.mint(address(this), 90e18);
        _rewardToken.approve(address(_rewardDistributor), 90e18);
        _rewardDistributor.depositToken(_rewardToken, 90e18);

        _rewardDistributor.checkpoint();

        vm.warp(604800 * 2);

        // User A claims 30 RewardToken from RewardDistributor;
        _rewardDistributor.claimToken(alice, _rewardToken);

        // User B claims 60 RewardToken from RewardDistributor;
        _rewardDistributor.claimToken(bob, _rewardToken);

        uint256 aliceRewardBalance = _rewardToken.balanceOf(address(alice));
        uint256 bobRewardBalance = _rewardToken.balanceOf(address(bob));

        assertApproxEqRel(aliceRewardBalance, 30e18, 1e6);
        assertApproxEqRel(bobRewardBalance, 60e18, 1e6);

        assertApproxEqRel(aliceRewardBalance + bobRewardBalance, 90e18, 1e6);
    }
}
