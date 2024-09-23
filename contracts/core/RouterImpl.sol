// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Router.sol";

/**
 * @title RouterImpl
 * @dev Concrete implementation of the Router contract for testing purposes
 */
contract RouterImpl is Router {
    constructor(address _factory, address _WETH) Router(_factory, _WETH) {
        // No additional implementation needed if Router is fully implemented
    }

    // Implement any remaining abstract methods if necessary
}