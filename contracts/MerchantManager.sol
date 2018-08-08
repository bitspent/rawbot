pragma solidity ^0.4.24;

import "./Merchant.sol";

contract MerchantManager {

    mapping(address => address) public merchants;
    uint  merchants_index = 0;

    event AddMerchant(address, address);

    constructor() public payable {
    }

    function addMerchant() public payable returns (Merchant) {
        Merchant merchant = new Merchant(msg.sender);
        merchants[merchant] = msg.sender;
        merchants_index++;
        emit AddMerchant(msg.sender, merchant);
        return merchant;
    }

    function getMerchants() public view returns (uint){
        return merchants_index;
    }
}