pragma solidity ^0.4.24;

import "./StandardToken.sol";

contract Rawbot is StandardToken {
    constructor() StandardToken(20000000, "Rawbot Test 1", "RWT") public payable {
        // price_status = PRICE_CHECKING_STATUS.NEEDED;
        // initEthereumPrice();
        user[msg.sender].available = true;
        user[msg.sender].allowed_to_exchange += 4000000;
    }

    // function TestingFunction() public {
    //        addDevice(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", "Raspberry PI 3");
    //        addAction(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", "Open", 20, 20, true);
    //        enableAction(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", 0);
    //        disableAction(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", 0);
    //        refund(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", 0, 0);
    // }

    function getActionsLengthOfDevice(address _device_address, string _device_serial_number) public view returns (uint) {
        return deviceActionsLength[_device_address][_device_serial_number];
    }

    function getActionsHistoryLengthOfDevice(address _device_address, string _device_serial_number) public view returns (uint) {
        return deviceActionsHistoryLength[_device_address][_device_serial_number];
    }

    function TestingIncrement(address _device_address, string _device_serial_number) public {
        deviceActionsHistoryLength[_device_address][_device_serial_number]++;
    }

    // function refundAutomatic() public {

    // }

    function getTotalDevices() public view returns (uint) {
        return (device_serial_numbers.length);
    }

    function getExchangeLeftOf(address _address) view public returns (uint256){
        return user[_address].allowed_to_exchange;
    }

    // "0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1"
    function getDevice(address _device_address, string _device_serial_number) public view returns (string, uint256, address, bool){
        Device storage current_device = devices[_device_address][_device_serial_number];
        return (current_device.name, current_device.balance, current_device.owner, current_device.available);
    }

    function getAddresses() view public returns (address[]) {
        return exchange_addresses;
    }

    function getAction(address _device_address, string _device_serial_number, uint _index) public view returns (string){
        return deviceActions[_device_address][_device_serial_number][_index].name;
    }

    function getDeviceOwner(address _address, string _device_serial_number) view public returns (address) {
        return devices[_address][_device_serial_number].owner;
    }

    function destoryContract() public {
        selfdestruct(this);
    }
}