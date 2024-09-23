// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals_, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _setupDecimals(decimals_);
    }

    // Optional: Override decimals if necessary
    function _setupDecimals(uint8 decimals_) internal {
        // Implementation if using OpenZeppelin versions that support decimals setup
    }
}