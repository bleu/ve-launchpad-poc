// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IVeSystemFactory {
    function getBlueprints() external view returns (address, address);
    function deploy(address _tokenAddr, string memory _name, string memory _symbol, uint256 _startRewardDistributorTime) external returns (address, address);
}
