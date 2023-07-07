// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test} from "forge-std/Test.sol";
import {StdCheatsSafe} from "forge-std/StdCheats.sol";

import {
    IVault,
    Vault
} from "lib/balancer-v2-monorepo/pkg/vault/contracts/Vault.sol";
import {
    WeightedPoolFactory
} from "lib/balancer-v2-monorepo/pkg/pool-weighted/contracts/WeightedPoolFactory.sol";

import {
    BalancerDeploymentEnvironment
} from "./helpers/E2EHelpers.sol";
import {
    VeLaunchpadTest
} from "./VeLaunchpad.t.sol";

contract SepoliaBalancerDeploymentEnvironment is BalancerDeploymentEnvironment {
    constructor() {
        _vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        _weightedPoolFactory = WeightedPoolFactory(
            0x7920BFa1b2041911b354747CA7A6cDD2dfC50Cfd
        );
    }
}

contract VeLaunchpadSepoliaTest is StdCheatsSafe, SepoliaBalancerDeploymentEnvironment, VeLaunchpadTest {
    constructor() {
        vm.createFork(stdChains.sepolia.rpcUrl);
    }

    // function setUp() public {
    //     mainnetFork = vm.createFork(MAINNET_RPC_URL);
    //     optimismFork = vm.createFork(OPTIMISM_RPC_URL);
    // }
}
