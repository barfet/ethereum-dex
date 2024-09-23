// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";
import "../libraries/DexLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Router
 * @dev Router contract to facilitate token swaps and liquidity management
 */
contract Router is IRouter, ReentrancyGuard {
    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(block.timestamp <= deadline, "Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @dev Adds liquidity to a pair
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    ) {
        address pair = DexLibrary.pairFor(factory, tokenA, tokenB);
        IERC20(tokenA).transferFrom(msg.sender, pair, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountBDesired);
        liquidity = IPair(pair).mint(to);
        amountA = amountADesired;
        amountB = amountBDesired;
        // Handle slippage and adjust amounts if necessary
    }

    /**
     * @dev Removes liquidity from a pair
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (
        uint256 amountA,
        uint256 amountB
    ) {
        address pair = DexLibrary.pairFor(factory, tokenA, tokenB);
        IPair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB) = IPair(pair).burn(to);
        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
    }

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens as possible
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = _getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20(path[0]).transferFrom(msg.sender, DexLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    /**
     * @dev Swaps tokens to receive an exact amount of output tokens
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = _getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        IERC20(path[0]).transferFrom(msg.sender, DexLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    /**
     * @dev Internal function to execute swaps along the path
     */
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = DexLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            uint256 amount0Out = input == token0 ? 0 : amountOut;
            uint256 amount1Out = input == token0 ? amountOut : 0;
            address to = i < path.length - 2 ? DexLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IPair(DexLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @dev Calculates the amounts out for a given input amount and path
     */
    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "Router: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint112 reserveIn, uint112 reserveOut) = DexLibrary.getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = DexLibrary.getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @dev Calculates the amounts in required to obtain a specific output amount and path
     */
    function _getAmountsIn(uint256 amountOut, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "Router: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint112 reserveIn, uint112 reserveOut) = DexLibrary.getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = DexLibrary.getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}