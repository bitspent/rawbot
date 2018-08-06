pragma solidity ^0.4.24;

import "./Device.sol";
import "./Rawbot.sol";

contract DeviceManager {
    Rawbot public rawbot;
    mapping(address => address) public devices;

    event AddDevice(address, address, string, string);

    constructor(address rawbot_address) public {
        rawbot = Rawbot(rawbot_address);
    }

    //"ABC1", "Raspberry PI 3"
    function addDevice(string _device_serial_number, string _device_name) public payable returns (Device) {
        Device device = new Device(msg.sender, _device_serial_number, _device_name);
        devices[device] = msg.sender;
        emit AddDevice(msg.sender, device, _device_serial_number, _device_name);
        return device;
    }
}