var Merchant = artifacts.require("./Merchant.sol");

module.exports = function (deployer) {
    deployer.deploy(Merchant, 0x8e99bad2338f5673de79d7bd5ab7e83f5ef65dbb);
};
