pragma solidity ^0.4.24;

import "./StandardToken.sol";

contract Rawbot is StandardToken {

    constructor() StandardToken(20000000, "Rawbot Test 1", "RWT") public payable {
        price_status = PRICE_CHECKING_STATUS.NEEDED;
        // initEthereumPrice();
    }
}