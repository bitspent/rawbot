pragma solidity ^0.4.24;

import "./Rawbot.sol";
import "./Oraclize.sol";

contract Merchant is usingOraclize {
    string[] public device_serial_numbers;
    address public merchant_address;
    mapping(string => Device) devices;

    event SendDeviceErrorMessage(string);
    event Testing(string);
    event SendErrorMessage(string);
    event ActionAdd(string, uint, string, uint256, uint256, bool, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);
    event Refund(uint, uint, uint, uint);

    address public rawbot_address = 0x1e3d402d19dd111db15fe00cd5726da452bf5a75;
    Rawbot public rawbot;

    constructor(address _merchant_address) payable public {
        merchant_address = _merchant_address;
        rawbot = Rawbot(rawbot_address);
    }

    struct Device {
        string device_name;
        Action[] device_actions;
        ActionHistory[] device_history;
        bool available;
    }

    struct Action {
        uint id;
        string name;
        uint price;
        uint duration;
        bool refundable;
        bool available;
    }

    struct ActionHistory {
        address user;
        uint256 id;
        string name;
        uint256 price;
        uint256 duration;
        uint256 time;
        bool enable;
        bool refunded;
        bool available;
    }

    //"ABC", "Raspberry PI 3"
    function addDevice(string device_serial_number, string device_name) public payable returns (bool){
        //        require(merchant_address == msg.sender);
        require(devices[device_serial_number].available == false);
        devices[device_serial_number].device_name = device_name;
        devices[device_serial_number].available = true;
        return true;
    }

    //"ABC", "Open", 20, 20, true
    function addAction(string device_serial_number, string action_name, uint action_price, uint action_duration, bool refundable) public payable returns (bool){
        //        require(merchant_address == msg.sender);
        require(devices[device_serial_number].available == true);
        devices[device_serial_number].device_actions.push(Action(devices[device_serial_number].device_actions.length, action_name, action_price, action_duration, refundable, true));
        emit ActionAdd(device_serial_number, devices[device_serial_number].device_actions.length, action_name, action_price, action_duration, refundable, true);
        return true;
    }

    //"ABC", 0
    function enableAction(string device_serial_number, uint action_id) public payable returns (bool success) {
        require(devices[device_serial_number].available == true);
        require(rawbot.getBalance(msg.sender) >= devices[device_serial_number].device_actions[action_id].price);
        devices[device_serial_number].device_history.push(ActionHistory(msg.sender, action_id, devices[device_serial_number].device_actions[action_id].name, devices[device_serial_number].device_actions[action_id].price, devices[device_serial_number].device_actions[action_id].duration, now, true, false, true));
        rawbot.modifyBalance(msg.sender, - devices[device_serial_number].device_actions[action_id].price);
        rawbot.modifyBalance(merchant_address, + devices[device_serial_number].device_actions[action_id].price);
        emit ActionEnable(device_serial_number, action_id, devices[device_serial_number].device_actions[action_id].name, devices[device_serial_number].device_actions[action_id].price, devices[device_serial_number].device_actions[action_id].duration, true);
        return true;
    }

    //"ABC", 0
    function disableAction(string device_serial_number, uint action_id) public payable returns (bool success) {
        require(devices[device_serial_number].available == true);
        devices[device_serial_number].device_history.push(ActionHistory(msg.sender, action_id, devices[device_serial_number].device_actions[action_id].name, devices[device_serial_number].device_actions[action_id].price, devices[device_serial_number].device_actions[action_id].duration, now, true, false, true));
        emit ActionDisable(device_serial_number, action_id, devices[device_serial_number].device_actions[action_id].name, devices[device_serial_number].device_actions[action_id].price, devices[device_serial_number].device_actions[action_id].duration, true);
        return true;
    }

    //"ABC", 0, 0
    function refund(string device_serial_number, uint256 action_id, uint256 _action_history_id) payable public returns (bool) {
        //        require(msg.sender == merchant_address);
        require(devices[device_serial_number].available == true);
        require(devices[device_serial_number].device_actions[action_id].available == true);
        require(devices[device_serial_number].device_actions[action_id].refundable == true);
        require(devices[device_serial_number].device_history[_action_history_id].available == true);
        require(devices[device_serial_number].device_history[_action_history_id].id == action_id);
        require(devices[device_serial_number].device_history[_action_history_id].refunded == false);

        emit Refund(action_id, _action_history_id, devices[device_serial_number].device_actions[action_id].price, now);
        return true;
    }

    //"ABC", 0, 0
    function refundAutomatic(string device_serial_number, uint256 action_id, uint256 _action_history_id) payable public returns (bool success) {
        require(devices[device_serial_number].device_actions[action_id].available == true);
        require(devices[device_serial_number].device_actions[action_id].refundable == true);
        require(devices[device_serial_number].device_history[_action_history_id].available == true);
        require(devices[device_serial_number].device_history[_action_history_id].id == action_id);
        require(devices[device_serial_number].device_history[_action_history_id].refunded == false);
        uint time_passed = now - devices[device_serial_number].device_history[_action_history_id].time + devices[device_serial_number].device_history[_action_history_id].duration;
        require(time_passed < 0);
        return true;
    }

    function getActionPrice(string device_serial_number, uint action_id) public view returns (uint) {
        return devices[device_serial_number].device_actions[action_id].price;
    }

    function isRefundable(string device_serial_number, uint action_id) public view returns (bool) {
        return devices[device_serial_number].device_actions[action_id].refundable;
    }

    function getMerchantAddress() public view returns (address) {
        return merchant_address;
    }

    function withdrawFromDevice(address device_address, uint value) public payable returns (bool success) {
        require(merchant_address == msg.sender);
        require(rawbot.getBalance(device_address) >= value);
        rawbot.modifyBalance(device_address, - value);
        rawbot.modifyBalance(msg.sender, + value);
        return true;
    }

    function getUserBalance(address _address) public view returns (uint256){
        return rawbot.getBalance(_address);
    }

    function recurringPayments(uint _days) public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
        } else {
            oraclize_query(_days * 60 * 60 * 24, "URL", "");
            RECURRING_PAYMENT_STEP = 1;
        }
    }

    event RecurringPaymentLog(string);

    uint public RECURRING_PAYMENT_STEP = 0;

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        emit RecurringPaymentLog("Potato test1");
        RECURRING_PAYMENT_STEP = 2;
    }
}