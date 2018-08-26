var Rawbot = artifacts.require("Rawbot");
var DeviceManager = artifacts.require("DeviceManager");
var Device = artifacts.require("Device");
let test_ethereum = true;

contract('Rawbot', function (accounts) {
    let device_address;

    it("should have matching contract creator", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.getContractCreator.call();
        }).then(function (address) {
            assert.equal(address, accounts[0], "Different contract creator address");
        });
    });
    it("should have 4000000 rawbot coin in rawbot's team address", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.getBalance.call(accounts[0]);
        }).then(function (balance) {
            assert.equal(balance.valueOf(), 4000000 * 1e18, "4000000 are not available in " + accounts[0]);
        });
    });

    it("should send 1 ethereum to contract", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.sendTransaction({to: instance.address, from: accounts[9], value: 1e18});
        }).then(function (tx) {
            assert.equal(tx !== null, true, "Failed to send ethereum to contract");
        });
    });

    it("should receive 1000 rawbot coin on account 9", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.getBalance.call(accounts[9]);
        }).then(function (balance) {
            assert.equal(balance.valueOf() == 1000 * 1e18, true, "Failed to receive rawbot coins");
        });
    });

    it("should withdraw 500 rawbot coin from account 9", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.withdraw(500, {to: instance.address, from: accounts[9]});
        }).then(function (tx) {
            assert.equal(tx !== null, true, "Failed to withdraw 500 rawbot coins");
        });
    });

    it("should send 500 rawbot coin to account 8 from account 9", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.sendRawbot(accounts[8], 500, {to: instance.address, from: accounts[9]});
        }).then(function (tx) {
            assert.equal(tx !== null, true, "Failed to send 500 rawbot coins");
        });
    });

    it("should receive 500 rawbot coin on account 8 from account 9", function () {
        return Rawbot.deployed().then(function (instance) {
            return instance.getBalance.call(accounts[8]);
        }).then(function (balance) {
            assert.equal(balance.valueOf() == 500 * 1e18, true, "Failed to receive 500 rawbot coins");
        });
    });

    it("should set device manager contract", function () {
        let rawbot;
        let device_manager;
        return Rawbot.deployed().then(function (instance) {
            rawbot = instance;
        }).then(function () {
            return DeviceManager.deployed().then(function (instance) {
                device_manager = instance;
            });
        }).then(function () {
            return rawbot.setContractDeviceManager(device_manager.address);
        }).then(function (tx) {
            assert.equal(tx.tx !== null, true, "Failed to set device manager contract address");
        });
    });

    it("should add device 1", function () {
        let device_manager;
        return DeviceManager.deployed().then(function (instance) {
            device_manager = instance;
        }).then(function () {
            return device_manager.addDevice("ABC", "Raspberry PI 3", {
                to: device_manager.address,
                from: accounts[0],
                value: 1e18
            });
        }).then(function (tx) {
            if (typeof tx.logs[0].args._contract !== "undefined") {
                device_address = tx.logs[0].args._contract;
            }
            assert.equal(typeof tx.logs[0].args._contract !== "undefined", true, "Failed to add device 1");
        });
    });

    it("should deploy device 1", function () {
        return Device.at(device_address).then(function (instance) {
            assert.equal(typeof instance.address !== "undefined", true, "Failed to deploy device 1");
        });
    });

    it("should send 1 ethereum to device contract", function () {
        return Device.at(device_address).then(function (instance) {
            return instance.sendTransaction({to: device_address, from: accounts[0], value: 1e18});
        }).then(function (tx) {
            assert.equal(tx.tx !== null, true, "Failed to send ethereum to contract");
        });
    });

    it("should received 1 ethereum on device contract", function () {
        return Device.at(device_address).then(function (instance) {
            return instance.getDeviceBalance();
        }).then(function (balance) {
            assert.equal(balance.valueOf() == 1e18, true, "Failed to check device contract balance");
        });
    });

    it("should check device 1 owner", function () {
        return Device.at(device_address).then(function (instance) {
            return instance.getDeviceOwner();
        }).then(function (owner) {
            assert.equal(owner === accounts[0], true, "Failed to check device 1 owner");
        });
    });

    it("should add image hash on device 1", function () {
        return Device.at(device_address).then(function (instance) {
            instance.addImageHash("ABCDEFG", {to: device_address, from: accounts[0]})
                .then(tx => {
                    assert.equal(typeof tx.tx !== "undefined", true, "Failed to add image hash on device 1");
                });
        });
    });

    it("should add action 1 on device 1", function () {
        return Device.at(device_address).then(function (instance) {
            instance.addAction("Open", 50, 0, true, false, {to: device_address, from: accounts[0]})
                .then(tx => {
                    assert.equal(typeof tx.tx !== "undefined", true, "Failed to add action on device 1");
                });
        });
    });

    it("should enable action 1 on device 1", function () {
        return Device.at(device_address).then(function (instance) {
            instance.enableAction(0, {to: device_address, from: accounts[0]})
                .then(tx => {
                    if (tx.logs[0].args._enable !== "undefined") {
                        assert.equal(tx.logs[0].args._enable, true, "Failed to enable action 1 on device 1");
                    } else {
                        assert.equal(false, true, "Failed to enable action 1 on device 1");
                    }
                });
        });
    });

    if (test_ethereum) {
        it("should fetch ethereum price", function () {
            return Rawbot.deployed().then(function (instance) {
                return instance.fetchEthereumPrice(0);
            }).then(function (tx) {
                let bool = tx.tx !== null;
                assert.equal(bool, true, "Failed to fetch Ethereum price");
            });
        });

        it("should display ethereum price correctly", function (done) {
            setTimeout(function () {
                return Rawbot.deployed().then(function (instance) {
                    return instance.getEthereumPrice();
                }).then(function (price) {
                    assert.equal(price > 0, true, "Failed to display ethereum price correctly");
                    done();
                });
            }, 15000);
        });
    }
    // it("should enable action 1 again on device 1", function () {
    //     return Device.at(device_address).then(function (instance) {
    //         instance.enableAction(0, {to: device_address, from: accounts[0]})
    //             .then(tx => {
    //                 if (tx.logs[0].args._enable !== "undefined") {
    //                     assert.equal(tx.logs[0].args._enable, true, "Failed to enable action 1 again on device 1");
    //                 } else {
    //                     assert.equal(true, true, "Failed to enable action 1 again on device 1");
    //                 }
    //             });
    //     });
    // });
});