// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";

import "./helpers/MyToken.sol";
import "../../utils/VyperDeployer.sol";
import "../RewardDistributor.sol";
import "../IBleuVotingEscrow.sol";
import "../IVeSystemFactory.sol";

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
import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/liquidity-mining/IVotingEscrow.sol";

abstract contract HelperContract is Test {
    MyToken _bleu;
    MyToken _wETH;

    uint256 public YEAR = 365 * 86400;
    uint256 public WEEK = 7 * 86400;

    WeightedPool internal _weightedPool;

    VyperDeployer internal _vyperDeployer = new VyperDeployer();

    WeightedPoolFactory public _weightedPoolFactory = WeightedPoolFactory(0x7920BFa1b2041911b354747CA7A6cDD2dfC50Cfd);
    // IAuthorizer public _authorizer = IAuthorizer(0xA331D84eC860Bf466b4CdCcFb4aC09a1B43F3aE6);
    IVault public _vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    // IProtocolFeePercentagesProvider public _protocolFeeProvider = IProtocolFeePercentagesProvider(0xf7D5DcE55E6D47852F054697BAB6A1B48A00ddbd);

    IERC20[] _poolTokens;

    constructor() {
        _bleu = new MyToken("Bleu token", "BLEU");
        _wETH = new MyToken("Wrapped ETH", "WETH");

        // _authorizer = new MockBasicAuthorizer();
        // _authorizer.grantRole(0x00, address(this));
        // _vault = new Vault(_authorizer, IWETH(0), 0, 0);
        // _protocolFeeProvider = new ProtocolFeePercentagesProvider(_vault, 1e18, 1e18);
        // _weightedPoolFactory = new WeightedPoolFactory(_vault, _protocolFeeProvider, 0, 0);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(_bleu);
        tokens[1] = IERC20(_wETH);
        _poolTokens = tokens;

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

        // Add initial liquidity
        _bleu.mint(address(this), 10_000e18);
        _wETH.mint(address(this), 10_000e18);

        _bleu.approve(address(_vault), 10_000e18);
        _wETH.approve(address(_vault), 10_000e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2000e18;
        amounts[1] = 8000e18;

        bytes32 poolId = _weightedPool.getPoolId();

        joinPoolHelper(
            address(this), amounts, abi.encode(WeightedPoolUserData.JoinKind.INIT, amounts, 1e18)
        );
    }

    function joinPoolHelper(address to, uint256[] memory amounts, bytes memory userData)
        public
    {
        _vault.joinPool(
            _weightedPool.getPoolId(),
            address(this),
            to,
            IVault.JoinPoolRequest({
                assets: _asIAsset(_poolTokens),
                maxAmountsIn: amounts,
                userData: userData,
                fromInternalBalance: false
            })
        );
    }
}

contract VeSystemLauncherSepoliaTest is HelperContract {
    IVeSystemFactory internal _veSystemFactory;
    IBleuVotingEscrow internal _votingEscrowBlueprint;
    IBleuVotingEscrow internal _veBleu;
    IRewardDistributor internal _rewardDistributorBlueprint;
    IRewardDistributor internal _rewardDistributorBleu;

    constructor() {
        _votingEscrowBlueprint = IBleuVotingEscrow(
            _vyperDeployer.deployBlueprint(
                "VotingEscrowBlueprint"
            )
        );
        _rewardDistributorBlueprint = IRewardDistributor(
            _vyperDeployer.deploySolidityBlueprint(
                "RewardDistributor.sol:RewardDistributor"
            )
        );
        _veSystemFactory = IVeSystemFactory(
            _vyperDeployer.deployContract(
                "VeSystemFactory",
                abi.encode(
                    address(_votingEscrowBlueprint),
                    address(_rewardDistributorBlueprint)
                )
            )
        );

        (address _veBleuAddress, address _veBleuRewardAddress) = _veSystemFactory.deploy(
            address(_weightedPool),
            "Bleu",
            "BLEU",
            WEEK
        );
        _veBleu = IBleuVotingEscrow(_veBleuAddress);
        _rewardDistributorBleu = IRewardDistributor(_veBleuRewardAddress);
    }

    function testBlueprints() public {
        assertEq(_veSystemFactory.votingEscrowBlueprint(), address(_votingEscrowBlueprint));
        assertEq(_veSystemFactory.rewardDistributorBlueprint(), address(_rewardDistributorBlueprint));
    }

    function testVotingEscrow() public {
        assert(_veSystemFactory.votingEscrowRegister(address(_veBleu)));
        assertEq(_veBleu.token(), address(_weightedPool));
        assertEq(_veBleu.admin(), address(this));

        assertEq(_veBleu.totalSupply(), 0);
        uint256 _BPTBeforeLock = _weightedPool.balanceOf(address(this));

        _weightedPool.approve(address(_veBleu), _BPTBeforeLock);
        _veBleu.create_lock(_BPTBeforeLock, block.timestamp + YEAR);

        assertEq(_weightedPool.balanceOf(address(this)), 0);
        assertGt(_veBleu.totalSupply(), 0);
        assertEq(_veBleu.totalSupply(block.timestamp + YEAR), 0);
        _veBleu.checkpoint();

        assertGt(_veBleu.balanceOf(address(this)), 0);
    }

    function testRewardDistribution() public {
        address alice = address(1);
        address bob = address(2);

        // Alice joins on the pool
        uint256[] memory aliceAmounts = new uint256[](2);
        aliceAmounts[0] = 100e18;
        aliceAmounts[1] = 400e18;
        joinPoolHelper(
            alice,
            aliceAmounts,
            abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, aliceAmounts, 1e18)
        );

        // Alice locks BPT into the voting escrow
        uint256 aliceBPTAmount = _weightedPool.balanceOf(address(alice));
        vm.startPrank(alice);
        _weightedPool.approve(address(_veBleu), aliceBPTAmount);
        _veBleu.create_lock(aliceBPTAmount, block.timestamp + YEAR);
        vm.stopPrank();

        // Bob joins on the pool
        uint256[] memory bobAmounts = new uint256[](2);
        bobAmounts[0] = aliceAmounts[0]*2;
        bobAmounts[1] = aliceAmounts[1]*2;
        joinPoolHelper(
            bob,
            bobAmounts,
            abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, bobAmounts, 1e18)
        );

        // Bob locks BPT into the voting escrow
        uint256 bobBPTAmount = _weightedPool.balanceOf(address(bob));
        vm.startPrank(bob);
        _weightedPool.approve(address(_veBleu), bobBPTAmount);
        _veBleu.create_lock(bobBPTAmount, block.timestamp + YEAR);
        vm.stopPrank();

        // One week later, admin deposits 90 RewardToken in RewardDistributor;
        vm.warp(WEEK + 1);
        _bleu.approve(address(_rewardDistributorBleu), 90e18);
        _rewardDistributorBleu.depositToken(_bleu, 90e18);
        _rewardDistributorBleu.checkpoint();

        vm.warp(WEEK * 2);

        // Two weeks later, bob and alice claims tokens;
        _rewardDistributorBleu.claimToken(alice, _bleu);
        _rewardDistributorBleu.claimToken(bob, _bleu);

        // Check that alice and bob have the correct amount of tokens
        assertApproxEqRel(_bleu.balanceOf(address(alice)), 30e18, 1e6);
        assertApproxEqRel(_bleu.balanceOf(address(bob)), 60e18, 1e6);
        assertApproxEqRel(
            _bleu.balanceOf(address(alice)) + _bleu.balanceOf(address(bob)),
            90e18,
            1e6
        );
    }
}
