// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Script.sol";
import "../utils/DeploymentHelper.sol";

contract Deploy is Script {
    function run() external {
        DeploymentHelper DeploymentHelper = new DeploymentHelper();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        DeploymentHelper.deployContract("SimpleStore", abi.encode(1234));

        DeploymentHelper.deployBlueprint("ExampleBlueprint");

        DeploymentHelper.deployContract("SimpleStoreFactory");

        vm.stopBroadcast();
    }
}
