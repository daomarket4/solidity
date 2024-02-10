// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract VotingContract {
    struct Vote {
        uint256 yesVotes; // 찬성 표 수
        uint256 noVotes; // 반대 표 수
        bool executed; // 투표가 실행되었는지 여부
        mapping(address => bool) voted; // 투표 여부를 저장하는 매핑
    }

    mapping(uint256 => Vote) public votes;
    uint256 public constant TOTAL_VOTES = 100;
    uint256 public constant VOTE_THRESHOLD_PERCENTAGE = 50; // 퍼센트로 표현된 임계값

    // 투표 제안을 받아들이기 위한 최소 표수 계산
    uint256 public constant VOTE_THRESHOLD = (TOTAL_VOTES * VOTE_THRESHOLD_PERCENTAGE) / 100;

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
