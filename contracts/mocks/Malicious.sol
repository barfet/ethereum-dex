// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPair.sol";

/**
 * @title Malicious
 * @dev Contract to attempt re-entrant calls to Pair contract for testing reentrancy protections
 */
contract Malicious {
    IPair public pair;

    constructor(address pairAddress) {
        pair = IPair(pairAddress);
    }

    /**
     * @dev Attempts to perform a re-entrant swap
     */
    function attemptReentrancySwap() external {
        // Attempt to call swap again within the swap function
        pair.swap(
            0,
            1, // Attempt to withdraw 1 token
            address(this),
            ""
        );
    }
}