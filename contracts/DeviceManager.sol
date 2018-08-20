pragma solidity ^0.4.24;

import "./Device.sol";
import "./Rawbot.sol";

contract DeviceManager {
    address[] public devices;
    mapping(address => address[]) public devicesOf;
    mapping(address => address) public ownerOf;
    mapping(address => bool) public devices_access;
    Rawbot private rawbot;
    address public constant rawbot_address = 0x5238527616882251df1ae2c5353dc6cf0a515fdc;

    event DeviceAdd(address _sender, address _contract, string _device_serial_number, string _device_name);

    constructor() public payable {
        rawbot = Rawbot(rawbot_address);
    }

    function addDevice(string _device_serial_number, string _device_name) public payable returns (bool) {
        Device device = new Device(msg.sender, _device_serial_number, _device_name);
        devicesOf[msg.sender].push(device);
        ownerOf[device] = msg.sender;
        devices.push(device);
        devices_access[device] = true;
        emit DeviceAdd(msg.sender, device, _device_serial_number, _device_name);
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

    function withdrawFromDevice(address device_address, uint256 value) public payable returns (bool success) {
        require(ownerOf[device_address] == msg.sender);
        require(rawbot.getBalance(device_address) >= value);
        rawbot.modifyBalance(device_address, - value);
        rawbot.modifyBalance(msg.sender, value);
        return true;
    }

}