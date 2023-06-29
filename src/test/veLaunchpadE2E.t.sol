// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Test.sol";

import "../../utils/VyperDeployer.sol";

import "../IVotingEscrow.sol";
import "../MyToken.sol";

abstract contract HelperContract {
    VyperDeployer vyperDeployer = new VyperDeployer();

    MyToken token;

    IVotingEscrow votingEscrow;

    constructor() {
        token = new MyToken("Voting Escrowed Test Token","veTEST");

        votingEscrow = IVotingEscrow(
            vyperDeployer.deployContract("VotingEscrow", abi.encode(token, "Voting Escrowed Test Token", "veTEST"))
        );
    }
}

contract veLaunchPadE2E is Test, HelperContract {
    function testVeToken() public view {
        address val = votingEscrow.token();

        require(val == address(token));
    }

    function testVeTokenName() public view {
        require(
            keccak256(abi.encodePacked(votingEscrow.name()))
                == keccak256(abi.encodePacked("Voting Escrowed Test Token"))
        );
    }

    function testVeTokenSymbol() public view {
        require(keccak256(abi.encodePacked(votingEscrow.symbol())) == keccak256(abi.encodePacked("veTEST")));
    }

    function testVeAdmin() public view {
        address val = votingEscrow.admin();

        require(val == address(vyperDeployer));
    }

    function testCreateLock() public {
        uint256 amount = 1e18;
        uint256 year = 365 * 86400;
        require(votingEscrow.totalSupply() == 0);
        require(token.balanceOf(address(this)) == 0);
        require(token.totalSupply() == 0);
        require(votingEscrow.epoch() == 0);

        token.mint(address(this), amount);
        token.approve(address(votingEscrow), amount);
        require(token.balanceOf(address(this)) == amount);

        votingEscrow.create_lock(amount, block.timestamp + year);
        require(token.balanceOf(address(this)) == 0);
        require(votingEscrow.epoch()==1);
        require(votingEscrow.supply() == amount);


        require(votingEscrow.totalSupply() > 0);
        require(votingEscrow.totalSupply(block.timestamp + year) == 0);
    }



    // function testIncreaseLockAmount() public {
    //     token.mint(address(this), 100);
    //     token.approve(address(votingEscrow), 100);
    //     votingEscrow.create_lock(100, 1690645);
    //     votingEscrow.increase_amount(100);
    // }
}
