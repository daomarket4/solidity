// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// ProposalAndFunding 컨트랙트와 상호작용하기 위한 인터페이스 선언
interface ProposalAndFunding {
    function getSuccessfulFundingDetails() external view returns (
        uint256[] memory proposalIds,
        address[] memory proposers,
        uint256[] memory totalFundingAmounts,
        address[][] memory contributors,
        uint256[][] memory fundingAmounts,
        uint256[] memory fundingTimes,
        uint256[] memory fundingShares
    );
}

// ERC1155 표준을 따르는 NFT 컨트랙트. 소유자 관리 및 SafeMath 사용
contract MintNFT is ERC1155, Ownable {
    using SafeMath for uint256;

    string public name; // 토큰 이름
    string public symbol; // 토큰 심볼
    uint256 constant TOTAL_NFT_SUPPLY = 1000; // NFT 총 공급량
    uint256 constant VOTING_POWER_PER_NFT = 1; // 각 NFT당 보팅파워 (0.1% 씩)

    // proposalID별로 기여한 금액을 저장하는 매핑
    mapping(uint256 => mapping(address => uint256)) public proposalFundingAmounts;
    // proposalID별 총 기여 금액을 저장하는 매핑
    mapping(uint256 => uint256) public totalFundedAmount;
    // proposalID별로 토큰 URI를 저장하는 매핑
    mapping(uint256 => string) private tokenURIs;
    // NFT가 발행되었는지 여부를 저장하는 매핑
    mapping(uint256 => bool) public isNftIssued;

    // 컨트랙트 생성자. 토큰 이름과 심볼을 초기화
    constructor(string memory _name, string memory _symbol, address initialOwner) ERC1155("") Ownable(initialOwner) {
        name = _name;
        symbol = _symbol;
    }

    // proposalID에 해당하는 토큰 URI 설정
    function setTokenURI(uint256 proposalID, string memory _tokenURI) public onlyOwner {
        tokenURIs[proposalID] = _tokenURI;
    }

    // 특정 proposalID에 대한 NFT 분배
    function mintNFT(uint256 proposalID) public onlyOwner {
        require(!isNftIssued[proposalID], "NFT already issued for this proposal");
        uint256 totalFunded = totalFundedAmount[proposalID];
        require(totalFunded > 0, "No funds for this proposal");

        address[] memory participants = getParticipants(proposalID);
        for (uint i = 0; i < participants.length; i++) {
            uint256 amountFunded = proposalFundingAmounts[proposalID][participants[i]];
            uint256 tokenAmount = (TOTAL_NFT_SUPPLY.mul(amountFunded)).div(totalFunded);
            _mint(participants[i], proposalID, tokenAmount, "");
        }

        isNftIssued[proposalID] = true; // NFT가 발행되었음을 표시
    }

    // tokenId에 해당하는 토큰 URI 반환
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(bytes(tokenURIs[tokenId]).length > 0, "URI not set");
        return tokenURIs[tokenId];
    }

    // 특정 proposalID에 대한 기여자 목록 반환
    function getParticipants(uint256 proposalID) internal view returns (address[] memory) {
        // 이 함수는 주어진 proposalID에 대한 기여자 목록을 반환해야 합니다.
        // 구체적인 기여자 주소 관리 방식에 따라 구현되어야 합니다.
    }

    // ProposalAndFunding 컨트랙트를 통해 성공적으로 모금된 내역을 반환하는 함수
    function getSuccessfulFundingDetails() public view returns (
        uint256[] memory proposalIds,
        address[] memory proposers,
        uint256[] memory totalFundingAmounts,
        address[][] memory contributors,
        uint256[][] memory fundingAmounts,
        uint256[] memory fundingTimes,
        uint256[] memory fundingShares
    ) {
        ProposalAndFunding proposalAndFunding = ProposalAndFunding(address(0x915bE544824b5F4786809358ccf63439A81a599b));
        return proposalAndFunding.getSuccessfulFundingDetails();
    }
    // 튜표파워 반환
    // 튜표파워 반환
function getVotingPower(address account) public view returns (uint256) {
    uint256 totalPower = 0;
    for (uint256 i = 0; i < balanceOf(account, 0); i++) {
        totalPower = totalPower.add(VOTING_POWER_PER_NFT);
    }
    return totalPower;
}
}
