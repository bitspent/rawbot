pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Rawbot.sol";
import "../contracts/Device.sol";
import "../contracts/DeviceManager.sol";

contract TestRawbot {
    Rawbot rawbot;
    Device device;
    DeviceManager device_manager;

    constructor() public {
        rawbot = Rawbot(DeployedAddresses.Rawbot());
        device_manager = DeviceManager(DeployedAddresses.DeviceManager());
        device = Device(DeployedAddresses.Device());
    }

    function testGetInitialCoins() public {
        uint expected = 4000000;
        Assert.equal(rawbot.getBalance(tx.origin) / 1e18, expected, "Owner should have 4000000 MetaCoin initially");
    }

    function testAllowedToExchange() public {
        Assert.isTrue(rawbot.getExchangeLeftOf(msg.sender) > 0, "User has zero raw coins to exchange.");
    }

    function testAllowedToExchangeValue() public {
        uint value = 10000;
        Assert.isTrue(rawbot.getExchangeLeftOf(msg.sender) >= value, "User has less raw coins to exchange than the value allowed.");
    }

    function testBalanceMoreThanValueToExchange() public {
        uint value = 10000;
        Assert.isTrue(rawbot.getBalance(msg.sender) >= value, "User has less raw coins than the value requested.");
    }

    function testModifyValuePositive() public {
        uint value = 10000;
        bool modified = rawbot.modifyBalance(msg.sender, value);
        Assert.equal(rawbot.getBalance(msg.sender), 4010000 * 1e18, "Wrong number");
        //        Assert.isTrue(modified, "Failed to modify balance");
    }

    function testEthereumPrice() public {
        Assert.equal(rawbot.getEthereumPrice(), 500, "Ethereum price isn't equal 500");
    }

    //    function testSetContractManager() {
    //        Assert.isTrue(rawbot.setContractdeviceManager(device_manager), "User doesn't have privileges.");
    //    }

    function testAddDevice() public {
        bool device_added = device_manager.addDevice("ABC", "Raspberry PI 3");
        Assert.isTrue(device_added, "Failed to add device.");
    }

    function testdevicesAmount() public {
        Assert.isTrue(device_manager.getDevices().length > 0, "Amount of devices equals zero.");
    }

    function testAddAction() public {
        bool add_action = device.addAction("Open", 20, 20, true);
        Assert.isTrue(add_action, "Failed to add action.");
    }

    function testEnableAction() public {
        bool enable_action = device.enableAction(0);
        Assert.isTrue(enable_action, "Failed to enable action.");
    }

    function testDisableAction() public {
        bool disable_action = device.disableAction(0);
        Assert.isTrue(disable_action, "Failed to disable action.");
    }

    function testRefund() {
        bool refund = device.refund(0, 0);
        Assert.isTrue(refund, "Failed to refund action.");
    }

    function testRefundAutomatic() {
        bool refundAutomatic = device.refundAutomatic(0, 0);
        Assert.isTrue(refundAutomatic, "Failed to automatically refund action.");
    }

    function testAddHash() {
        bool addHash = device.addImageHash("abcdefg");
        Assert.isTrue(addHash, "Failed to add IPFS hash.");
    }
}