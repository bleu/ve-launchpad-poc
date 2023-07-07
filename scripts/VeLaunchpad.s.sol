// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Script.sol";
import "../utils/DeploymentHelper.sol";

contract VeLaunchpad is Script {
    DeploymentHelper private _deploymentHelper = new DeploymentHelper();

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address votingEscrowAddress = _deploymentHelper.deployVyperBlueprint(
            "VotingEscrowBlueprint"
        );
        address rewardDistributorAddress = _deploymentHelper
            .deploySolidityBlueprint("RewardDistributorBlueprint");

        _deploymentHelper.deployVyperContract("SimpleStoreFactory");

        vm.stopBroadcast();
    }
}
