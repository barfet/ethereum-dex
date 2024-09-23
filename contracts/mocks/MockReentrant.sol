// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/Router.sol";

contract MockReentrant {
    Router public router;

    constructor(address _router) {
        router = Router(_router);
    }

    fallback() external payable {
        if (address(router).balance >= 1 ether) {
            router.swapExactTokensForTokens(/* parameters */);
        }
    }

    function attack() external {
        router.swapExactTokensForTokens(/* parameters */);
    }
}