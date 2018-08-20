var Device = artifacts.require("./Device.sol");

module.exports = function (deployer) {
    deployer.deploy(Device, "0x443ead827a0efb1f387d92fa088099ab12c5f25a", "ABC", "Raspberry PI 3");
};
