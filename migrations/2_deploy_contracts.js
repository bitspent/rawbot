var Rawbot = artifacts.require("./Rawbot.sol");
var DeviceManager = artifacts.require("./DeviceManager.sol");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(Rawbot, {from: accounts[0], value: 1e18 / 4}).then(function () {
        return deployer.deploy(DeviceManager, Rawbot.address, {from: accounts[0], value: 1e18 / 4});
    });
};

