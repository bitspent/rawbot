pragma solidity ^0.4.24;

import "./Merchant.sol";

contract MerchantManager {

    mapping(address => address) public merchants;
    uint  merchants_index = 0;

    event AddMerchant(address, address);

    constructor() public payable {
    }

    function addMerchant() public payable returns (bool) {
        Merchant merchant = new Merchant(msg.sender);
        merchants[merchant] = msg.sender;
        merchants_index++;
        emit AddMerchant(msg.sender, merchant);
        return true;
    }

    function getMerchants() public view returns (uint){
        return merchants_index;
    }
}