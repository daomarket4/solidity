// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract ProposalContract {
    struct Proposal {
        address proposer; // 제안자 주소
        string title; // 안건 제목
        string nftLink; // 구매하고자 하는 NFT 링크
        string imageLink; // 사진 링크
        uint256 fundingGoal; // 모금 원하는 금액 (이더리움)
        uint256 startTime; // 안건 시작 시간
        uint256 endTime; // 안건 종료 시간
        string description; // 안건 내용
        bool executed; // 실행 여부
    }

    Proposal[] public proposals;

    // 안건 생성 함수
    function createProposal(
        string memory title,
        string memory nftLink,
        string memory imageLink,
        uint256 fundingGoal,
        uint256 durationInDays,
        string memory description
    ) public {
        require(durationInDays >= 1 && durationInDays <= 7, "Duration must be between 1 and 7 days");
        uint256 startTime = block.timestamp; // 현재 시간
        uint256 endTime = startTime + (durationInDays * 1 days); // 종료 시간 설정

        proposals.push(Proposal({
            proposer: msg.sender,
            title: title,
            nftLink: nftLink,
            imageLink: imageLink,
            fundingGoal: fundingGoal,
            startTime: startTime,
            endTime: endTime,
            description: description,
            executed: false
        }));
    }
}
