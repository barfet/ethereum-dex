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
            100 ether,                        // amountIn
            90 ether,                         // amountOutMin
            new address[](2),                  // path
            address(this),                    // to
            block.timestamp + 1200             // deadline
        );
    }

    // Fallback function to perform reentrancy
    fallback() external payable {
        if (attackInitiated) {
            router.swapExactTokensForTokens(
                100 ether,                        // amountIn
                90 ether,                         // amountOutMin
                new address[](2),                  // path
                address(this),                    // to
                block.timestamp + 1200             // deadline
            );
        }
    }

    // Add receive function to handle plain ether transfers
    receive() external payable {}
}