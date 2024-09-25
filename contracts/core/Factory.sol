// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IFactory.sol";
import "../interfaces/IPair.sol";
import "../libraries/DexLibrary.sol";
import "../core/Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Factory
 * @dev Factory contract to create and manage Pair contracts for a decentralized exchange
 * This contract is responsible for creating new trading pairs and managing fees
 */
contract Factory is IFactory {
    // Address where fees are sent
    address public override feeTo;
    // Address allowed to change the fee recipient
    address public override feeToSetter;

    // Mapping to store created pairs: token0 address => token1 address => pair address
    mapping(address => mapping(address => address)) public override getPair;
    // Array to store all created pair addresses
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev Creates a new pair for the given two tokens
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return pair Address of the newly created pair contract
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Factory: IDENTICAL_ADDRESSES");
        // Sort tokens to ensure consistent pair addresses regardless of token order
        (address token0, address token1) = DexLibrary.sortTokens(tokenA, tokenB);
        require(token0 != address(0), "Factory: ZERO_ADDRESS");
        // Check if the pair already exists
        require(getPair[token0][token1] == address(0), "Factory: PAIR_EXISTS");

        // Generate bytecode for the new Pair contract
        bytes memory bytecode = type(Pair).creationCode;
        // Create a unique salt for the CREATE2 opcode
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // Use assembly to deploy the new Pair contract using CREATE2
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // Initialize the newly created pair
        IPair(pair).initialize(token0, token1);
        // Store the pair address in the mapping (both directions)
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        // Add the new pair to the allPairs array
        allPairs.push(pair);
        // Emit an event to notify listeners about the new pair
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev Sets the feeTo address (where fees are sent)
     * @param _feeTo New address to receive fees
     */
    function setFeeTo(address _feeTo) external override {
        // Only the feeToSetter can change the fee recipient
        require(msg.sender == feeToSetter, "Factory: FORBIDDEN");
        feeTo = _feeTo;
    }

    /**
     * @dev Sets the feeToSetter address (who can change the fee recipient)
     * @param _feeToSetter New address allowed to set the fee recipient
     */
    function setFeeToSetter(address _feeToSetter) external override {
        // Only the current feeToSetter can change the feeToSetter
        require(msg.sender == feeToSetter, "Factory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev Returns the number of all pairs created by this factory
     * @return The total number of pairs
     */
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }
}