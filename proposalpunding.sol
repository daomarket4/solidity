// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract ProposalAndFunding {
    address public admin; // 초기 관리자 주소
    mapping(address => bool) public admins; // 관리자 목록

    struct Contribution {
        uint256 amount; // 기여한 이더 양
        uint256 timestamp; // 기여한 시간
    }

    struct Proposal {
        address proposer; // 제안자 주소
        string title; // 제안 제목
        string nftLink; // NFT 링크
        string imageLink; // 이미지 링크
        uint256 fundingGoal; // 목표 모금액
        uint256 amountRaised; // 현재까지 모금된 금액
        uint256 startTime; // 펀딩 시작 시간
        uint256 endTime; // 펀딩 종료 시간
        string description; // 제안 설명
        bool fundingClosed; // 펀딩 종료 여부
        bool isRefunded; // 환불 여부
    }

    struct RefundInfo {
        uint256 amount; // 환불 금액
        uint256 timestamp; // 환불 시간
    }

    Proposal[] public proposals; // 모든 제안 리스트
    mapping(uint256 => mapping(address => Contribution)) public contributions; // 각 제안에 대한 기여 내역
    mapping(uint256 => address[]) public proposalContributors; // 각 제안에 대한 기여자 목록
    mapping(uint256 => mapping(address => RefundInfo)) public refunds; // 각 제안에 대한 환불 정보

    event NewProposal(uint256 indexed proposalId, address indexed proposer, uint256 fundingGoal, uint256 startTime, uint256 endTime); // 새로운 제안 이벤트
    event FundingReceived(uint256 indexed proposalId, address contributor, uint256 amount); // 모금 이벤트
    event FundingClosed(uint256 indexed proposalId, uint256 amountRaised); // 펀딩 종료 이벤트

    constructor() {
        admin = msg.sender; // 컨트랙트 생성자를 기본 관리자로 설정
        admins[msg.sender] = true; // 기본 관리자 추가
        admins[0xe3cd9fC292B724095874522026Fb68932329296C] = true;
        admins[0xeFfC9eAf0CB26B4CA0614Ea99aCa0908Ca468FB3] = true;
        admins[0x32C1B6C8261F665Ac41a2b176C488d16ccD4109C] = true;
        admins[0x11D539b3339A89633e4067E6036Ea2729E225467] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin"); // 관리자만 실행 가능
        _;
    }

    // 관리자 추가 함수
    function addAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid address"); // 유효한 주소인지 확인
        admins[_newAdmin] = true; // 새로운 관리자 추가
    }

    // 관리자 삭제 함수
    function removeAdmin(address _admin) public onlyAdmin {
        require(_admin != msg.sender, "Cannot remove self"); // 자기 자신을 삭제할 수 없도록 함
        admins[_admin] = false; // 관리자 삭제
    }

    // 제안 생성 및 펀딩 시작 함수
    function createProposalAndStartFunding(
        string memory _title,
        string memory _nftLink,
        string memory _imageLink,
        uint256 _fundingGoal,
        uint256 _durationInDays,
        string memory _description
    ) public {
        uint256 startTime = block.timestamp; // 현재 시간을 시작 시간으로 설정
        uint256 endTime = startTime + (_durationInDays * 1 days); // 지정된 기간 뒤에 종료될 시간 설정

        // 새로운 제안 객체 생성
        Proposal memory newProposal = Proposal({
            proposer: msg.sender,
            title: _title,
            nftLink: _nftLink,
            imageLink: _imageLink,
            fundingGoal: _fundingGoal,
            amountRaised: 0,
            startTime: startTime,
            endTime: endTime,
            description: _description,
            fundingClosed: false,
            isRefunded: false
        });
        proposals.push(newProposal); // 제안 리스트에 추가
        emit NewProposal(proposals.length - 1, msg.sender, _fundingGoal, startTime, endTime); // 새로운 제안 이벤트 발생
    }

    // 펀딩 함수
    function fundProposal(uint256 _proposalId) public payable {
        require(_proposalId < proposals.length, "Proposal does not exist"); // 제안이 존재하는지 확인
        Proposal storage proposal = proposals[_proposalId]; // 해당 제안 가져오기

        // 펀딩 가능한 상태인지 확인
        require(!proposal.fundingClosed, "Funding is already closed"); // 펀딩이 이미 종료되었는지 확인
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Funding period is not active"); // 펀딩 기간 내에 있는지 확인
        require(proposal.amountRaised + msg.value <= proposal.fundingGoal, "Funding goal exceeded"); // 목표 모금액을 초과하지 않았는지 확인

        // 기여 내역 업데이트
        contributions[_proposalId][msg.sender].amount += msg.value; // 기여한 이더 양 추가
        contributions[_proposalId][msg.sender].timestamp = block.timestamp; // 기여한 시간 업데이트

        // 제안에 기여한 금액 업데이트
        proposal.amountRaised += msg.value; // 제안에 모금된 금액 업데이트
        proposalContributors[_proposalId].push(msg.sender); // 기여자 목록에 추가

        emit FundingReceived(_proposalId, msg.sender, msg.value); // 모금 이벤트 발생

        // 목표 모금액을 달성했는지 확인 후 펀딩 종료 이벤트 발생
        if (proposal.amountRaised >= proposal.fundingGoal) {
            proposal.fundingClosed = true; // 펀딩 종료 상태로 변경
            emit FundingClosed(_proposalId, proposal.amountRaised); // 펀딩 종료 이벤트 발생
        }
    }

    // 펀딩 취소 및 환불 함수
    function cancelFundingAndRefund(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId]; // 해당 제안 가져오기
        require(msg.sender == proposal.proposer || admins[msg.sender], "Not authorized"); // 권한 확인
        require(!proposal.fundingClosed, "Funding already closed"); // 펀딩이 이미 종료되었는지 확인

        proposal.fundingClosed = true; // 펀딩 종료 상태로 변경
        address[] memory contributors = proposalContributors[_proposalId]; // 해당 제안에 기여한 기여자 목록 가져오기
        for (uint256 i = 0; i < contributors.length; i++) {
            address payable contributor = payable(contributors[i]); // 기여자 주소 가져오기
            uint256 contributedAmount = contributions[_proposalId][contributor].amount; // 기여한 이더 양 가져오기
            if (contributedAmount > 0) {
                contributions[_proposalId][contributor].amount = 0; // 기여한 이더 양 초기화
                (bool sent, ) = contributor.call{value: contributedAmount}(""); // 기여자에게 환불
                require(sent, "Failed to send Ether"); // 환불 실패 시 오류 발생
                refunds[_proposalId][contributor] = RefundInfo({ // 환불 정보 기록
                    amount: contributedAmount,
                    timestamp: block.timestamp
                });
            }
        }
        proposal.isRefunded = true; // 환불 상태로 변경
    }

    // 환불 정보 조회 함수
    function getRefundInfo(uint256 _proposalId, address _contributor) public view returns (uint256, uint256) {
        RefundInfo storage refundInfo = refunds[_proposalId][_contributor]; // 해당 제안에서 해당 기여자의 환불 정보 가져오기
        return (refundInfo.amount, refundInfo.timestamp); // 환불 정보 반환
    }

    // 제안 상세 정보 조회 함수
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
        bool fundingClosed,
        bool isRefunded,
        address contractAddress // 컨트랙트 주소 반환을 위한 추가 필드
    ) {
        Proposal storage proposal = proposals[_proposalId]; // 해당 제안 가져오기
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
            proposal.fundingClosed,
            proposal.isRefunded,
            address(this) // 현재 컨트랙트의 주소 반환
        );
    }

    // 제안 수 조회 함수
    function getProposalsCount() public view returns (uint256) { 
        return proposals.length; // 제안 배열의 길이 반환
    }

    // 기여자 목록 조회 함수
    function getContributors(uint256 _proposalId) public view returns (address[] memory) {
        return proposalContributors[_proposalId]; // 해당 제안의 기여자 목록 반환
    }

    // 기여 금액 및 시간 조회 함수
    function getContributionDetails(uint256 _proposalId, address _contributor) public view returns (uint256, uint256) {
        Contribution storage contribution = contributions[_proposalId][_contributor]; // 해당 제안에서 해당 기여자의 기여 내역 가져오기
        return (contribution.amount, contribution.timestamp); // 기여 내역 반환
    }

    // 전체 제안 수 조회 함수
    function getTotalProposals() public view returns (uint256) {
        return proposals.length; // 모든 제안의 수 반환
    }

    // 펀딩 종료 확인 함수
    function checkFundingStatus(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId]; // 해당 제안 가져오기
        require(block.timestamp > proposal.endTime, "Funding period has not ended yet"); // 펀딩 기간이 아직 종료되지 않았는지 확인
        require(!proposal.fundingClosed, "Funding is already closed"); // 펀딩이 이미 종료되었는지 확인

        // 펀딩 기간이 종료되었고, 목표 모금액에 도달하지 못했을 경우
        if (proposal.amountRaised < proposal.fundingGoal) {
            proposal.fundingClosed = true; // 펀딩 종료 상태로 변경
            address[] memory contributors = proposalContributors[_proposalId]; // 해당 제안에 기여한 기여자 목록 가져오기
            
            // 모든 기여자에게 기여금 환불
            for (uint256 i = 0; i < contributors.length; i++) {
                address payable contributor = payable(contributors[i]); // 기여자 주소 가져오기
                uint256 contributedAmount = contributions[_proposalId][contributor].amount; // 기여한 이더 양 가져오기
                if (contributedAmount > 0) {
                    contributions[_proposalId][contributor].amount = 0; // 기여한 이더 양 초기화
                    (bool sent, ) = contributor.call{value: contributedAmount}(""); // 기여자에게 환불
                    require(sent, "Failed to send Ether"); // 환불 실패 시 오류 발생
                }
            }
            proposal.isRefunded = true; // 환불 상태로 변경
        }
    }

    // 이더리움을 받을 수 있는 fallback 함수
    receive() external payable {}

    // 펀딩 성공 시 호출할 함수
    function purchaseNFT(uint256 _proposalId) public onlyAdmin {
        Proposal storage proposal = proposals[_proposalId]; // 해당 제안 가져오기
        require(proposal.fundingClosed, "Funding is not closed yet"); // 펀딩이 아직 종료되지 않았는지 확인
        require(proposal.amountRaised >= proposal.fundingGoal, "Funding goal not reached yet"); // 목표 모금액에 도달했는지 확인

        // NFT 구매를 위한 NFT 구매 스마트 계약의 purchaseNFT 함수 호출
        // 예시: NFTPurchaseContract nftContract = NFTPurchaseContract(nftContractAddress);
        // nftContract.purchaseNFT(proposal.proposer, proposal.nftLink, proposal.imageLink); 
    }
    
    // 목표 모금액 달성 여부 확인 함수
    function isFundingGoalReached(uint256 _proposalId) public view returns (bool) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];
        return proposal.amountRaised >= proposal.fundingGoal;
    }
}
