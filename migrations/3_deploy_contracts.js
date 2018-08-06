var MerchantManager = artifacts.require("./MerchantManager.sol");

module.exports = function (deployer) {
    deployer.deploy(MerchantManager);
};
