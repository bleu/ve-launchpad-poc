import "./IRewardDistributor.sol";
import "./IBleuVotingEscrow.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Clones.sol";


contract VeSystemFactory {
    address private _votingEscrowImplementation;
    address private _rewardDistributorImplementation;

    constructor(
        address votingEscrowImplementation,
        address rewardDistributorImplementation
    )
    {
        _votingEscrowImplementation = votingEscrowImplementation;
        _rewardDistributorImplementation = rewardDistributorImplementation;
    }

    function getVotingEscrowImplementation() external view returns (address) {
        return _votingEscrowImplementation;
    }

    function getRewardDistributorImplementation() external view returns (address) {
        return _rewardDistributorImplementation;
    }

    function create(
        address token,
        string memory name,
        string memory symbol,
        uint256 rewardDistributorStartTimeStamp
    ) external returns (address) {
        address votingEscrow = Clones.clone(_votingEscrowImplementation);
        IBleuVotingEscrow(votingEscrow).initialize(token, name, symbol);
    }
}