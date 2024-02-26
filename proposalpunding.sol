// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract ProposalAndFunding {
    address public admin; // 초기 관리자 주소
    mapping(address => bool) public admins; // 관리자 목록
    address[] public adminList; // 관리자 주소 목록
    Proposal[] public proposals; // 모든 제안 리스트

    struct Contribution {
        uint256 amount; // 기여한 이더 양
        uint256 timestamp; // 기여한 시간
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description; // 설명
        string nftLink; // NFT 링크
        string imageLink; // 이미지 링크
        uint256 fundingGoal;
        uint256 amountRaised;
        uint256 startTime;
        uint256 endTime;
        bool fundingClosed;
        bool isRefunded;
        bool isUserCancelled; // 사용자에 의한 취소 여부
    }

    mapping(uint256 => mapping(address => Contribution)) public contributions;
    mapping(uint256 => address[]) public proposalContributors;
    mapping(uint256 => mapping(address => uint256)) public refunds;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 fundingGoal, uint256 startTime, uint256 endTime);
    event FundingReceived(uint256 indexed proposalId, address contributor, uint256 amount);
    event FundingClosed(uint256 indexed proposalId, uint256 amountRaised);
    event FundingCancelled(uint256 indexed proposalId); // 취소 이벤트 추가

   constructor() {
        admin = msg.sender; // 배포자를 초기 관리자로 설정
        admins[msg.sender] = true; // 배포자의 관리자 여부를 참으로 설정
        adminList.push(msg.sender); // 관리자 목록에 배포자 추가
    }

    function addAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        require(!admins[_newAdmin], "Already an admin");
        admins[_newAdmin] = true;
        adminList.push(_newAdmin); // 관리자 목록에 새 관리자 추가
    }

    function removeAdmin(address _admin) public onlyAdmin {
        require(_admin != msg.sender, "Cannot remove self");
        require(admins[_admin], "Not an admin");
        admins[_admin] = false;

        // 관리자 목록에서 제거하는 로직 구현
        for (uint i = 0; i < adminList.length; i++) {
            if (adminList[i] == _admin) {
                adminList[i] = adminList[adminList.length - 1];
                adminList.pop();
                break;
            }
        }
    }

    function getAdmins() public view returns (address[] memory) {
        return adminList; // 현재 등록된 모든 관리자 주소 목록 반환
    }

    // onlyAdmin modifier 구현
    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

// 새로운 제안 객체 생성
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
        proposalId: proposals.length, // proposalId 필드 추가
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
        isRefunded: false,
        isUserCancelled: false // 초기값은 false
    });
    proposals.push(newProposal); 
    emit ProposalCreated(proposals.length - 1, msg.sender, _fundingGoal, startTime, endTime);
}

   function fundProposal(uint256 _proposalId) public payable {
    require(_proposalId < proposals.length, "Proposal does not exist"); // 수정된 부분
    Proposal storage proposal = proposals[_proposalId];
    require(!proposal.fundingClosed, "Funding is already closed");
    require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Funding period is not active");
    require(proposal.amountRaised + msg.value <= proposal.fundingGoal, "Funding goal exceeded");

    // 기여 정보 업데이트
    updateContributions(_proposalId, msg.sender, msg.value);

    emit FundingReceived(_proposalId, msg.sender, msg.value);

    if (proposal.amountRaised >= proposal.fundingGoal) {
        proposal.fundingClosed = true;
        emit FundingClosed(_proposalId, proposal.amountRaised);
    }
}

function updateContributions(uint256 _proposalId, address _contributor, uint256 _amount) internal {
    contributions[_proposalId][_contributor].amount += _amount;
    contributions[_proposalId][_contributor].timestamp = block.timestamp;
    proposals[_proposalId].amountRaised += _amount;
    proposalContributors[_proposalId].push(_contributor);
}

function cancelFundingAndRefund(uint256 _proposalId) public {
    require(_proposalId < proposals.length && _proposalId >= 0, "Proposal does not exist");
    Proposal storage proposal = proposals[_proposalId];
    require(msg.sender == proposal.proposer || admins[msg.sender], "Not authorized");
    require(!proposal.fundingClosed, "Funding already closed");

    // 펀딩 취소 및 환불 수행
    cancelFunding(_proposalId);
    refundContributions(_proposalId);

    proposal.isRefunded = true;
}

function cancelFunding(uint256 _proposalId) internal {
    proposals[_proposalId].fundingClosed = true;
    proposals[_proposalId].isUserCancelled = true; // 취소 표시
    emit FundingCancelled(_proposalId); // 취소 이벤트 발생
}

function refundContributions(uint256 _proposalId) internal {
    address[] memory contributorsList = proposalContributors[_proposalId];
    for (uint256 i = 0; i < contributorsList.length; i++) {
        address payable contributor = payable(contributorsList[i]);
        uint256 contributedAmount = contributions[_proposalId][contributor].amount;
        if (contributedAmount > 0) {
            contributions[_proposalId][contributor].amount = 0;
            (bool sent, ) = contributor.call{value: contributedAmount}("");
            require(sent, "Failed to send Ether");
            refunds[_proposalId][contributor] = contributedAmount;
        }
    }
}
    // 환불 정보 조회 함수
    function getRefundInfo(uint256 _proposalId, address _contributor) public view returns (uint256) {
        return refunds[_proposalId][_contributor]; // 해당 제안에서 해당 기여자의 환불 정보 가져오기
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

    // 펀딩 종료 확인 함수
    function checkFundingStatus(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId]; // 해당 제안 가져오기
        require(block.timestamp > proposal.endTime, "Funding period has not ended yet"); // 펀딩 기간이 아직 종료되지 않았는지 확인
        require(!proposal.fundingClosed, "Funding is already closed"); // 펀딩이 이미 종료되었는지 확인

        // 펀딩 기간이 종료되었고, 목표 모금액에 도달하지 못했을 경우
        if (proposal.amountRaised < proposal.fundingGoal) {
            proposal.fundingClosed = true; // 펀딩 종료 상태로 변경
            proposal.isRefunded = true; // 환불 상태로 변경
        }

        emit FundingClosed(_proposalId, proposal.amountRaised); // 펀딩 종료 이벤트 발생
    }
    // 목표 모금액 달성 여부 확인 함수
    function isFundingGoalReached(uint256 _proposalId) public view returns (bool) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];
        return proposal.amountRaised >= proposal.fundingGoal;
    }

  // 제안의 상세 정보를 반환하는 함수
    function getProposal(uint256 _proposalId) public view returns (
    uint256 proposalId,
    address proposer,
    string memory title,
    string memory nftLink,
    string memory imageLink,
    uint256 fundingGoal,
    uint256 amountRaised,
    uint256 startTime,
    uint256 endTime,
    bool fundingClosed,
    bool isRefunded,
    bool isUserCancelled
) {
    require(_proposalId < proposals.length, "Proposal does not exist");
    Proposal storage proposal = proposals[_proposalId];
    return (
        proposal.proposalId,
        proposal.proposer,
        proposal.title,
        proposal.nftLink,
        proposal.imageLink,
        proposal.fundingGoal,
        proposal.amountRaised,
        proposal.startTime,
        proposal.endTime,
        proposal.fundingClosed,
        proposal.isRefunded,
        proposal.isUserCancelled
    );
}

function getFundingAddress(address _contributor) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    uint256 count = 0;

    // 펀딩된 정보의 개수 세기
    for (uint256 i = 0; i < proposals.length; i++) {
        if (contributions[i][_contributor].amount > 0) {
            count++;
        }
    }

    // 동적 배열 할당
    uint256[] memory proposalIds = new uint256[](count);
    uint256[] memory amounts = new uint256[](count);
    uint256[] memory timestamps = new uint256[](count);
    uint256 index = 0;

    // 값 채워 넣기
    for (uint256 i = 0; i < proposals.length; i++) {
        uint256 contributionAmount = contributions[i][_contributor].amount;
        uint256 contributionTimestamp = contributions[i][_contributor].timestamp;
        if (contributionAmount > 0) {
            proposalIds[index] = i;
            amounts[index] = contributionAmount;
            timestamps[index] = contributionTimestamp;
            index++;
        }
    }

    return (proposalIds, amounts, timestamps);
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
}