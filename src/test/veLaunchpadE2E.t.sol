// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../MyToken.sol";
import "../RewardDistributor.sol";
import "../IBleuVotingEscrow.sol";
import "../../lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPoolFactory.sol";
import "../../lib/balancer-v2-monorepo/pkg/vault/contracts/Vault.sol";
import "../../lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/test/MockBasicAuthorizer.sol";
import "../../lib/balancer-v2-monorepo/pkg/standalone-utils/contracts/ProtocolFeePercentagesProvider.sol";
import "../../lib/balancer-v2-monorepo/pkg/interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "../../lib/balancer-v2-monorepo/pkg/pool-utils/contracts/test/MockRateProvider.sol";
import "../../lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-utils/IRateProvider.sol";
import "../../lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPool.sol";


abstract contract HelperContract {
    VyperDeployer vyperDeployer = new VyperDeployer();

    MyToken token;
    MyToken weth;
    RewardDistributor rewardDistributor;

    IBleuVotingEscrow votingEscrow;
    WeightedPoolFactory weightedPoolFactory;
    MockBasicAuthorizer authorizer;
    Vault vault;
    ProtocolFeePercentagesProvider protocolFeeProvider;

    constructor() {
        token = new MyToken("Voting Escrowed Test Token", "veTEST");
        weth = new MyToken("Wrapped ETH", "WETH");

        votingEscrow = IBleuVotingEscrow(
            vyperDeployer.deployContract("VotingEscrow", abi.encode(token, "Voting Escrowed Test Token", "veTEST"))
        );

        rewardDistributor = new RewardDistributor(votingEscrow, 604800);

        authorizer = new MockBasicAuthorizer();
        vault = new Vault(authorizer, IWETH(0), 0, 0);
        protocolFeeProvider = new ProtocolFeePercentagesProvider(vault, 1e18, 1e18);
        weightedPoolFactory = new WeightedPoolFactory(vault, protocolFeeProvider, 0, 0);
    }
}

contract veLaunchPadE2E is Test, HelperContract {
    function testVeToken() public view {
        address val = votingEscrow.token();

        require(val == address(token));
    }

    function testVeTokenName() public view {
        require(
            keccak256(abi.encodePacked(votingEscrow.name()))
                == keccak256(abi.encodePacked("Voting Escrowed Test Token"))
        );
    }

    function testVeTokenSymbol() public view {
        require(keccak256(abi.encodePacked(votingEscrow.symbol())) == keccak256(abi.encodePacked("veTEST")));
    }

    function testVeAdmin() public view {
        address val = votingEscrow.admin();

        require(val == address(vyperDeployer));
    }

    function testCreateLock() public {
        uint256 amount = 1e18;
        uint256 year = 365 * 86400;
        require(votingEscrow.totalSupply() == 0);
        require(token.balanceOf(address(this)) == 0);
        require(token.totalSupply() == 0);
        require(votingEscrow.epoch() == 0);

        token.mint(address(this), amount);
        token.approve(address(votingEscrow), amount);
        require(token.balanceOf(address(this)) == amount);

        votingEscrow.create_lock(amount, block.timestamp + year);
        require(token.balanceOf(address(this)) == 0);
        require(votingEscrow.epoch() == 1);

        require(votingEscrow.totalSupply() > 0);
        require(votingEscrow.totalSupply(block.timestamp + year) == 0);
    }

    function testIncreaseLockAmount() public {
        uint256 amount = 1e18;
        uint256 year = 365 * 86400;
        token.mint(address(this), amount);
        token.approve(address(votingEscrow), amount);
        votingEscrow.create_lock(amount / 2, block.timestamp + year);
        uint256 amountBefore = votingEscrow.totalSupply();
        votingEscrow.increase_amount(amount / 2);
        uint256 amountAfter = votingEscrow.totalSupply();
        require(amountAfter > amountBefore);
    }

    function testFeeDistributor() public {
        uint256 amount = 10e18;
        uint256 year = 365 * 86400;

        require(votingEscrow.totalSupply() == 0);
        require(token.balanceOf(address(this)) == 0);
        require(token.totalSupply() == 0);
        require(votingEscrow.epoch() == 0);

        token.mint(address(this), amount);
        require(token.balanceOf(address(this)) == amount);

        token.approve(address(votingEscrow), 1e18);
        votingEscrow.create_lock(1e18, block.timestamp + year);

        require(token.balanceOf(address(this)) == 9e18);
        require(votingEscrow.epoch() == 1);

        require(votingEscrow.totalSupply() > 0);
        require(votingEscrow.totalSupply(block.timestamp + year) == 0);

        require(rewardDistributor.getVotingEscrow() == votingEscrow);

        vm.warp(604801);

        token.approve(address(rewardDistributor), 2e18);
        rewardDistributor.depositToken(token, 2e18);
        require(rewardDistributor.getTokenLastBalance(token) == 2e18);

        // require(rewardDistributor.getTotalSupplyAtTimestamp(604800) == votingEscrow.totalSupply(604800));
        require(rewardDistributor.getUserTokenTimeCursor(address(this), token) == 604800);

        rewardDistributor.checkpoint();
        rewardDistributor.checkpointUser(address(this));
        rewardDistributor.checkpointToken(token);

        vm.warp(604802);

        require(rewardDistributor.getUserBalanceAtTimestamp(address(this), 604800) == 978082191757238400);
        require(rewardDistributor.getTotalSupplyAtTimestamp(604800) == 978082191757238400);

        vm.warp(604800 * 2);

        rewardDistributor.claimToken(address(this), token);
        require(token.balanceOf(address(this)) == 9e18);
    }

    function testE2E() public {
        // Deploy 2 ERC20 -> BAL, WETH on initialization;
        // Deploy Voting Escrow on initialization;
        // Deploy RewardDistributor on initialization;

        // Declare 2 users;
        address alice = address(1);
        address bob = address(2);

        // Mint 1000 BAL, 1000 WETH;
        token.mint(address(this), 1000e18);
        weth.mint(address(this), 1000e18);

        // Deploy Weighted Pool factory;
        // Deploy 80/20 Pool;

        // Mint 100 BAL to A;
        token.mint(alice, 100e18);
        // User A to join pool with 100 BAL;
        // User A to lock pool BPT in Voting Escrow;

        // Mint 200 BAL to B;
        token.mint(bob, 200e18);
        // User B to join pool with 200 BAL;
        // User B to lock pool BPT in Voting Escrow;

        // Admin deposits 90 BAL in RewardDistributor;
        token.approve(address(rewardDistributor), 90e18);

        vm.warp(604801);
        rewardDistributor.depositToken(token, 90e18);

        // User A claims 30 BAL from RewardDistributor;
        rewardDistributor.claimToken(alice, token);

        // User B claims 60 BAL from RewardDistributor;
        rewardDistributor.claimToken(bob, token);
    }
}
