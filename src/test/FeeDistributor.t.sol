// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../IVotingEscrow.sol";
import "../MyToken.sol";
import "../FeeDistributor.sol";

abstract contract HelperContract {
    VyperDeployer _vyperDeployer = new VyperDeployer();

    MyToken _token;

    IVotingEscrow _votingEscrow;

    FeeDistributor _feeDistributor;

    constructor() {
        _token = new MyToken("Voting Escrowed Test Token", "veTEST");

        _votingEscrow = IVotingEscrow(
            _vyperDeployer.deployContract("VotingEscrow", abi.encode(_token, "Voting Escrowed Test Token", "veTEST"))
        );
        

        _feeDistributor = new FeeDistributor(_votingEscrow, 5);
    }

}

contract FeeDistributorTest is Test, HelperContract {
    function testVeToken() public view {
        address val = _votingEscrow.token();

        require(val == address(_token));
    }
}
