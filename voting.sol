// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.2 <0.9.0;

contract VotingContract {
    struct Vote {
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Vote) public votes;
    uint256 public constant VOTE_THRESHOLD = 60;

    function proposeVote(uint256 proposalIndex) public {
        votes[proposalIndex] = Vote({ yesVotes: 0, noVotes: 0, executed: false });
    }

    function vote(uint256 proposalIndex, bool voteYes) public {
        Vote storage vote = votes[proposalIndex];
        require(!vote.voted[msg.sender], "Already voted");
        vote.voted[msg.sender] = true;

        if (voteYes) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }
    }
}