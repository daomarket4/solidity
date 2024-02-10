// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

interface VotingContract {
    function getVoteResult(uint256 proposalIndex) external view returns (uint256 yesVotes, uint256 noVotes);
}

contract SaleContract {
    VotingContract public votingContract;

    constructor(address _votingContractAddress) {
        votingContract = VotingContract(_votingContractAddress);
    }

    // 판매를 실행하는 함수입니다.
    function executeSale(uint256 proposalIndex) public {
        // 투표 결과를 가져옵니다.
        (uint256 yesVotes, uint256 noVotes) = votingContract.getVoteResult(proposalIndex);
        
        // 투표 비율을 계산합니다.
        uint256 totalVotes = yesVotes + noVotes;
        uint256 yesPercentage = (yesVotes * 100) / totalVotes;

        // yes 비율이 50%를 초과하는지 확인
        require(yesPercentage > 50, "Not enough 'yes' votes to execute sale");


        // 판매 로직 구현
        // 자금 분배 NFT 전송 구현
    }
}
