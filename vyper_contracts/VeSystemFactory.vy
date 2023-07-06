
votingEscrowBlueprint: address
rewardDistributorBlueprint: address

@external
def __init__(_votingEscrowBlueprint: address, _rewardDistributorBluePrint: address):
    self.votingEscrowBlueprint = _votingEscrowBlueprint
    self.rewardDistributorBlueprint = _rewardDistributorBluePrint

@external
def getBlueprints() -> (address, address):
    return (self.votingEscrowBlueprint, self.rewardDistributorBlueprint)

@external
def deploy(_tokenAddr: address, _name: String[64], _symbol: String[32], _startRewardDistributorTime: uint256) -> (address, address):
    _deployedVE: address = create_from_blueprint(self.votingEscrowBlueprint, _tokenAddr, _name, _symbol)
    # _deployedRD: address = create_from_blueprint(self.rewardDistributorBlueprint, _deployedVE, _startRewardDistributorTime)
    return (_deployedVE, _tokenAddr)
