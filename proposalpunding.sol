// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// 안건등록과 동시에 펀딩시작, 펀딩 참여,종료 까지 일단

contract ProposalAndFunding {
    // 안건 구조체 정의
     struct Proposal {
        address proposer;  // 제안자의 주소
        string title;  // 안건 제목
        string nftLink;  // 구매하고자 하는 NFT 링크
        string imageLink;  // 사진 링크
        uint256 fundingGoal;  // 펀딩 원하는 금액 (이더리움)
        uint256 amountRaised;  // 현재까지 모금된 금액
        uint256 startTime;  // 안건 & 펀딩 시작 시간
        uint256 endTime;  // 안건 & 펀딩 종료 시간
        string description;  // 안건 내용
        bool fundingClosed;  // 펀딩 종료 여부
        mapping(address => uint256) contributions;  // 각 참여자의 기여 금액
    }

    Proposal[] public proposals;  // 모든 안건을 저장하는 배열

    // 안건 제안 및 펀딩 시작 이벤트
    event NewProposal(uint256 proposalId, address proposer, uint256 fundingGoal, uint256 startTime, uint256 endTime);
    // 펀딩 참여 이벤트
    event FundingReceived(uint256 proposalId, address contributor, uint256 amount);
    // 펀딩 종료 이벤트
    event FundingClosed(uint256 proposalId, uint256 amountRaised);

    // 안건 생성 및 펀딩 시작 함수
function createProposalAndStartFunding(
    string memory _title,
    string memory _nftLink,
    string memory _imageLink,
    uint256 _fundingGoal,
    uint256 _durationInDays,
    string memory _description
) public {
    require(_durationInDays >= 1 && _durationInDays <= 7, "Duration must be between 1 and 7 days");
    
    uint256 startTime = block.timestamp;
    uint256 endTime = startTime + (_durationInDays * 1 days);
    uint256 fundingGoalWithMargin = _fundingGoal + (_fundingGoal * 10 / 100);  // 금액 변동성 고려, 10% 가산
    
    proposals.push();  // 빈 Proposal 구조체를 배열에 추가
    uint256 proposalId = proposals.length - 1;  // 새 Proposal의 인덱스
    Proposal storage proposal = proposals[proposalId];
    
    proposal.proposer = msg.sender;
    proposal.title = _title;
    proposal.nftLink = _nftLink;
    proposal.imageLink = _imageLink;
    proposal.fundingGoal = fundingGoalWithMargin;
    proposal.amountRaised = 0;
    proposal.startTime = startTime;
    proposal.endTime = endTime;
    proposal.description = _description;
    proposal.fundingClosed = false;

    emit NewProposal(proposalId, msg.sender, fundingGoalWithMargin, startTime, endTime);
}


   // 펀딩에 참여하는 함수
    function fundProposal(uint256 _proposalId) public payable {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.fundingClosed, "Funding is already closed");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Funding is not active");
        require(proposal.amountRaised + msg.value <= proposal.fundingGoal, "Funding goal exceeded");

        proposal.contributions[msg.sender] += msg.value;
        proposal.amountRaised += msg.value;
        emit FundingReceived(_proposalId, msg.sender, msg.value);

        // 목표 금액에 도달하면 펀딩 종료
        if (proposal.amountRaised >= proposal.fundingGoal) {
            proposal.fundingClosed = true;
            emit FundingClosed(_proposalId, proposal.amountRaised);
        }
    }

    // 펀딩 종료 및 환불 처리 함수
    function finalizeAndRefund(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Funding period is not over yet");
        require(!proposal.fundingClosed, "Funding is already closed");

        proposal.fundingClosed = true;

        if (proposal.amountRaised < proposal.fundingGoal) {
            // 펀딩 목표에 도달하지 못한 경우 환불
            for (uint256 i = 0; i < proposals.length; i++) {
                uint256 contributedAmount = proposal.contributions[proposals[i].proposer];
                if (contributedAmount > 0) {
                    address payable contributor = payable(proposals[i].proposer);
                    proposal.contributions[contributor] = 0;
                    contributor.transfer(contributedAmount);
                }
            }
        }
        emit FundingClosed(_proposalId, proposal.amountRaised);
    }

    // 컨트랙트가 이더를 받을 수 있도록 fallback 함수 정의
    receive() external payable {}
}
