pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MerchantManager.sol";

contract TestMerchantManager {
    function testAddMerchant() public {
        MerchantManager meta = MerchantManager(DeployedAddresses.MerchantManager());
        Assert.isTrue(meta.addMerchant(), "Failed to add merchant");
    }
}