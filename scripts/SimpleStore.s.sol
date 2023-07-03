// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Script.sol";
import "../utils/VyperDeployer.sol";

contract Deploy is Script {
    function run() external {
        VyperDeployer vyperDeployer = new VyperDeployer();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        vyperDeployer.deployContract("SimpleStore", abi.encode(1234));

        vyperDeployer.deployBlueprint("ExampleBlueprint");

        vyperDeployer.deployContract("SimpleStoreFactory");

        vm.stopBroadcast();
    }
}
