// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "lib/balancer-v2-monorepo/pkg/solidity-utils/contracts/openzeppelin/ERC20.sol";

contract MyToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function burn(address form, uint256 amount) public virtual {
        _burn(form, amount);
    }
}
