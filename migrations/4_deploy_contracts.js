var Merchant = artifacts.require("./Merchant.sol");

module.exports = function (deployer) {
    deployer.deploy(Merchant, 0x0a9f2077838bb8be19fada5de4832983e319d663);
};
