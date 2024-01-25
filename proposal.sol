// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.2 <0.9.0;

contract ProposalContract {
    struct Proposal {
        address proposer;
        string description;
        uint256 fundingGoal;
        bool executed;
    }

    Proposal[] public proposals;

    function createProposal(string memory description, uint256 fundingGoal) public {
        proposals.push(Proposal({
            proposer: msg.sender,
            description: description,
            fundingGoal: fundingGoal,
            executed: false
        }));
    }
}
