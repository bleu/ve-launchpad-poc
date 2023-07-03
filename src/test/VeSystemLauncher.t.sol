// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../IVotingEscrow.sol";
import "../MyToken.sol";
import "../FeeDistributor.sol";
import "../VeSystemFactory.sol";

contract VeSystemLauncherTest is Test {
    VeSystemFactory _veSystemFactory;

    constructor() {
        // abi.encode(token, "Voting Escrowed Test Token", "veTEST"), 604800

        _veSystemFactory = new VeSystemFactory();
    }

    function testGetOwner() public view {
        assertEq(_veSystemFactory.owner, address(this));
    }
}
