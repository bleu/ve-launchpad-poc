// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "./helpers/MyToken.sol";
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

    uint256 public immutable YEAR = 365 * 86400;

    WeightedPool internal _weightedPool;

    VyperDeployer internal _vyperDeployer = new VyperDeployer();

    WeightedPoolFactory _weightedPoolFactory;
    MockBasicAuthorizer _authorizer;
    Vault _vault;
    ProtocolFeePercentagesProvider _protocolFeeProvider;

    constructor() {
        _bleu = new MyToken("Bleu token", "BLEU");
        _wETH = new MyToken("Wrapped ETH", "WETH");

        _authorizer = new MockBasicAuthorizer();
        _authorizer.grantRole(0x00, address(this));
        _vault = new Vault(_authorizer, IWETH(0), 0, 0);
        _protocolFeeProvider = new ProtocolFeePercentagesProvider(_vault, 1e18, 1e18);
        _weightedPoolFactory = new WeightedPoolFactory(_vault, _protocolFeeProvider, 0, 0);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(_bleu);
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

        // Add initial liquidity
        _bleu.mint(address(this), 10_000e18);
        _wETH.mint(address(this), 10_000e18);

        _bleu.approve(address(_vault), 10_000e18);
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

contract VeSystemLauncherTest is HelperContract {
    IVeSystemFactory internal _veSystemFactory;
    RewardDistributor internal _rewardDistributorBlueprint;
    IBleuVotingEscrow internal _votingEscrowBlueprint;

    constructor() {
        _votingEscrowBlueprint = IBleuVotingEscrow(_vyperDeployer.deployBlueprint("VotingEscrowBlueprint"));
        _veSystemFactory = IVeSystemFactory(
            _vyperDeployer.deployContract(
                "VeSystemFactory", abi.encode(address(_votingEscrowBlueprint), address(_rewardDistributorBlueprint))
            )
        );
    }

    function testBlueprints() public {
        (address blueprint1, address blueprint2) = _veSystemFactory.getBlueprints();
        assertEq(blueprint1, address(_votingEscrowBlueprint));
    }

    // function testDeploy() public {
    //     _veSystemFactory.deploy(address(_bleu), "Bleu", "BLEU", block.timestamp + YEAR);
    // }
}
