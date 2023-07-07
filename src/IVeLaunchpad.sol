// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IVeLaunchpad {
    function getBlueprints() external view returns (address, address);

    function votingEscrowBlueprint() external view returns (address);

    function rewardDistributorBlueprint() external view returns (address);

    function votingEscrowRegister(address) external view returns (bool);

    function rewardDistributorRegister(address) external view returns (bool);

    function deploy(
        address _tokenAddr,
        string memory _name,
        string memory _symbol,
        uint256 _timeToStartRewardDistributor
    ) external returns (address, address);
}
