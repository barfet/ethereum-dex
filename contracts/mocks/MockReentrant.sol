// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/Router.sol";
import "../interfaces/IPair.sol"; // Add this line to import the IPair interface

contract MockReentrant {
    Router public router; // Declare the router variable
    IPair public pair; // Declare the pair variable
    
    // {{ Declare tokenAAddress and tokenBAddress }}
    address public tokenAAddress;
    address public tokenBAddress;

    // {{ Update constructor to accept tokenA and tokenB addresses }}
    constructor(address pairAddress, address routerAddress) { // Modify constructor to accept 'routerAddress'
        pair = IPair(pairAddress);
        router = Router(routerAddress); // Initialize the router
    }

    fallback() external payable {
        if (address(router).balance >= 1 ether) {
            // Provide the required 5 parameters for swapExactTokensForTokens
            uint256 amountIn = 1 ether; // Example amount, adjust as needed
            uint256 amountOutMin = 1 ether; // Example minimum amount out
            address[] memory path = new address[](2);
            path[0] = tokenAAddress; // Replace with TokenA's deployed address
            path[1] = tokenBAddress; // Replace with TokenB's deployed address
            address to = address(this); // Address to receive the output tokens
            uint256 deadline = block.timestamp + 300; // 5 minutes from now

            router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        }
    }

    function attack() external {
        // Provide the required 5 parameters for swapExactTokensForTokens
        uint256 amountIn = 1 ether; // Example amount, adjust as needed
        uint256 amountOutMin = 1 ether; // Example minimum amount out
        address[] memory path = new address[](2);
        path[0] = tokenAAddress; // Replace with TokenA's deployed address
        path[1] = tokenBAddress; // Replace with TokenB's deployed address
        address to = address(this); // Address to receive the output tokens
        uint256 deadline = block.timestamp + 300; // 5 minutes from now

        router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    // Add a receive function to handle incoming Ether
    receive() external payable {}

    // Update the attackSwap function with correct parameters
    function attackSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    // Update the attackBurn function with correct parameters
    function attackBurn(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }
}