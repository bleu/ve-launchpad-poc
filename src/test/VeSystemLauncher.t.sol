// // SPDX-License-Identifier: MIT
// pragma solidity ^0.7.6;
// pragma abicoder v2;

// import "forge-std/Test.sol";

// import "../../utils/VyperDeployer.sol";

// import "../MyToken.sol";
// import "../RewardDistributor.sol";
// import "../IBleuVotingEscrow.sol";
// import "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPoolFactory.sol";
// import "lib/balancer-v2-monorepo/pkg/vault/contracts/Vault.sol";
// import "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/test/MockBasicAuthorizer.sol";
// import "lib/balancer-v2-monorepo/pkg/standalone-utils/contracts/ProtocolFeePercentagesProvider.sol";
// import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
// import "lib/balancer-v2-monorepo/pkg/pool-utils/contracts/test/MockRateProvider.sol";
// import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-utils/IRateProvider.sol";
// import "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPool.sol";
// import "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/helpers/ERC20Helpers.sol";
// import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";
// import "lib/balancer-v2-monorepo/pkg/interfaces/contracts/liquidity-mining/IVotingEscrow.sol";

// import "../MyToken.sol";
// import "../RewardDistributor.sol";
// import "../VeSystemFactory.sol";

// abstract contract HelperContract is Test {
//     MyToken internal _poolToken = new MyToken("Voting Escrowed Test Token", "veTEST");
//     MyToken internal _wETH = new MyToken("Wrapped ETH", "WETH");

//     WeightedPool internal _weightedPool;

//     VyperDeployer internal _vyperDeployer = new VyperDeployer();

//     IVault internal _vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

//     IWeightedPoolFactory internal _weightedPoolFactory =
//         IWeightedPoolFactory(0x5Dd94Da3644DDD055fcf6B3E1aa310Bb7801EB8b);

//     constructor() {
//         IERC20[] memory tokens = new IERC20[](2);
//         tokens[0] = IERC20(_veToken);
//         tokens[1] = IERC20(_wETH);

//         uint256[] memory weights = new uint256[](2);
//         weights[0] = 20e16;
//         weights[1] = 80e16;

//         IRateProvider[] memory rateProviders = new IRateProvider[](2);
//         rateProviders[0] = new MockRateProvider();
//         rateProviders[1] = new MockRateProvider();

//         bytes32 salt = bytes32(0);
//         address weightedPoolAddress =
//             _weightedPoolFactory.create("Test Pool", "TEST", tokens, weights, rateProviders, 1e12, address(this), salt);

//         _weightedPool = WeightedPool(weightedPoolAddress);

//         assertEq(keccak256(abi.encodePacked(_weightedPool.name())), keccak256(abi.encodePacked("Test Pool")));
//         assertEq(keccak256(abi.encodePacked(_weightedPool.symbol())), keccak256(abi.encodePacked("TEST")));
//         assertEq(_weightedPool.getOwner(), address(this));
//         assertEq(_weightedPool.totalSupply(), 0);

//         // Add initial liquidity
//         _veToken.mint(address(this), 1000e18);
//         _wETH.mint(address(this), 1000e18);

//         _veToken.approve(address(_weightedPool), 1000e18);
//         _wETH.approve(address(_weightedPool), 1000e18);

//         uint256[] memory amounts = new uint256[](2);
//         amounts[0] = 1000e18;
//         amounts[1] = 1000e18;

//         bytes32 poolId = _weightedPool.getPoolId();
//         (IERC20[] memory poolTokens,,) = _vault.getPoolTokens(poolId);

//         _vault.joinPool(
//             _weightedPool.getPoolId(),
//             address(this),
//             address(this),
//             IVault.JoinPoolRequest({
//                 assets: _asIAsset(poolTokens),
//                 maxAmountsIn: amounts,
//                 userData: abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amounts, 1e18),
//                 fromInternalBalance: false
//             })
//         );
//     }
// }

// contract VeSystemLauncherTest is HelperContract {
//     VeSystemFactory internal _veSystemFactory;

//     constructor() {
//         // abi.encode(_veToken, "Voting Escrowed Test Token", "veTEST"), 604800

//         _veSystemFactory = new VeSystemFactory();
//     }

//     function testGetOwner() public {
//         assertEq(_veSystemFactory.owner(), address(this));
//     }
// }
