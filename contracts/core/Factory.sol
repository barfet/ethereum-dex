// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IFactory.sol";
import "../interfaces/IPair.sol";
import "../libraries/DexLibrary.sol";

/**
 * @title Factory
 * @dev Factory contract to create and manage Pair contracts
 */
contract Factory is IFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev Creates a new pair for the given two tokens
     */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "Factory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = DexLibrary.sortTokens(tokenA, tokenB);
        require(token0 != address(0), "Factory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Factory: PAIR_EXISTS"); // single check is sufficient

        bytes memory bytecode = type(Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev Sets the feeTo address
     */
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "Factory: FORBIDDEN");
        feeTo = _feeTo;
    }

    /**
     * @dev Sets the feeToSetter address
     */
    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "Factory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev Returns the number of all pairs
     */
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }
}