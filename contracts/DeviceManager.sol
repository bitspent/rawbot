pragma solidity ^0.4.24;

import "./Device.sol";
import "./Rawbot.sol";
import "./Owned.sol";

contract DeviceManager is Owned {
    address[] private devices;
    mapping(address => address[]) private devicesOf;
    mapping(address => address) private ownerOf;
    mapping(address => bool) private devices_access;
    Rawbot private rawbot;
    address private rawbot_address;

    event DeviceAdd(address _sender, address _contract, string _device_serial_number, string _device_name);

    constructor(address _rawbot_address) public payable {
        rawbot_address = _rawbot_address;
        rawbot = Rawbot(_rawbot_address);
    }

    function addDevice(string _device_serial_number, string _device_name) public payable returns (Device) {
        Device device = new Device(rawbot_address, msg.sender, _device_serial_number, _device_name);
        devicesOf[msg.sender].push(device);
        ownerOf[device] = msg.sender;
        devices.push(device);
        devices_access[device] = true;
        emit DeviceAdd(msg.sender, device, _device_serial_number, _device_name);
        return device;
    }

    function withdrawFromDevice(address device_address, uint256 value) public payable returns (bool success) {
        require(ownerOf[device_address] == msg.sender);
        require(rawbot.getBalance(device_address) >= value);
        rawbot.modifyBalance(device_address, - value);
        rawbot.modifyBalance(msg.sender, value);
        return true;
    }

    function getDevices() public view returns (address[]){
        return devices;
    }

    function getDevicesOf(address _address) public view returns (address[]){
        return devicesOf[_address];
    }

    function hasAccess(address _address) public view returns (bool){
        return devices_access[_address];
    }

    function getRawbotAddress() public view returns (address){
        return rawbot_address;
    }
}