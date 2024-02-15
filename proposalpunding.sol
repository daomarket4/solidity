// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract ProposalAndFunding {
    // 안건에 대한 정보를 담는 구조체
    struct Proposal {
        address proposer; // 제안자의 주소
        string title; // 안건의 제목
        string nftLink; // 구매하고자 하는 NFT의 링크
        string imageLink; // 안건 관련 이미지 링크
        uint256 fundingGoal; // 목표 펀딩 금액
        uint256 amountRaised; // 현재까지 모금된 금액 
        uint256 startTime; // 펀딩 시작 시간
        uint256 endTime; // 펀딩 종료 시간
        string description; // 안건의 설명
        bool fundingClosed; // 펀딩이 종료되었는지의 여부
    }

    // 모든 안건을 저장하는 배열
    Proposal[] public proposals;
    // 제안 ID와 참여자 주소에 따른 기여 금액을 추적하는 매핑
    mapping(uint256 => mapping(address => uint256)) public contributions;

    // 새 안건이 생성될 때 발생하는 이벤트
    event NewProposal(uint256 indexed proposalId, address indexed proposer, uint256 fundingGoal, uint256 startTime, uint256 endTime);
    // 펀딩에 참여할 때 발생하는 이벤트
    event FundingReceived(uint256 indexed proposalId, address contributor, uint256 amount);
    // 펀딩이 종료될 때 발생하는 이벤트
    event FundingClosed(uint256 indexed proposalId, uint256 amountRaised);

    // 안건을 생성하고 펀딩을 시작하는 함수
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
        uint256 fundingGoalWithMargin = _fundingGoal + (_fundingGoal * 10 / 100);
        
        proposals.push(Proposal({
            proposer: msg.sender,
            title: _title,
            nftLink: _nftLink,
            imageLink: _imageLink,
            fundingGoal: fundingGoalWithMargin,
            amountRaised: 0,
            startTime: startTime,
            endTime: endTime,
            description: _description,
            fundingClosed: false
        }));
        uint256 proposalId = proposals.length - 1;
        
        emit NewProposal(proposalId, msg.sender, fundingGoalWithMargin, startTime, endTime);
    }

    // 펀딩에 참여하는 함수
    function fundProposal(uint256 _proposalId) public payable {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.fundingClosed, "Funding is already closed");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Funding period is not active");
        require(proposal.amountRaised + msg.value <= proposal.fundingGoal, "Funding goal exceeded");

        contributions[_proposalId][msg.sender] += msg.value;
        proposal.amountRaised += msg.value;

        emit FundingReceived(_proposalId, msg.sender, msg.value);

        if (proposal.amountRaised >= proposal.fundingGoal) {
            proposal.fundingClosed = true;
            emit FundingClosed(_proposalId, proposal.amountRaised);
        }
    }

    // 목표 금액 도달 여부를 확인하는 함수
    function isFundingGoalReached(uint256 _proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        return proposal.amountRaised >= proposal.fundingGoal;
    }

     // 펀딩 종료 후 환불 처리 함수
    /* function finalizeAndRefund(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        // 펀딩 기간 종료 및 상태 검증
        require(block.timestamp > proposal.endTime, "Funding period is not over yet");
        require(!proposal.fundingClosed, "Funding is already closed");

        proposal.fundingClosed = true;

        // 목표 금액에 미달한 경우 환불 처리
        if (proposal.amountRaised < proposal.fundingGoal) {
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
    } */


    // 안건 상세 정보를 조회하는 함수
    function getProposal(uint256 _proposalId) public view returns (
        address proposer,
        string memory title,
        string memory nftLink,
        string memory imageLink,
        uint256 fundingGoal,
        uint256 amountRaised,
        uint256 startTime,
        uint256 endTime,
        string memory description,
        bool fundingClosed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.nftLink,
            proposal.imageLink,
            proposal.fundingGoal,
            proposal.amountRaised,
            proposal.startTime,
            proposal.endTime,
            proposal.description,
            proposal.fundingClosed
        );
    }

    function getProposalsCount() public view returns (uint256) { 
        return proposals.length; 
    }

    // 이더리움을 받을 수 있는 fallback 함수
    receive() external payable {}
}
