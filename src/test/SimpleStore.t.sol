// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../../src/ISimpleStore.sol";

contract SimpleStoreTest is Test {
    VyperDeployer vyperDeployer = new VyperDeployer();

    ISimpleStore simpleStore;
    ISimpleStore simpleStoreBlueprint;
    ISimpleStoreFactory simpleStoreFactory;

    function setUp() public {
        simpleStore = ISimpleStore(vyperDeployer.deployContract("SimpleStore", abi.encode(1234)));

        simpleStoreBlueprint = ISimpleStore(vyperDeployer.deployBlueprint("ExampleBlueprint"));

        simpleStoreFactory = ISimpleStoreFactory(vyperDeployer.deployContract("SimpleStoreFactory"));
    }

    function testGet() public {
        uint256 val = simpleStore.get();

        require(val == 1234);
    }

    function testStore(uint256 _val) public {
        simpleStore.store(_val);
        uint256 val = simpleStore.get();

        require(_val == val);
    }

    function testFactory() public {
        address deployedAddress = simpleStoreFactory.deploy(address(simpleStoreBlueprint), 1354);

        ISimpleStore deployedSimpleStore = ISimpleStore(deployedAddress);

        uint256 val = deployedSimpleStore.get();

        require(val == 1354);

        deployedSimpleStore.store(1234);

        val = deployedSimpleStore.get();

        require(val == 1234);
    }
}
