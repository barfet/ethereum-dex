// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPair.sol";
import "../libraries/DexLibrary.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Pair
 * @dev Pair contract to handle swaps and liquidity for a specific token pair
 */
contract Pair is ERC20, IPair, ReentrancyGuard {
    using SafeMath for uint256;

    address public override token0;
    address public override token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;
    uint32  private blockTimestampLast;

    bool private initialized;

    constructor() ERC20("LP Token", "LP") {
        // Empty constructor to prevent unwanted initializations
    }

    /**
     * @dev Initializes the pair with two tokens
     */
    function initialize(address _token0, address _token1) external {
        require(!initialized, "Pair: ALREADY_INITIALIZED");
        token0 = _token0;
        token1 = _token1;
        initialized = true;
    }

    /**
     * @dev Returns the current reserves of the pair
     */
    function getReserves() public view override returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    /**
     * @dev Updates the reserves based on the current balances
     */
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "Pair: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /**
     * @dev Mints liquidity tokens to the provider
     */
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        if (totalSupply() == 0) {
            liquidity = sqrt(amount0 * amount1);
            require(liquidity > 0, "Insufficient liquidity minted");
            _mint(address(0), 1000); // minimum liquidity
        } else {
            liquidity = min((amount0 * totalSupply()) / _reserve0, (amount1 * totalSupply()) / _reserve1);
            require(liquidity > 0, "Insufficient liquidity minted");
        }

        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @dev Burns liquidity tokens and returns underlying tokens to the provider
     */
    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint liquidity = balanceOf(msg.sender);
        require(liquidity > 0, "Pair: INSUFFICIENT_LIQUIDITY_BURNED");
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint amount0Optimal = (liquidity * _reserve0) / totalSupply();
        uint amount1Optimal = (liquidity * _reserve1) / totalSupply();
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

        require(amount0 > 0 && amount1 > 0, "Pair: INSUFFICIENT_LIQUIDITY_BURNED");
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
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "Pair: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "Pair: INSUFFICIENT_LIQUIDITY");

        uint balance0;
        uint balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            if (amount0Out > 0) IERC20(_token0).transfer(to, amount0Out);
            if (amount1Out > 0) IERC20(_token1).transfer(to, amount1Out);
            if (data.length > 0) IPair(to).swap(amount0Out, amount1Out, to, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > (_reserve0 - amount0Out) ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > (_reserve1 - amount1Out) ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "Pair: INSUFFICIENT_INPUT_AMOUNT");

        {
            uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
            uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
            require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * uint(_reserve1) * (1000**2), "Pair: K");
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @dev Skims any excess tokens to the specified address
     */
    function skim(address to) external nonReentrant {
        address _token0 = token0;
        address _token1 = token1;
        IERC20(_token0).transfer(to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        IERC20(_token1).transfer(to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    /**
     * @dev Synchronizes the reserves with actual balances
     */
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    /**
     * @dev Internal function to mint liquidity tokens
     */
    function _mint(address to, uint256 liquidity) internal override {
        super._mint(to, liquidity);
        emit Transfer(address(0), to, liquidity);
    }

    /**
     * @dev Internal function to burn liquidity tokens
     */
    function _burn(address from, uint256 liquidity) internal override {
        super._burn(from, liquidity);
        emit Transfer(from, address(0), liquidity);
    }

    /**
     * @dev Returns the square root of a number
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Returns the minimum of two numbers
     */
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}