// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IVotingEscrow.sol";
import "../MyToken.sol";
import "../RewardDistributor.sol";
import "../VeSystemFactory.sol";

contract VeSystemLauncherTest is Test {
    VeSystemFactory _veSystemFactory;

    constructor() {
        // abi.encode(token, "Voting Escrowed Test Token", "veTEST"), 604800

        _veSystemFactory = new VeSystemFactory();
    }

    function testGetOwner() public {
        assertEq(_veSystemFactory.owner(), address(this));
    }
}
