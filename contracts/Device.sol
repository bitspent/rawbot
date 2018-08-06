pragma solidity ^0.4.24;

import "./Rawbot.sol";

contract Device {

    string[] public device_serial_numbers;
    string public device_serial_number;
    string public device_name;
    address public device_owner;
    Action[] device_actions;
    ActionHistory[] device_history;

    event SendDeviceErrorMessage(string);
    event Testing(string);
    event SendErrorMessage(string);
    event ActionAdd(string, uint, string, uint256, uint256, bool, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);
    event Refund(uint, uint, uint, uint);

    constructor(address _device_owner, string _device_serial_number, string _device_name) payable public {
        device_serial_number = _device_serial_number;
        device_name = _device_name;
        device_owner = _device_owner;
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

    /*
        Add only owner can add actions
    */
    //"Open", 20, 20, true
    function addAction(string action_name, uint action_price, uint action_duration, bool refundable) public payable returns (bool){
        device_actions.push(Action(device_actions.length, action_name, action_price, action_duration, refundable, true));
        emit ActionAdd(device_serial_number, device_actions.length, action_name, action_price, action_duration, refundable, true);
        return true;
    }

    function enableAction(uint action_id) public payable returns (bool success) {
        require(device_actions[action_id].available == true);
        device_history.push(ActionHistory(msg.sender, action_id, device_actions[action_id].name, device_actions[action_id].price, device_actions[action_id].duration, now, true, false, true));
        emit ActionEnable(device_serial_number, action_id, device_actions[action_id].name, device_actions[action_id].price, device_actions[action_id].duration, true);
        return true;
    }

    function disableAction(uint action_id) public payable returns (bool success) {
        require(device_actions[action_id].available == true);
        device_history.push(ActionHistory(msg.sender, action_id, device_actions[action_id].name, device_actions[action_id].price, device_actions[action_id].duration, now, true, false, true));
        emit ActionDisable(device_serial_number, action_id, device_actions[action_id].name, device_actions[action_id].price, device_actions[action_id].duration, true);
        return true;
    }

    function refund(uint256 action_id, uint256 _action_history_id) payable public returns (bool) {
        require(msg.sender == device_owner);
        require(device_actions[action_id].available == true);
        require(device_actions[action_id].refundable == true);
        require(device_history[_action_history_id].available == true);
        require(device_history[_action_history_id].id == action_id);
        require(device_history[_action_history_id].refunded == false);
        emit Refund(action_id, _action_history_id, device_actions[action_id].price, now);
        return true;
    }

    function refundAutomatic(uint256 action_id, uint256 _action_history_id) payable public returns (bool success) {
        require(device_actions[action_id].available == true);
        require(device_actions[action_id].refundable == true);
        require(device_history[_action_history_id].available == true);
        require(device_history[_action_history_id].id == action_id);
        require(device_history[_action_history_id].refunded == false);
        uint time_passed = now - device_history[_action_history_id].time + device_history[_action_history_id].duration;
        require(time_passed < 0);
    }

    function getActionPrice(uint action_id) public view returns (uint) {
        return device_actions[action_id].price;
    }

    function isRefundable(uint action_id) public view returns (bool) {
        return device_actions[action_id].refundable;
    }

    function getOwner() public view returns (address) {
        return device_owner;
    }


    function withdrawFromDevice(address device_address, uint value) public payable returns (bool success) {
        require(device_owner == msg.sender);
        // require(rawbot.balanceOf[device_address] >= value);
        // rawbot.balanceOf[device_address] -= value;
        // rawbot.balanceOf[msg.sender] += value;
        return true;
    }

    function getDeviceOwner(address _address) public view returns (address) {
        return Device(_address).getOwner();
    }
}