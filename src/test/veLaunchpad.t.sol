// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../../src/IVotingEscrow.sol";

contract SimpleStoreTest is Test {
    ///@notice create a new instance of VyperDeployer
    VyperDeployer vyperDeployer = new VyperDeployer();
    address TOKEN_ADDR = 0x00000;
    address AUTHORIZER_ADDR = 0x00000;

    IVotingEscrow votingEscrow;

    function setUp() public {
        ///@notice deploy a new instance of ISimplestore by passing in the address of the deployed Vyper contract
        votingEscrow = IVotingEscrow(
            vyperDeployer.deployContract(
                "VotingEscrow", TOKEN_ADDR, "Voting Escrowed Test Token", "veTest", AUTHORIZER_ADDR
            )
        );
    }

    function testGet() public {
        uint256 val = votingEscrow.token();

        require(val == 1234);
    }
}
