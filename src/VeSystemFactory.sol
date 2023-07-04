// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../utils/VyperDeployer.sol";

import "./IVeSystemFactory.sol";
import "./IVotingEscrow.sol";
import "./FeeDistributor.sol";

contract VeSystemFactory is IVeSystemFactory {
    VyperDeployer _vyperDeployer = new VyperDeployer();

    address public owner;
    FeeDistributor public feeDistributor;
    IVotingEscrow public votingEscrow;

    constructor() {
        owner = msg.sender;
    }

    function deploy(address token, string memory tokenName, string memory tokenSymbol) external virtual {
        _deployVe(token, tokenName, tokenSymbol);
        _deployRewardDistributor();
    }

    function _deployVe(address token, string memory tokenName, string memory tokenSymbol) internal virtual {
        votingEscrow =
            IVotingEscrow(_vyperDeployer.deployContract("VotingEscrow", abi.encode(token, tokenName, tokenSymbol)));
    }

    function _deployRewardDistributor(uint256 startTime) internal virtual {
        feeDistributor = new FeeDistributor(votingEscrow, startTime);
    }
}
