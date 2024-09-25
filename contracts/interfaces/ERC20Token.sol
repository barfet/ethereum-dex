// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Token
 * @dev Implementation of the ERC20 Token standard with customizable decimals
 * This contract extends OpenZeppelin's ERC20 implementation, allowing for
 * a configurable number of decimal places for token amounts.
 */
contract ERC20Token is ERC20 {
    // The number of decimal places for token amounts
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol}, {decimals}, and mints an initial supply to the deployer.
     *
     * All four of these values are immutable: they can only be set once during construction.
     * @param name The name of the token
     * @param symbol The symbol (ticker) of the token
     * @param decimals_ The number of decimal places for token amounts
     * @param initialSupply The initial amount of tokens to mint to the contract deployer
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        // Set the custom number of decimal places
        _decimals = decimals_;
        // Mint the initial supply to the contract deployer (msg.sender)
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Overrides the decimals function to return the custom decimals value.
     * This allows for flexibility in token precision beyond the default 18 decimals.
     * @return The number of decimal places for this token
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}