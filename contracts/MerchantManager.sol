pragma solidity ^0.4.24;

import "./Merchant.sol";

contract MerchantManager {

    mapping(address => address) public merchants;
    mapping(address => bool) public merchant_access;

    uint  merchants_index = 0;

    event AddMerchant(address, address);

    constructor() public payable {
    }

    function addMerchant() public payable returns (bool) {
        Merchant merchant = new Merchant(msg.sender);
        merchants[merchant] = msg.sender;
        merchant_access[merchant] = true;
        merchants_index++;
        emit AddMerchant(msg.sender, merchant);
        return true;
    }

    function getMerchants() public view returns (uint){
        return merchants_index;
    }

    function hasAccess(address _address) public view returns (bool){
        return merchant_access[_address];
    }
}