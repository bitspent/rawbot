var Rawbot = artifacts.require("Rawbot");
var DeviceManager = artifacts.require("DeviceManager");
var Device = artifacts.require("Device");
let test_ethereum = true;

contract('Rawbot', function (accounts) {
    let device_address;

    it("should have 0.25 ethereum in rawbot contract", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getContractBalance.call();
        assert.equal(1e18 / 4, balance, "Contract balance isn't equal to 0.25 eth");
    });

    it("should have 0.25 ethereum in device manager contract", async () => {
        let instance = await DeviceManager.deployed();
        let balance = await instance.getContractBalance.call();
        assert.equal(1e18 / 4, balance, "Contract balance isn't equal to 0.25 eth");
    });

    it("should match rawbot contract address in device manager contract", async () => {
        let rawbot = await Rawbot.deployed();
        let device_manager = await DeviceManager.deployed();
        let device_manager_address = await device_manager.getRawbotAddress.call();
        let rawbot_address = await rawbot.address;
        assert.equal(device_manager_address, rawbot_address, "Rawbot contract address doesn't match the device manager's");
    });

    it("should have rawbot team address matching contract creator", async () => {
        let instance = await Rawbot.deployed();
        let address = await instance.getContractCreator.call();
        assert.equal(address, accounts[0], "Different contract creator address");
    });

    it("should have 4000000 rawbot coin in rawbot's team address", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[0]);
        assert.equal(balance.valueOf(), 4000000 * 1e18, "4000000 are not available in " + accounts[0]);
    });

    it("should send 1 ethereum to contract using account 9", async () => {
        let instance = await Rawbot.deployed();
        let tx = await instance.sendTransaction({to: instance.address, from: accounts[9], value: 1e18});
        assert.equal(tx !== null, true, "Failed to send ethereum to contract");
    });

    it("should receive 1000 rawbot coin on account 9", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[9]);
        assert.equal(balance.valueOf() == 1000 * 1e18, true, "Failed to receive rawbot coins");
    });

    it("should fail to send 99 ethereum to contract using account 9", async () => {
        let instance = await Rawbot.deployed();
        try {
            let tx = await instance.sendTransaction({to: instance.address, from: accounts[9], value: 99 * 1e18});
        } catch (e) {
            assert.equal(false, false, "Failed to send ethereum to contract");
        }
    });

    it("should withdraw 500 rawbot coin into ethereum from account 9", async () => {
        let instance = await Rawbot.deployed();
        let tx = await instance.withdraw(500, {to: instance.address, from: accounts[9]});
        assert.equal(tx !== null, true, "Failed to withdraw 500 rawbot coins");
    });

    it("should have 500 rawbot coin to exchange on account 9", async () => {
        let instance = await Rawbot.deployed();
        let amount = await instance.getExchangeLeftOf(accounts[9]);
        assert.equal(amount == 500 * 1e18, true, "Failed to get exchange left of 500 rawbot coins");
    });

    it("should send 500 rawbot coin to account 8 from account 9", async () => {
        let instance = await Rawbot.deployed();
        let tx = await instance.sendRawbot(accounts[8], 500, {to: instance.address, from: accounts[9]});
        assert.equal(tx !== null, true, "Failed to send 500 rawbot coins");
    });

    it("should have 500 rawbot coin on account 8 from account 9", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[8]);
        assert.equal(balance.valueOf() == 500 * 1e18, true, "Failed to receive 500 rawbot coins");
    });

    it("should have 0 rawbot coin on account 9", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[9]);
        assert.equal(balance.valueOf() == 0, true, "Failed to check balance on account 9");
    });

    it("should fail to send 500 rawbot coin to account 8 from account 9", async () => {
        let instance = await Rawbot.deployed();
        try {
            let tx = await instance.sendRawbot(accounts[8], 500, {to: instance.address, from: accounts[9]});
        } catch (e) {
            assert.equal(false, false, "Failed to send 500 rawbot coins");
        }
    });

    it("should fail to withdraw 500 rawbot coin into ethereum from account 9", async () => {
        let instance = await Rawbot.deployed();
        try {
            let tx = await instance.withdraw(500, {to: instance.address, from: accounts[9]});
        } catch (e) {
            assert.equal(false, false, "Failed to withdraw 500 rawbot coins");
        }
    });

    it("should set device manager contract using account 0", async () => {
        let rawbot = await Rawbot.deployed();
        let device_manager = await DeviceManager.deployed();
        let tx = await rawbot.setContractDeviceManager(device_manager.address, {from: accounts[0]});
        assert.equal(tx !== null, true, "Failed to set device manager contract address");
    });

    it("should fail to set device manager contract using account 3", async () => {
        let rawbot = await Rawbot.deployed();
        let device_manager = await DeviceManager.deployed();
        try {
            let tx = await rawbot.setContractDeviceManager(device_manager.address, {from: accounts[3]});
        } catch (e) {
            assert.equal(false, false, "Failed to set device manager contract address");
        }
    });

    it("should match device manager contract previously set", async () => {
        let rawbot = await Rawbot.deployed();
        let device_manager = await DeviceManager.deployed();
        let address = await rawbot.getContractDeviceManager();
        assert.equal(address === device_manager.address, true, "Failed to match device manager contract address");
    });

    it("should add device 1", async () => {
        let device_manager = await DeviceManager.deployed();
        let tx = await device_manager.addDevice("ABC1", "Raspberry PI 3", {
            to: device_manager.address,
            from: accounts[0],
            value: 1e18
        });
        if (typeof tx.logs[0].args._contract !== "undefined") {
            device_address = tx.logs[0].args._contract;
        }
        assert.equal(typeof tx.logs[0].args._contract !== "undefined", true, "Failed to add device 1");
    });

    it("should add device 2", async () => {
        let device_manager = await DeviceManager.deployed();
        let tx = await device_manager.addDevice("ABC2", "Raspberry PI 2", {
            to: device_manager.address,
            from: accounts[0],
            value: 1e18
        });
        if (typeof tx.logs[0].args._contract !== "undefined") {
            device_address = tx.logs[0].args._contract;
        }
        assert.equal(typeof tx.logs[0].args._contract !== "undefined", true, "Failed to add device 2");
    });

    it("should add device 3", async () => {
        let device_manager = await DeviceManager.deployed();
        let tx = await device_manager.addDevice("ABC3", "Arduino", {
            to: device_manager.address,
            from: accounts[0],
            value: 1e18
        });
        if (typeof tx.logs[0].args._contract !== "undefined") {
            device_address = tx.logs[0].args._contract;
        }
        assert.equal(typeof tx.logs[0].args._contract !== "undefined", true, "Failed to add device 3");
    });

    it("should have 3 devices added on device manager", async () => {
        let device_manager = await DeviceManager.deployed();
        let devices = await device_manager.getDevices();
        assert.equal(devices.length === 3, true, "Failed to check devices amount");
    });

    it("should be able to modify balance automatically", async () => {
        let device_manager = await DeviceManager.deployed();
        let bool = await device_manager.hasAccess(device_address);
        assert.equal(bool, true, "Failed to modify balance automatically");
    });

    it("should not be able to modify balance automatically", async () => {
        let device_manager = await DeviceManager.deployed();
        let bool = await device_manager.hasAccess(accounts[0]);
        assert.equal(bool, false, "Failed to modify balance automatically");
    });

    it("should deploy device 1", async () => {
        let instance = await Device.at(device_address);
        assert.equal(typeof instance.address !== "undefined", true, "Failed to deploy device 1");
    });

    it("should send 1 ethereum to device 1", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.sendTransaction({to: device_address, from: accounts[0], value: 1e18});
        assert.equal(tx.tx !== null, true, "Failed to send ethereum to contract");
    });

    it("should receive 1 ethereum on device 1", async () => {
        let instance = await Device.at(device_address);
        let balance = await instance.getDeviceBalance();
        assert.equal(balance.valueOf() == 1e18, true, "Failed to check device contract balance");
    });

    it("should match device 1 owner", async () => {
        let instance = await Device.at(device_address);
        let owner = await instance.getDeviceOwner();
        assert.equal(owner === accounts[0], true, "Failed to check device 1 owner");
    });

    it("should add image hash on device 1", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.addImageHash("ABCDEFG", {to: device_address, from: accounts[0]});
        assert.equal(typeof tx.tx !== "undefined", true, "Failed to add image hash on device 1");
    });

    it("should add action 1 on device 1", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.addAction("Open", 50, 0, true, false, {to: device_address, from: accounts[0]});
        assert.equal(typeof tx.tx !== "undefined", true, "Failed to add action 1 on device 1");
    });

    it("should add action 2 on device 1", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.addAction("Close", 0, 0, true, false, {to: device_address, from: accounts[0]});
        assert.equal(typeof tx.tx !== "undefined", true, "Failed to add action 2 on device 1");
    });

    it("should add action 3 on device 1", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.addAction("Electricity", 250, 86400, true, true, {to: device_address, from: accounts[0]});
        assert.equal(typeof tx.tx !== "undefined", true, "Failed to add action 3 on device 1");
    });

    it("should enable action 1 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.enableAction(0, {to: device_address, from: accounts[8]});
        if (tx.logs[0].args._enable !== "undefined") {
            assert.equal(tx.logs[0].args._enable, true, "Failed to enable action 1 on device 1");
        } else {
            assert.equal(false, true, "Failed to enable action 1 on device 1");
        }
    });

    it("should have 50 rawbot coin on device 1", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(device_address);
        assert.equal(balance.valueOf(), 50 * 1e18, "50 are not available in device 1");
    });

    it("should have 450 rawbot coin on account 8", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[8]);
        assert.equal(balance.valueOf(), 450 * 1e18, "450 are not available in " + accounts[8]);
    });

    it("should withdraw 50 rawbot coins from device 1", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.withdraw(50, {to: device_address, from: accounts[0]});
        assert.equal(tx !== null, true, "Failed to withdraw 50 rawbot coins from device 1");
    });

    it("should fail to withdraw 50 rawbot coins from device 1", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.withdraw(50, {to: device_address, from: accounts[0]});
        } catch (e) {
            assert.equal(false, false, "Failed to withdraw 50 rawbot coins from device 1");
        }
    });

    it("should have 0 rawbot coin on device 1 after withdrawal", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(device_address);
        assert.equal(balance.valueOf(), 0, "More than zero rawbot coins are available in device 1");
    });

    it("should fail to enable action 1 again on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.enableAction(0, {to: device_address, from: accounts[8]});
        } catch (e) {
            assert.equal(false, false, "Failed to enable action 1 again on device 1");
        }
    });

    it("should disable action 1 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.disableAction(0, {to: device_address, from: accounts[8]});
        if (tx.logs[0].args._disable !== "undefined") {
            assert.equal(tx.logs[0].args._disable, true, "Failed to disable action 1 on device 1");
        } else {
            assert.equal(false, true, "Failed to disable action 1 on device 1");
        }
    });

    it("should fail to disable action 1 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.disableAction(0, {to: device_address, from: accounts[8]});
        } catch (e) {
            assert.equal(false, false, "Failed to disable action 1 on device 1");
        }
    });

    it("should fail to enable action 5 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.enableAction(4, {to: device_address, from: accounts[8]});
        } catch (e) {
            assert.equal(false, false, "Failed to enable action 5 on device 1");
        }
    });

    it("should fail to disable action 5 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.disableActon(0, {to: device_address, from: accounts[8]});
        } catch (e) {
            assert.equal(false, false, "Failed to disable action 5 on device 1");
        }
    });

    it("should enable action 3 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.enableAction(2, {to: device_address, from: accounts[8]});
        if (tx.logs[0].args._enable !== "undefined") {
            assert.equal(tx.logs[0].args._enable, true, "Failed to enable action 3 on device 1");
        } else {
            assert.equal(false, true, "Failed to enable action 3 on device 1");
        }
    });

    it("should have 200 rawbot coin on account 8", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[8]);
        assert.equal(balance.valueOf(), 200 * 1e18, "200 are not available in " + accounts[8]);
    });

    it("should have 250 rawbot coin on device 1 after action 3 execution", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(device_address);
        assert.equal(balance.valueOf(), 250 * 1e18, "Balance is different than 250 rawbot coins are available in device 1");
    });

    it("should fail to refund action 1 on device 1 using account 0", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.refund(0, 0, {to: device_address, from: accounts[0]});
        } catch (e) {
            assert.equal(false, false, "Failed to refund action 1 on device 1");
        }
    });

    it("should refund action 3 on device 1 using account 0", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.refund(2, 0, {to: device_address, from: accounts[0]});
        assert.equal(tx !== null, true, "Failed to refund action 1 on device 1");
    });

    it("should fail to refund action 3 again on device 1 using account 0", async () => {
        let instance = await Device.at(device_address);
        try {
            let tx = await instance.refund(2, 0, {to: device_address, from: accounts[0]});
        } catch (e) {
            assert.equal(false, false, "Failed to refund action 3 again on device 1");
        }
    });

    it("should have 450 rawbot coin on account 8 after refunding action 3", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[8]);
        assert.equal(balance.valueOf(), 450 * 1e18, "450 are not available in " + accounts[8]);
    });

    it("should enable action 3 on device 1 using account 8", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.enableAction(2, {to: device_address, from: accounts[8]});
        if (tx.logs[0].args._enable !== "undefined") {
            assert.equal(tx.logs[0].args._enable, true, "Failed to enable action 3 on device 1");
        } else {
            assert.equal(false, true, "Failed to enable action 3 on device 1");
        }
    });

    it("should automatically refund action 3 on device 1 using account 0", async () => {
        let instance = await Device.at(device_address);
        let tx = await instance.refundAutomatic(2, 1, {to: device_address, from: accounts[8]});
        assert.equal(tx !== null, true, "Failed to refund action 1 on device 1");
    });

    it("should have 450 rawbot coin on account 8 after automatically refunding action 3 for the second time", async () => {
        let instance = await Rawbot.deployed();
        let balance = await instance.getBalance.call(accounts[8]);
        assert.equal(balance.valueOf(), 450 * 1e18, "450 are not available in " + accounts[8]);
    });

    if (test_ethereum) {
        it("should fetch ethereum price", async () => {
            let instance = await Rawbot.deployed();
            let tx = instance.fetchEthereumPrice(0);
            assert.equal(tx.tx !== null, true, "Failed to fetch Ethereum price");
        });

        it("should display ethereum price correctly", async () => {
            let instance = await Rawbot.deployed();
            let price = await instance.getEthereumPrice();
            await waitSeconds(15);
            assert.equal(price > 0, true, "Failed to display ethereum price correctly");
        });
    }
});

function waitSeconds(seconds) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve();
        }, seconds * 1000);
    });
}