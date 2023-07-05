// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "../utils/VyperDeployer.sol";

import "./RewardDistributor.sol";
import "./IBleuVotingEscrow.sol";

contract VeSystemFactory {
    VyperDeployer internal _vyperDeployer = new VyperDeployer();

    address public owner;
    RewardDistributor public rewardDistributor;
    IBleuVotingEscrow public votingEscrow;

    constructor() {
        owner = msg.sender;
    }

    function deploy(address token, string memory tokenName, string memory tokenSymbol) external virtual {
        _deployVe(token, tokenName, tokenSymbol);
        _deployRewardDistributor(604800);
    }

    function _deployVe(address token, string memory tokenName, string memory tokenSymbol) internal virtual {
        votingEscrow =
            IBleuVotingEscrow(_vyperDeployer.deployContract("VotingEscrow", abi.encode(token, tokenName, tokenSymbol)));
    }

    function _deployRewardDistributor(uint256 startTime) internal virtual {
        rewardDistributor = new RewardDistributor(votingEscrow, startTime);
    }
}
