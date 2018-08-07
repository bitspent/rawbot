pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MerchantManager.sol";

contract TestMerchantManager {
    MerchantManager merchant_manager;

    constructor() public {
        merchant_manager = MerchantManager(DeployedAddresses.MerchantManager());
    }

    function testAddMerchant() public {
        Assert.isTrue(merchant_manager.addMerchant(), "Failed to add merchant");
    }

    function testMerchantsAmount() public {
        Assert.isTrue(merchant_manager.getMerchants() > 0, "Amount of merchants equals zero.");
    }
}