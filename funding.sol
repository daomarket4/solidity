// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.2 <0.9.0;

contract FundingContract {
    struct Funding {
        uint256 amountRaised;
        uint256 fundingGoal;
    }

    mapping(uint256 => Funding) public fundings;

    function fund(uint256 proposalIndex) public payable {
        Funding storage funding = fundings[proposalIndex];
        require(msg.value > 0, "Funding amount must be greater than 0");
        require(funding.amountRaised < funding.fundingGoal, "Funding goal reached");
        funding.amountRaised += msg.value;
    }
}