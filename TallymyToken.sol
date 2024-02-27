// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "daomarket/node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "daomarket/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "daomarket/node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract MyToken is ERC20, ERC20Permit, ERC20Votes {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    // function afterTokenTransfer(address from, address to, uint256 amount)
   //     internal
    
   // {
   //    _afterTokenTransfer(from, to, amount);
   // }

    function decimals() public pure override returns(uint8) {
        return 0;
    }

    function mint(address to, uint256 amount)
        public
    {
       _mint(to, amount);
    }

    function burn(address account, uint256 amount)
        internal    
    {
       _burn(account, amount);
    }
}