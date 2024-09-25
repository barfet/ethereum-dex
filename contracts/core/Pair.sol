// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPair.sol";
import "../libraries/DexLibrary.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

using SafeMath for uint256;

/**
 * @title Pair
 * @dev Pair contract to handle swaps and liquidity for a specific token pair
 * This contract implements the core functionality of a decentralized exchange (DEX) pair,
 * including liquidity provision, token swaps, and fee collection.
 */
contract Pair is ERC20, IPair, ReentrancyGuard {
    address public override token0;
    address public override token1;

    // These variables use a single storage slot for gas efficiency
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    // Constants for fee calculation and minimum liquidity
    uint256 private constant FEE_NUMERATOR = 997; // Represents a 0.3% fee (1000 - 997 = 3)
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    constructor() ERC20("LP Token", "LP") {
        // Empty constructor to prevent unwanted initializations
    }

    /**
     * @dev Initializes the pair with two tokens
     * @param _token0 Address of the first token
     * @param _token1 Address of the second token
     */
    function initialize(address _token0, address _token1) external override {
        require(
            token0 == address(0) && token1 == address(0),
            "Pair: ALREADY_INITIALIZED"
        );
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @dev Returns the current reserves of the pair and the last block timestamp
     * @return reserve0 The current reserve of token0
     * @return reserve1 The current reserve of token1
     * @return blockTimestampLast The timestamp of the last block when reserves were updated
     */
    function getReserves()
        public
        view
        override
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reserve0, reserve1, blockTimestampLast);
    }

    /**
     * @dev Updates the reserves based on the current balances
     * @param balance0 The new balance of token0
     * @param balance1 The new balance of token1
     * @param _reserve0 The old reserve of token0 (unused)
     * @param _reserve1 The old reserve of token1 (unused)
     */
    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "Pair: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /**
     * @dev Mints liquidity tokens to the provider
     * @param to Address to receive the minted liquidity tokens
     * @return liquidity Amount of liquidity tokens minted
     */
    function mint(address to)
        external
        override
        nonReentrant
        returns (uint256 liquidity)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;    

        if (totalSupply() == 0) {
            // Initial liquidity provision
            liquidity = DexLibrary.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            require(
                liquidity > 0,
                "Pair: INSUFFICIENT_LIQUIDITY_MINTED"
            );
            _mint(address(this), MINIMUM_LIQUIDITY); // Lock minimum liquidity to prevent division by zero
        } else {
            // Subsequent liquidity provisions
            liquidity = DexLibrary.min(
                (amount0 * totalSupply()) / _reserve0,
                (amount1 * totalSupply()) / _reserve1
            );
            require(
                liquidity > 0,
                "Pair: INSUFFICIENT_LIQUIDITY_MINTED"
            );
        }

        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @dev Burns liquidity tokens and returns underlying tokens to the provider
     * @param to Address to receive the underlying tokens
     * @return amount0 Amount of token0 returned
     * @return amount1 Amount of token1 returned
     */
    function burn(address to)
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint liquidity = balanceOf(msg.sender);
        require(
            liquidity > 0,
            "Pair: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint amount0Optimal = (liquidity * _reserve0) / totalSupply();
        uint amount1Optimal = (liquidity * _reserve1) / totalSupply();
        
        // Determine the actual amounts to be returned based on available balances
        if (amount0Optimal > balance0) {
            amount1 = (liquidity * _reserve1) / totalSupply();
            amount0 = balance0;
        } else if (amount1Optimal > balance1) {
            amount0 = (liquidity * _reserve0) / totalSupply();
            amount1 = balance1;
        } else {
            amount0 = amount0Optimal;
            amount1 = amount1Optimal;
        }

        require(
            amount0 > 0 && amount1 > 0,
            "Pair: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        super._burn(msg.sender, liquidity);
        IERC20(_token0).transfer(to, amount0);
        IERC20(_token1).transfer(to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /**
     * @dev Swaps tokens within the pair
     * @param amount0Out Amount of token0 to be sent out
     * @param amount1Out Amount of token1 to be sent out
     * @param to Address to receive the swapped tokens
     * @param data Additional data for flash swaps (if any)
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "Pair: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Pair: INSUFFICIENT_LIQUIDITY"
        );

        // Transfer tokens to 'to' address
        if (amount0Out > 0) {
            IERC20(token0).transfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            IERC20(token1).transfer(to, amount1Out);
        }

        uint balance0;
        uint balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            if (data.length > 0)
                IPair(to).swap(amount0Out, amount1Out, to, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        (uint256 amount0In, uint256 amount1In) = _calculateAmountsIn(
            _reserve0,
            _reserve1,
            amount0Out,
            amount1Out,
            balance0,
            balance1
        );
        require(
            amount0In > 0 || amount1In > 0,
            "Pair: INSUFFICIENT_INPUT_AMOUNT"
        );

        _validateInvariant(
            _reserve0,
            _reserve1,
            balance0,
            balance1,
            amount0In,
            amount1In
        );

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(
            msg.sender,
            amount0In,
            amount1In,
            amount0Out,
            amount1Out,
            to
        );
    }

    /**
     * @dev Calculates the input amounts based on reserves and output amounts
     * @param _reserve0 Current reserve of token0
     * @param _reserve1 Current reserve of token1
     * @param amount0Out Amount of token0 to be sent out
     * @param amount1Out Amount of token1 to be sent out
     * @param balance0 New balance of token0 after swap
     * @param balance1 New balance of token1 after swap
     * @return amount0In Amount of token0 received
     * @return amount1In Amount of token1 received
     */
    function _calculateAmountsIn(
        uint112 _reserve0,
        uint112 _reserve1,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 balance0,
        uint256 balance1
    ) internal pure returns (uint256 amount0In, uint256 amount1In) {
        amount0In = balance0 > (_reserve0 - amount0Out) ? balance0 - (_reserve0 - amount0Out) : 0;
        amount1In = balance1 > (_reserve1 - amount1Out) ? balance1 - (_reserve1 - amount1Out) : 0;
    }

    /**
     * @dev Validates the constant product invariant after swap
     * Ensures that the product of adjusted balances is greater than or equal to the product of reserves
     * This check maintains the price curve and prevents manipulation
     */
    function _validateInvariant(
        uint112 _reserve0,
        uint112 _reserve1,
        uint256 balance0,
        uint256 balance1,
        uint256 amount0In,
        uint256 amount1In
    ) internal view {
        uint256 balance0Adjusted = balance0.mul(FEE_DENOMINATOR).sub(amount0In.mul(FEE_NUMERATOR));
        uint256 balance1Adjusted = balance1.mul(FEE_DENOMINATOR).sub(amount1In.mul(FEE_NUMERATOR));

        require(
            balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(uint(_reserve1)).mul(FEE_DENOMINATOR**2),
            "Pair: K"
        );
    }

    /**
     * @dev Skims any excess tokens to the specified address
     * This function can be used to recover any tokens sent to the contract by mistake
     * @param to Address to receive the excess tokens
     */
    function skim(address to) external override nonReentrant {
        address _token0 = token0;
        address _token1 = token1;
        IERC20(_token0).transfer(
            to,
            IERC20(_token0).balanceOf(address(this)) - reserve0
        );
        IERC20(_token1).transfer(
            to,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    /**
     * @dev Synchronizes the reserves with actual balances
     * This function can be called to ensure the contract's state matches its actual token balances
     */
    function sync() external override nonReentrant {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    /**
     * @dev Internal function to mint liquidity tokens
     * @param to Address to receive the minted tokens
     * @param liquidity Amount of liquidity tokens to mint
     */
    function _mint(address to, uint256 liquidity) internal override {
        require(
            to != address(0),
            "ERC20: mint to the zero address"
        );
        super._mint(to, liquidity);
        emit Transfer(address(0), to, liquidity);
    }

    /**
     * @dev Internal function to burn liquidity tokens
     * @param from Address from which to burn tokens
     * @param liquidity Amount of liquidity tokens to burn
     */
    function _burn(address from, uint256 liquidity) internal override {
        require(
            from != address(0),
            "ERC20: burn from the zero address"
        );
        super._burn(from, liquidity);
        emit Transfer(from, address(0), liquidity);
    }

    /**
     * @dev Returns the fee applied to swaps
     * @return The fee numerator, representing a 0.3% fee
     */
    function getFee() external view returns (uint256) {
        return FEE_NUMERATOR; // Represents a 0.3% fee
    }
}