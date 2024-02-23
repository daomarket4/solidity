// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "daomarket/node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "daomarket/node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface VotingContract {
    function getVoteResult(uint256 proposalIndex) external view returns (uint256 yesVotes, uint256 noVotes);
}

contract SaleContract {
    VotingContract public votingContract;
    mapping(address => uint256) public funds;

    constructor(address _votingContractAddress) {
        votingContract = VotingContract(_votingContractAddress);
    }

    // 판매를 실행
    function executeSale(uint256 proposalIndex, address _nftContractAddress, uint256 _tokenId) public {
        // 투표 결과
        (uint256 yesVotes, uint256 noVotes) = votingContract.getVoteResult(proposalIndex);
        
        // 투표 비율을 계산
        uint256 totalVotes = yesVotes + noVotes;
        uint256 yesPercentage = (yesVotes * 100) / totalVotes;

        // yes 비율이 50%를 초과하는지 확인
        require(yesPercentage > 50, "Not enough 'yes' votes to execute sale");

        //nft 판매
        IERC721 nftContract = IERC721(_nftContractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");
        
        // nft 전송
        nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    // 자금 분배 
    function distributeFunds(address payable[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Lengths of recipients and amounts arrays must be equal");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(funds[msg.sender] >= amounts[i], "Insufficient funds for distribution");

            funds[msg.sender] -= amounts[i];
            recipients[i].transfer(amounts[i]);
        }
    }
}
