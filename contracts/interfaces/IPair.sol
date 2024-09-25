// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IPair
 * @dev Interface for the Pair contract, representing a liquidity pair in a DEX
 * This interface extends IERC20, indicating that the pair itself is also a token (LP token)
 */
interface IPair is IERC20 {
    /**
     * @dev Emitted when liquidity is added to the pair
     * @param sender Address of the liquidity provider
     * @param amount0 Amount of token0 added
     * @param amount1 Amount of token1 added
     */
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /**
     * @dev Emitted when liquidity is removed from the pair
     * @param sender Address of the liquidity remover
     * @param amount0 Amount of token0 removed
     * @param amount1 Amount of token1 removed
     * @param to Address receiving the removed tokens
     */
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @dev Emitted when a swap occurs in the pair
     * @param sender Address initiating the swap
     * @param amount0In Amount of token0 input
     * @param amount1In Amount of token1 input
     * @param amount0Out Amount of token0 output
     * @param amount1Out Amount of token1 output
     * @param to Address receiving the output tokens
     */
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @dev Emitted when the reserves of the pair are synchronized
     * @param reserve0 New reserve of token0
     * @param reserve1 New reserve of token1
     */
    event Sync(uint112 reserve0, uint112 reserve1);

    /**
     * @dev Returns the address of the first token in the pair
     */
    function token0() external view returns (address);

    /**
     * @dev Returns the address of the second token in the pair
     */
    function token1() external view returns (address);

    /**
     * @dev Returns the current reserves of the pair and the timestamp of the last update
     * @return reserve0 Current reserve of token0
     * @return reserve1 Current reserve of token1
     * @return blockTimestampLast Timestamp of the last update
     */
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    /**
     * @dev Initializes the pair with the addresses of the two tokens
     * @param _token0 Address of the first token
     * @param _token1 Address of the second token
     */
    function initialize(address _token0, address _token1) external;

    /**
     * @dev Mints liquidity tokens to the provider
     * @param to Address receiving the minted liquidity tokens
     * @return liquidity Amount of liquidity tokens minted
     */
    function mint(address to) external returns (uint256 liquidity);

    /**
     * @dev Burns liquidity tokens and returns the underlying assets
     * @param to Address receiving the underlying assets
     * @return amount0 Amount of token0 returned
     * @return amount1 Amount of token1 returned
     */
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /**
     * @dev Executes a swap on the pair
     * @param amount0Out Amount of token0 to output
     * @param amount1Out Amount of token1 to output
     * @param to Address receiving the output tokens
     * @param data Additional data for flash loans (if supported)
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /**
     * @dev Forces balances to match reserves
     * @param to Address receiving any excess tokens
     */
    function skim(address to) external;

    /**
     * @dev Forces reserves to match balances
     */
    function sync() external;
}