pragma solidity ^0.4.24;

import "./Rawbot.sol";
import "./Merchant.sol";

contract DeviceManager {
    Rawbot public rawbot;
    mapping(address => address) public merchants;

    event AddMerchant(address, address);

    constructor(address rawbot_address) public {
        rawbot = Rawbot(rawbot_address);
    }

    function addMerchant() public payable returns (Merchant) {
        Merchant merchant = new Merchant(msg.sender);
        emit AddMerchant(msg.sender, merchant);
        return merchant;
    }
}