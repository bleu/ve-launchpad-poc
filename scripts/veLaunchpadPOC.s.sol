// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Script.sol";
import "../utils/DeploymentHelper.sol";
import "../src/IVotingEscrow.sol";
import "../test/helpers/MyToken.sol";

contract Deploy is Script {
    MyToken token;

    IVotingEscrow votingEscrow;

    function run() external {
        DeploymentHelper DeploymentHelper = new DeploymentHelper();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        token = new MyToken("Voting Escrowed Test Token", "veTEST");

        votingEscrow = IVotingEscrow(
            DeploymentHelper.deployContract(
                "VotingEscrowBlueprint",
                abi.encode(token, "Voting Escrowed Test Token", "veTEST")
            )
        );

        vm.stopBroadcast();
    }
}
