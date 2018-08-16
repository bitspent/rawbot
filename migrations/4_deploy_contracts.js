var Merchant = artifacts.require("./Merchant.sol");

module.exports = function (deployer) {
    deployer.deploy(Merchant, 0x8a530a1fff67c5aa27730f9b8c8bc11b94c76c2c);
};
