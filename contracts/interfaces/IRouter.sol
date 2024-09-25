// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRouter
 * @dev Interface for the Router contract, which handles token swaps and liquidity operations
 * This interface defines the core functionality for interacting with the DEX
 */
interface IRouter {
    /**
     * @dev Returns the address of the factory contract
     * The factory is responsible for creating and managing token pairs
     */
    function factory() external view returns (address);

    /**
     * @dev Returns the address of the Wrapped Ether (WETH) contract
     * WETH is used for ETH <-> ERC20 swaps
     */
    function WETH() external view returns (address);

    /**
     * @dev Adds liquidity to a token pair
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param amountADesired Desired amount of tokenA to add as liquidity
     * @param amountBDesired Desired amount of tokenB to add as liquidity
     * @param amountAMin Minimum amount of tokenA to add as liquidity
     * @param amountBMin Minimum amount of tokenB to add as liquidity
     * @param to Address that will receive the liquidity tokens
     * @param deadline Timestamp after which the transaction will revert
     * @return amountA The amount of tokenA actually added as liquidity
     * @return amountB The amount of tokenB actually added as liquidity
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
    ) external returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @dev Removes liquidity from a token pair
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param liquidity Amount of liquidity tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive
     * @param amountBMin Minimum amount of tokenB to receive
     * @param to Address that will receive the withdrawn tokens
     * @param deadline Timestamp after which the transaction will revert
     * @return amountA The amount of tokenA received
     * @return amountB The amount of tokenB received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (
        uint256 amountA,
        uint256 amountB
    );

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens as possible
     * @param amountIn The amount of input tokens to send
     * @param amountOutMin The minimum amount of output tokens to receive
     * @param path An array of token addresses representing the swap path
     * @param to Address that will receive the output tokens
     * @param deadline Timestamp after which the transaction will revert
     * @return amounts An array of amounts for each swap in the path
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @dev Swaps tokens for an exact amount of output tokens
     * @param amountOut The amount of output tokens to receive
     * @param amountInMax The maximum amount of input tokens to send
     * @param path An array of token addresses representing the swap path
     * @param to Address that will receive the output tokens
     * @param deadline Timestamp after which the transaction will revert
     * @return amounts An array of amounts for each swap in the path
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}