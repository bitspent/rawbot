pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Rawbot.sol";

contract TestRawbot {
    Rawbot rawbot;

    constructor() {
        rawbot = Rawbot(DeployedAddresses.Rawbot());
    }

    function testGetInitialCoins() {
        uint expected = 4000000;
        Assert.equal(rawbot.getBalance(tx.origin), expected, "Owner should have 4000000 MetaCoin initially");
    }

    function testWithdrawCoins(){
        uint coins = 1000;
        bool withdrawn = rawbot.withdraw(coins);
        Assert.isTrue(withdrawn, "Failed to withdraw ETH");
    }

    function testAllowedToExchange(){
        Assert.isTrue(rawbot.getExchangeLeftOf(msg.sender) > 0, "User has zero raw coins to exchange.");
    }

    function testAllowedToExchangeValue(){
        uint value = 10000;
        Assert.isTrue(rawbot.getExchangeLeftOf(msg.sender) >= value, "User has less raw coins to exchange than the value allowed.");
    }

    function testBalanceMoreThanValueToExchange(){
        uint value = 10000;
        Assert.isTrue(rawbot.getBalance(msg.sender) >= value, "User has less raw coins than the value requested.");
    }
}