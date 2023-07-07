// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";

import "./MyToken.sol";

import {DeploymentHelper} from "../../../utils/DeploymentHelper.sol";
import {RewardDistributor} from "../../RewardDistributor.sol";
import {IBleuVotingEscrow} from "../../IBleuVotingEscrow.sol";
import {IVeSystemFactory} from "../../IVeSystemFactory.sol";

import {
    WeightedPoolFactory
} from "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPoolFactory.sol";
import {
    IVault,
    Vault,
    IWETH
} from "lib/balancer-v2-monorepo/pkg/vault/contracts/Vault.sol";
import {
    MockBasicAuthorizer
} from "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/test/MockBasicAuthorizer.sol";
import {
    ProtocolFeePercentagesProvider
} from "lib/balancer-v2-monorepo/pkg/standalone-utils/contracts/ProtocolFeePercentagesProvider.sol";
import {
    IERC20
} from "lib/balancer-v2-monorepo/pkg/interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import {
    MockRateProvider
} from "lib/balancer-v2-monorepo/pkg/pool-utils/contracts/test/MockRateProvider.sol";
import {
    IRateProvider
} from "lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-utils/IRateProvider.sol";
import {
    WeightedPool
} from "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPool.sol";
import {
    _asIAsset
} from "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/helpers/ERC20Helpers.sol";
import {
    WeightedPoolUserData
} from "lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";
import {
    IVotingEscrow
} from "lib/balancer-v2-monorepo/pkg/interfaces/contracts/liquidity-mining/IVotingEscrow.sol";

abstract contract TestTokensHelper is Test {
    MyToken internal _bleu;
    MyToken internal _wETH;

    constructor() {
        _bleu = new MyToken("Bleu token", "BLEU");
        _wETH = new MyToken("Wrapped ETH", "WETH");
    }
}

abstract contract ContractDeploymentHelper {
    DeploymentHelper internal _deploymentHelper = new DeploymentHelper();
}

abstract contract BalancerDeploymentEnvironment {
    IVault internal _vault;

    MockBasicAuthorizer internal _authorizer;
    ProtocolFeePercentagesProvider internal _protocolFeeProvider;

    WeightedPoolFactory internal _weightedPoolFactory;
}

abstract contract VaultPoolHelper {
    function joinPoolHelper(
        IVault _vault,
        WeightedPool pool,
        IERC20[] memory poolTokens,
        address to,
        uint256[] memory amounts,
        bytes memory userData
    ) public {
        _vault.joinPool(
            pool.getPoolId(),
            address(this),
            to,
            IVault.JoinPoolRequest({
                assets: _asIAsset(poolTokens),
                maxAmountsIn: amounts,
                userData: userData,
                fromInternalBalance: false
            })
        );
    }
}

contract LocalBalancerDeploymentEnvironment is BalancerDeploymentEnvironment {
    constructor() {
        _authorizer = new MockBasicAuthorizer();
        _authorizer.grantRole(0x00, address(this));
        _vault = new Vault(_authorizer, IWETH(0), 0, 0);
        _protocolFeeProvider = new ProtocolFeePercentagesProvider(
            _vault,
            1e18,
            1e18
        );
        _weightedPoolFactory = new WeightedPoolFactory(
            _vault,
            _protocolFeeProvider,
            0,
            0
        );
    }
}

abstract contract WeightedPoolCreatorHelper is
    TestTokensHelper,
    VaultPoolHelper,
    BalancerDeploymentEnvironment
{
    uint256 public constant YEAR = 365 * 86400;
    uint256 public constant WEEK = 7 * 86400;

    WeightedPool internal _weightedPool;
    IERC20[] internal _poolTokens;

    constructor() {
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
        address weightedPoolAddress = _weightedPoolFactory.create(
            "Test Pool",
            "TEST",
            tokens,
            weights,
            rateProviders,
            1e12,
            address(this),
            salt
        );

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
            _vault,
            _weightedPool,
            _poolTokens,
            address(this),
            amounts,
            abi.encode(WeightedPoolUserData.JoinKind.INIT, amounts, 1e18)
        );
    }
}
