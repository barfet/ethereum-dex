// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";
import "../libraries/DexLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Router
 * @dev Router contract to facilitate token swaps and liquidity management in a decentralized exchange
 * This contract handles the core functionality of adding/removing liquidity and executing token swaps
 */
contract Router is IRouter, ReentrancyGuard {
    address public immutable override factory;
    address public immutable override WETH;

    /**
     * @dev Ensures that the transaction is executed before the deadline
     * @param deadline The timestamp by which the transaction must be executed
     */
    modifier ensure(uint256 deadline) {
        require(block.timestamp <= deadline, "Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @dev Adds liquidity to a token pair
     * @notice This function transfers tokens from the user to the pair contract and mints liquidity tokens
     * @param tokenA The address of the first token in the pair
     * @param tokenB The address of the second token in the pair
     * @param amountADesired The amount of tokenA the user wishes to add as liquidity
     * @param amountBDesired The amount of tokenB the user wishes to add as liquidity
     * @param amountAMin The minimum amount of tokenA to add (slippage protection)
     * @param amountBMin The minimum amount of tokenB to add (slippage protection)
     * @param to The address that will receive the liquidity tokens
     * @param deadline The timestamp by which the transaction must be executed
     * @return amountA The actual amount of tokenA added as liquidity
     * @return amountB The actual amount of tokenB added as liquidity
     * @return liquidity The amount of liquidity tokens minted
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
    ) external override nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        address pair = DexLibrary.pairFor(factory, tokenA, tokenB);
        IERC20(tokenA).transferFrom(msg.sender, pair, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountBDesired);
        liquidity = IPair(pair).mint(to);
        amountA = amountADesired;
        amountB = amountBDesired;
        // TODO: Implement slippage protection and amount adjustment logic
    }

    /**
     * @dev Removes liquidity from a token pair
     * @notice This function burns liquidity tokens and returns the underlying assets to the user
     * @param tokenA The address of the first token in the pair
     * @param tokenB The address of the second token in the pair
     * @param liquidity The amount of liquidity tokens to burn
     * @param amountAMin The minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin The minimum amount of tokenB to receive (slippage protection)
     * @param to The address that will receive the underlying tokens
     * @param deadline The timestamp by which the transaction must be executed
     * @return amountA The amount of tokenA returned to the user
     * @return amountB The amount of tokenB returned to the user
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
     * @notice This function calculates the optimal swap path and executes the swap
     * @param amountIn The amount of input tokens to swap
     * @param amountOutMin The minimum amount of output tokens to receive (slippage protection)
     * @param path An array of token addresses representing the swap path
     * @param to The address that will receive the output tokens
     * @param deadline The timestamp by which the transaction must be executed
     * @return amounts An array of token amounts for each step in the swap path
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
     * @notice This function calculates the required input amount and executes the swap
     * @param amountOut The exact amount of output tokens to receive
     * @param amountInMax The maximum amount of input tokens to spend (slippage protection)
     * @param path An array of token addresses representing the swap path
     * @param to The address that will receive the output tokens
     * @param deadline The timestamp by which the transaction must be executed
     * @return amounts An array of token amounts for each step in the swap path
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
     * @notice This function performs the actual token swaps by interacting with pair contracts
     * @param amounts An array of token amounts for each step in the swap path
     * @param path An array of token addresses representing the swap path
     * @param _to The final recipient of the swapped tokens
     */
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = DexLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? DexLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IPair(DexLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @dev Calculates the amounts out for a given input amount and path
     * @notice This function uses the current reserves of each pair to calculate the output amounts
     * @param amountIn The input amount of the first token in the path
     * @param path An array of token addresses representing the swap path
     * @return amounts An array of token amounts for each step in the swap path
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
     * @notice This function uses the current reserves of each pair to calculate the input amounts
     * @param amountOut The desired output amount of the last token in the path
     * @param path An array of token addresses representing the swap path
     * @return amounts An array of token amounts for each step in the swap path
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