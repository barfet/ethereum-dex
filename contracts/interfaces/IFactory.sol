// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IFactory
 * @dev Interface for the Factory contract in a decentralized exchange (DEX) system.
 * This contract is responsible for creating and managing trading pairs.
 */
interface IFactory {
    /**
     * @dev Emitted when a new trading pair is created.
     * @param token0 The address of the first token in the pair.
     * @param token1 The address of the second token in the pair.
     * @param pair The address of the newly created pair contract.
     * @param The fourth parameter is likely the total number of pairs after creation (unnamed in the event).
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    /**
     * @dev Returns the address that receives the protocol fees.
     * @return The address of the fee recipient.
     */
    function feeTo() external view returns (address);

    /**
     * @dev Returns the address that has the authority to change the fee recipient.
     * @return The address of the fee setter.
     */
    function feeToSetter() external view returns (address);

    /**
     * @dev Retrieves the address of a trading pair for two given tokens.
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * @return pair The address of the trading pair contract, or zero address if it doesn't exist.
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @dev Returns the address of a trading pair by its index.
     * @param index The index of the pair in the allPairs array.
     * @return pair The address of the trading pair contract at the given index.
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @dev Returns the total number of trading pairs created by the factory.
     * @return The length of the allPairs array.
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @dev Creates a new trading pair for two given tokens.
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * @return pair The address of the newly created trading pair contract.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @dev Sets the address that will receive the protocol fees.
     * @param newFeeTo The new address to receive fees.
     */
    function setFeeTo(address newFeeTo) external;

    /**
     * @dev Sets the address that has the authority to change the fee recipient.
     * @param newFeeToSetter The new address with the authority to set fees.
     */
    function setFeeToSetter(address newFeeToSetter) external;
}