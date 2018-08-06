pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Merchant.sol";

contract TestMerchant {
    function testAddDevice() {
        Merchant merchant = Merchant(DeployedAddresses.Merchant());
        bool add_device = merchant.addDevice("ABC", "Raspberry PI 3");
        Assert.isTrue(add_device, "Failed to add device.");
    }

    function testAddAction() {
        Merchant merchant = Merchant(DeployedAddresses.Merchant());
        bool add_action = merchant.addAction("ABC", "Open", 20, 20, true);
        Assert.isTrue(add_action, "Failed to add action.");
    }

    function testEnableAction() {
        Merchant merchant = Merchant(DeployedAddresses.Merchant());
        bool enable_action = merchant.enableAction("ABC", 0);
        Assert.isTrue(enable_action, "Failed to enable action.");
    }

    function testDisableAction() {
        Merchant merchant = Merchant(DeployedAddresses.Merchant());
        bool disable_action = merchant.disableAction("ABC", 0);
        Assert.isTrue(disable_action, "Failed to disable action.");
    }

    function testRefund() {
        Merchant merchant = Merchant(DeployedAddresses.Merchant());
        bool refund = merchant.refund("ABC", 0, 0);
        Assert.isTrue(refund, "Failed to refund action.");
    }

    function testRefundAutomatic() {
        Merchant merchant = Merchant(DeployedAddresses.Merchant());
        bool refundAutomatic = merchant.refundAutomatic("ABC", 0, 0);
        Assert.isTrue(refundAutomatic, "Failed to automatically refund action.");
    }
}