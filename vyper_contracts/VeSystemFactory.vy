votingEscrowBlueprint: public(address)
rewardDistributorBlueprint: public(address)
votingEscrowRegister: public(HashMap[address, bool])
rewardDistributorRegister: public(HashMap[address, bool])

interface tokenInterface:
    def getOwner() -> address: view

event NewVESystem:
    admin: address
    token: address
    votingEscrowAddres: address
    rewardDistributorAddress: address

@external
def __init__(
    _votingEscrowBlueprint: address, _rewardDistributorBluePrint: address
):
    self.votingEscrowBlueprint = _votingEscrowBlueprint
    self.rewardDistributorBlueprint = _rewardDistributorBluePrint

@external
def deploy(
    _tokenAddr: address,
    _name: String[64],
    _symbol: String[32],
    _timeToStartRewardDistributor: uint256,
) -> (address, address):
    assert (
        msg.sender == tokenInterface(_tokenAddr).getOwner()
    ), "only token owner can deploy"

    _deployedVE: address = create_from_blueprint(
        self.votingEscrowBlueprint,
        _tokenAddr,
        _name,
        _symbol,
        msg.sender,
        code_offset=3,
    )
    self.votingEscrowRegister[_deployedVE] = True


    _deployedRD: address = create_from_blueprint(
        self.rewardDistributorBlueprint,
        _deployedVE,
        block.timestamp + _timeToStartRewardDistributor,
        code_offset=3,
    )
    self.rewardDistributorRegister[_deployedRD] = True

    log NewVESystem(
        msg.sender,
        _tokenAddr,
        _deployedVE,
        _deployedRD
    )
    return (_deployedVE, _deployedRD)
