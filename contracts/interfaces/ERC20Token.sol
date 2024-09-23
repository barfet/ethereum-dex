// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Token
 * @dev Implementation of the ERC20 Token standard with customizable decimals
 */
contract ERC20Token is ERC20 {
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol}, {decimals}, and mints an initial supply to the deployer.
     *
     * All four of these values are immutable: they can only be set once during construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Overrides the decimals function to return the custom decimals value.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}