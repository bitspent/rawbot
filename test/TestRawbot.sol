pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Rawbot.sol";

contract TestRawbot {
    Rawbot rawbot;
    Merchant merchant;
    MerchantManager merchant_manager;

    constructor() {
        rawbot = Rawbot(DeployedAddresses.Rawbot());
        merchant_manager = MerchantManager(DeployedAddresses.MerchantManager());
        merchant = Merchant(DeployedAddresses.Merchant());
    }

    function testGetInitialCoins() {
        uint expected = 4000000;
        Assert.equal(rawbot.getBalance(tx.origin), expected, "Owner should have 4000000 MetaCoin initially");
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

    function testEthereumPrice(){
        Assert.equal(rawbot.getEthereumPrice(), 500, "Ethereum price isn't equal 500");
    }

    //    function testSetContractManager() {
    //        Assert.isTrue(rawbot.setContractMerchantManager(merchant_manager), "User doesn't have privileges.");
    //    }

    function testAddMerchant() public {
        //        Assert.isTrue(, "Failed to add merchant");
        merchant = Merchant(merchant_manager.addMerchant());
    }

    function testMerchantsAmount() public {
        Assert.isTrue(merchant_manager.getMerchants() > 0, "Amount of merchants equals zero.");
    }

    function testAddDevice() {
        bool add_device = merchant.addDevice("ABC", "Raspberry PI 3");
        Assert.isTrue(add_device, "Failed to add device.");
    }

    function testAddAction() {
        bool add_action = merchant.addAction("ABC", "Open", 20, 20, true);
        Assert.isTrue(add_action, "Failed to add action.");
    }

    function testEnableAction() {
        bool enable_action = merchant.enableAction("ABC", 0);
        Assert.isTrue(enable_action, "Failed to enable action.");
    }

    function testDisableAction() {
        bool disable_action = merchant.disableAction("ABC", 0);
        Assert.isTrue(disable_action, "Failed to disable action.");
    }

    function testAddRecurringAction() {
        bool add_action = merchant.addRecurringAction("ABC", "Open", 20, 20, true);
        Assert.isTrue(add_action, "Failed to add recurring action.");
    }

    function testEnableRecurringAction() {
        bool enable_action = merchant.enableRecurringAction("ABC", 0);
        Assert.isTrue(enable_action, "Failed to enable recurring action.");
    }

    function testDisableRecurringAction() {
        bool disable_action = merchant.disableRecurringAction("ABC", 0);
        Assert.isTrue(disable_action, "Failed to disabled recurring action.");
    }

    function testRefund() {
        bool refund = merchant.refund("ABC", 0, 0);
        Assert.isTrue(refund, "Failed to refund action.");
    }

    function testRefundAutomatic() {
        bool refundAutomatic = merchant.refundAutomatic("ABC", 0, 0);
        Assert.isTrue(refundAutomatic, "Failed to automatically refund action.");
    }

    function testAddHash() {
        bool addHash = merchant.addImageHash("abcdefg");
        Assert.isTrue(addHash, "Failed to add IPFS hash.");
    }
}