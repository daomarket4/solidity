// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MintNFT.sol";

contract VotingContract is MintNFT {
    // 각 투표에 대한 정보를 저장하는 구조체
    struct Vote {
        uint256 yesVotes; // 찬성 표 수
        uint256 noVotes; // 반대 표 수
        bool executed; // 투표 실행 여부
    }

    // 투표 제안 인덱스로 Vote 구조체에 접근 매핑
    mapping(uint256 => Vote) public votes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // 총 투표 수
    uint256 public constant TOTAL_VOTES = 100;

    // 투표 임계값(퍼센트로 표현된 값)
    uint256 public constant VOTE_THRESHOLD_PERCENTAGE = 50;

    // 투표 제안을 받아들이기 위한 최소 투표 수 계산
    uint256 public constant VOTE_THRESHOLD = (TOTAL_VOTES * VOTE_THRESHOLD_PERCENTAGE) / 100;

    // 제안된 투표를 초기화하고 저장하는 함수
    function proposeVote(uint256 proposalIndex) public {
        votes[proposalIndex] = Vote({ yesVotes: 0, noVotes: 0, executed: false });
    }

    // 특정 제안에 투표하는 함수
    function vote(uint256 proposalIndex, bool voteYes) public {
        require(!hasVoted[proposalIndex][msg.sender], "Already voted");
        
        Vote storage voteInfo = votes[proposalIndex];
        hasVoted[proposalIndex][msg.sender] = true;

        // 찬성/반대 투표 수 업데이트
        if (voteYes) {
            voteInfo.yesVotes += getVotingPower(msg.sender);
        } else {
            voteInfo.noVotes += getVotingPower(msg.sender);
        }
    }

    // 특정 주소의 보팅 파워를 가져오는 함수
    function getVotingPower(address voter) internal view returns (uint256) {
        // MintNFT 컨트랙트를 통해 성공적으로 모금된 내역을 가져옴
        (
            uint256[] memory proposalIds,
            address[] memory proposers,
            uint256[] memory totalFundingAmounts,
            address[][] memory contributors,
            uint256[][] memory fundingAmounts,
            uint256[] memory fundingTimes,
            uint256[] memory fundingShares
        ) = getSuccessfulFundingDetails();

        uint256 votingPower = 0;

        // 각 모금 내역을 확인하여 보팅 주소의 기여를 찾아 보팅 파워 계산
        for (uint256 i = 0; i < proposalIds.length; i++) {
            for (uint256 j = 0; j < contributors[i].length; j++) {
                if (contributors[i][j] == voter) {
                    votingPower += (fundingAmounts[i][j] * fundingShares[i]) / totalFundingAmounts[i];
                }
            }
        }

        return votingPower;
    }
}
