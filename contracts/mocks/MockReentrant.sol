// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/Router.sol";

contract MaliciousReentrant {
    Router public router;
    bool public attackInitiated;

    constructor(address _router) {
        router = Router(_router);
    }

    function attack() external {
        require(!attackInitiated, "Attack already initiated");
        attackInitiated = true;
        router.swapExactTokensForTokens(
            address(this),
            address(0),
            100 ether,
            90 ether,
            address(this),
            block.timestamp + 1200
        );
    }

    // Fallback function to perform reentrancy
    fallback() external payable {
        if (attackInitiated) {
            router.swapExactTokensForTokens(
                address(this),
                address(0),
                100 ether,
                90 ether,
                address(this),
                block.timestamp + 1200
            );
        }
    }
}