pragma solidity ^0.4.24;

import "./Rawbot.sol";
import "./Oraclize.sol";

contract Merchant is usingOraclize {

    Rawbot private rawbot;
    address public rawbot_address = 0x1e3d402d19dd111db15fe00cd5726da452bf5a75;
    address private merchant_address;

    mapping(string => Device) private devices;
    mapping(uint256 => ActionHistory[]) private action_history;
    mapping(uint256 => ActionHistory[]) private recurring_action_history;

    uint256 public RECURRING_PAYMENT_STEP = 0;
    string[] private device_serial_numbers;
    string[] private device_names;
    RA[] recurring_action_array;

    event Refund(uint, uint, uint, uint);
    event RefundAutomatic(uint, uint, uint, uint);

    event RecurrentRefund(uint, uint, uint, uint);
    event RecurrentRefundAutomatic(uint, uint, uint, uint);

    event RecurringPaymentLog(string);
    event ActionAdd(string, uint, string, uint256, uint256, bool, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);

    event RecurringActionAdd(string, uint, string, uint256, uint256, bool, bool);
    event RecurringActionEnable(string, uint, string, uint256, uint256, bool);
    event RecurringActionDisable(string, uint, string, uint256, uint256, bool);


    constructor(address _merchant_address) payable public {
        merchant_address = _merchant_address;
        rawbot = Rawbot(rawbot_address);
    }

    struct RA {
        string device_name;
        uint256 recurring_action_id;
        uint256 recurring_action_history_id;
        bool available;
    }

    struct Device {
        string device_name;
        Action[] device_actions;
        RecurringAction[] device_recurring_actions;
        bool available;
    }

    struct Action {
        uint256 id;
        string name;
        uint256 price;
        uint256 duration;
        bool refundable;
        bool available;
    }

    struct RecurringAction {
        uint256 id;
        string name;
        uint256 price;
        uint256 _days;
        bool refundable;
        bool available;
    }

    struct ActionHistory {
        address user;
        uint256 id;
        uint256 time;
        bool enable;
        bool refunded;
        bool available;
    }

    //"ABC", "Raspberry PI 3"
    function addDevice(string device_serial_number, string device_name) public payable returns (bool){
        //        require(merchant_address == msg.sender, "Only merchant can add devices.");
        require(devices[device_serial_number].available == false);
        devices[device_serial_number].device_name = device_name;
        devices[device_serial_number].available = true;
        device_serial_numbers.push(device_serial_number);
        device_names.push(device_name);
        return true;
    }

    //"ABC", "Open", 20, 20, true
    function addAction(string device_serial_number, string action_name, uint256 action_price, uint256 action_duration, bool refundable) public payable returns (bool){
        //        require(merchant_address == msg.sender);
        require(devices[device_serial_number].available == true, "Device serial number is not available");
        devices[device_serial_number].device_actions.push(Action(devices[device_serial_number].device_actions.length, action_name, action_price, action_duration, refundable, true));
        emit ActionAdd(device_serial_number, devices[device_serial_number].device_actions.length, action_name, action_price, action_duration, refundable, true);
        return true;
    }

    //"ABC", "Open", 20, 20, true
    function addRecurringAction(string device_serial_number, string action_name, uint256 action_price, uint256 _days, bool refundable) public payable returns (bool){
        //        require(merchant_address == msg.sender);
        require(devices[device_serial_number].available == true, "Device serial number is not available");
        devices[device_serial_number].device_recurring_actions.push(RecurringAction(devices[device_serial_number].device_recurring_actions.length, action_name, action_price, _days, refundable, true));
        emit ActionAdd(device_serial_number, devices[device_serial_number].device_recurring_actions.length, action_name, action_price, _days, refundable, true);
        return true;
    }

    //"ABC", 0
    function enableAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        require(devices[device_serial_number].available == true, "Device serial number is not available");
        require(devices[device_serial_number].device_actions[action_id].available == true, "Device action id is not available");
        //        require(rawbot.getBalance(msg.sender) >= devices[device_serial_number].device_actions[action_id].price, "User doesn't have enough balance");
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, true, false, true));
        //        rawbot.modifyBalance(msg.sender, - devices[device_serial_number].device_actions[action_id].price);
        //        rawbot.modifyBalance(merchant_address, devices[device_serial_number].device_actions[action_id].price);
        emit ActionEnable(device_serial_number, action_id, devices[device_serial_number].device_actions[action_id].name, devices[device_serial_number].device_actions[action_id].price, devices[device_serial_number].device_actions[action_id].duration, true);
        return true;
    }

    //"ABC", 0
    function enableRecurringAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        if (oraclize_getPrice("URL") > address(this).balance) {
            return false;
        } else {
            require(devices[device_serial_number].available == true, "Device serial number is not available");
            require(devices[device_serial_number].device_recurring_actions[action_id].available == true, "Device action id is not available");
            require(rawbot.getBalance(msg.sender) >= devices[device_serial_number].device_recurring_actions[action_id].price, "User doesn't have enough balance");
            recurring_action_history[action_id].push(ActionHistory(msg.sender, action_id, now, true, false, true));
            recurring_action_array.push(RA(device_serial_number, action_id, recurring_action_history[action_id].length - 1, true));
            rawbot.modifyBalance(msg.sender, - devices[device_serial_number].device_recurring_actions[action_id].price);
            rawbot.modifyBalance(merchant_address, devices[device_serial_number].device_recurring_actions[action_id].price);
            oraclize_query(devices[device_serial_number].device_recurring_actions[action_id]._days * 60 * 60 * 24, "URL", "");
            RECURRING_PAYMENT_STEP = 1;
            emit ActionEnable(device_serial_number, action_id, devices[device_serial_number].device_recurring_actions[action_id].name, devices[device_serial_number].device_recurring_actions[action_id].price, devices[device_serial_number].device_recurring_actions[action_id]._days, true);
            return true;
        }
    }

    //"ABC", 0
    function disableAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        require(devices[device_serial_number].available == true, "Device serial number is not available");
        require(devices[device_serial_number].device_actions[action_id].available == true, "Device action id is not available");
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, false, false, true));
        emit ActionDisable(device_serial_number, action_id, devices[device_serial_number].device_actions[action_id].name, devices[device_serial_number].device_actions[action_id].price, devices[device_serial_number].device_actions[action_id].duration, true);
        return true;
    }

    //"ABC", 0
    function disableRecurringAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        require(devices[device_serial_number].available == true, "Device serial number is not available");
        require(devices[device_serial_number].device_recurring_actions[action_id].available == true, "Device action id is not available");
        recurring_action_history[action_id].push(ActionHistory(msg.sender, action_id, now, false, false, true));
        emit ActionDisable(device_serial_number, action_id, devices[device_serial_number].device_recurring_actions[action_id].name, devices[device_serial_number].device_recurring_actions[action_id].price, devices[device_serial_number].device_recurring_actions[action_id]._days, true);
        return true;
    }

    //"ABC", 0, 0
    function refund(string device_serial_number, uint256 action_id, uint _action_history_id) payable public returns (bool) {
        //        require(msg.sender == merchant_address);
        require(devices[device_serial_number].available == true);
        require(devices[device_serial_number].device_actions[action_id].available == true);
        require(devices[device_serial_number].device_actions[action_id].refundable == true);
        require(action_history[action_id][_action_history_id].available == true);
        require(action_history[action_id][_action_history_id].id == action_id);
        require(action_history[action_id][_action_history_id].refunded == false);
        //        rawbot.modifyBalance(msg.sender, devices[device_serial_number].device_actions[action_id].price);
        emit Refund(action_id, _action_history_id, devices[device_serial_number].device_actions[action_id].price, now);
        return true;
    }

    //"ABC", 0, 0
    function refundAutomatic(string device_serial_number, uint256 action_id, uint256 _action_history_id) payable public returns (bool success) {
        require(devices[device_serial_number].available == true);
        require(devices[device_serial_number].device_actions[action_id].available == true);
        require(devices[device_serial_number].device_actions[action_id].refundable == true);
        require(action_history[action_id][_action_history_id].available == true);
        require(action_history[action_id][_action_history_id].id == action_id);
        require(action_history[action_id][_action_history_id].refunded == false);
        uint256 time_passed = now - (action_history[action_id][_action_history_id].time + devices[device_serial_number].device_actions[action_id].duration);
        //        require(time_passed < 0);
        emit RefundAutomatic(action_id, _action_history_id, devices[device_serial_number].device_actions[action_id].price, now);
        return true;
    }

    function getActionPrice(string device_serial_number, uint256 action_id) public view returns (uint) {
        return devices[device_serial_number].device_actions[action_id].price;
    }

    function isRefundable(string device_serial_number, uint256 action_id) public view returns (bool) {
        return devices[device_serial_number].device_actions[action_id].refundable;
    }

    function getMerchantAddress() public view returns (address) {
        return merchant_address;
    }

    function withdrawFromDevice(address device_address, uint256 value) public payable returns (bool success) {
        require(merchant_address == msg.sender);
        require(rawbot.getBalance(device_address) >= value);
        rawbot.modifyBalance(device_address, - value);
        rawbot.modifyBalance(msg.sender, value);
        return true;
    }

    function getUserBalance(address _address) public view returns (uint256){
        return rawbot.getBalance(_address);
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        RA[] temp;
        for (uint i = 0; i < recurring_action_array.length; i++) {
            require(recurring_action_history[raid][rahid].id == raid);
            string device_name = recurring_action_array[i].device_name;
            uint256 raid = recurring_action_array[i].recurring_action_id;
            uint256 rahid = recurring_action_array[i].recurring_action_history_id;

            uint _days = devices[device_name].device_recurring_actions[raid]._days * 86400;
            uint _time = recurring_action_history[raid][rahid].time;

            uint difference = now - (_days + _time);
            if (difference > 0) {
                disableRecurringAction(device_name, raid);
            } else {
                //                temp.push(RA(device_name, raid, rahid, true));
            }
        }

        //        recurring_action_array = temp;
        emit RecurringPaymentLog("Recurring payment callback.");
        RECURRING_PAYMENT_STEP = 2;
    }
}