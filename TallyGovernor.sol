// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "daomarket/node_modules/@openzeppelin/contracts/governance/Governor.sol";
import "daomarket/node_modules/@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "daomarket/node_modules/@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "daomarket/node_modules/@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract MyGovernor is Governor, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    constructor(IVotes _token)
        Governor("MyGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 10; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 4581; // 1 week
    }
  
    function proposalThreshold() public pure override returns (uint256) {
        return 500;  // 제안 최소수량  
    }

    // The following functions are overrides required by Solidity.
    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }
}