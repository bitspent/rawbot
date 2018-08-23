pragma solidity ^0.4.24;

import "./Rawbot.sol";
import "./Oraclize.sol";

contract Device is usingOraclize {

    struct RA {
        uint256 action_id;
        uint256 history_id;
        bool available;
    }

    struct Action {
        uint256 id;
        string name;
        uint256 price;
        uint256 duration;
        bool recurring;
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

    event AddIPFSHash(uint, string);
    event RecurringPaymentLog(string);

    event Refund(uint, uint, uint, uint);
    event RefundAutomatic(uint, uint, uint, uint);

    event ActionAdd(uint _id, string _name, uint256 _price, uint256 _duration, bool _recurring, bool _refundable, bool _available);
    event ActionEnable(uint _id, string _name, uint256 _price, uint256 _duration, bool _recurring, bool _refundable, bool _available);
    event ActionDisable(uint _id, string _name, uint256 _price, uint256 _duration, bool _recurring, bool _refundable, bool _available);

    string private device_name;
    string private device_serial_number;
    address private device_owner;

    Action[] actions;

    mapping(uint256 => ActionHistory[]) private action_history;

    RA[] recurring_action_array;
    Rawbot private rawbot;
    address public constant rawbot_address = 0xb2992f579ed42387cd583bfac8fd16bd59b55fc5;
    uint public hash_index = 0;
    mapping(uint => string) ipfs_hash;


    uint256 public RECURRING_PAYMENT_STEP = 0;

    //0x50165970a40f9cf945a7f7c6b8a9d9d593d60ee4, "ABC", "Raspberry PI 3"
    constructor(address _device_owner, string _device_serial_number, string _device_name) payable public {
        device_owner = _device_owner;
        device_serial_number = _device_serial_number;
        device_name = _device_name;
        rawbot = Rawbot(rawbot_address);
    }

    function addImageHash(string _hash) public returns (bool) {
        ipfs_hash[hash_index] = _hash;
        emit AddIPFSHash(hash_index, _hash);
        hash_index++;
        return true;
    }

    //"Open", 50, 0, true, false
    function addAction(string action_name, uint256 action_price, uint256 action_duration, bool recurring, bool refundable) public payable returns (bool){
        require(device_owner == msg.sender);
        actions.push(Action(actions.length, action_name, action_price, action_duration, recurring, refundable, true));
        emit ActionAdd(actions.length, action_name, action_price, action_duration, recurring, refundable, true);
        return true;
    }

    //"ABC", 0
    function enableAction(uint256 action_id) public payable returns (bool success) {
        require(actions[action_id].available == true, "Device action id is not available");
        require(rawbot.getBalance(msg.sender) >= actions[action_id].price, "User doesn't have enough balance");

        if (actions[action_id].recurring == true) {
            // require(oraclize_getPrice("URL") > address(this).balance);
            oraclize_query(actions[action_id].duration * 86400, "URL", "");
            recurring_action_array.push(RA(action_id, action_history[action_id].length - 1, true));
        }

        rawbot.modifyBalance(msg.sender, - actions[action_id].price);
        rawbot.modifyBalance(device_owner, actions[action_id].price);
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, true, false, true));
        emit ActionEnable(action_id, actions[action_id].name, actions[action_id].price, actions[action_id].duration, actions[action_id].recurring, actions[action_id].refundable, true);
        return true;
    }

    //"ABC", 0
    function disableAction(uint256 action_id) public payable returns (bool success) {
        require(actions[action_id].available == true, "Device action id is not available");
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, false, false, true));
        emit ActionDisable(action_id, actions[action_id].name, actions[action_id].price, actions[action_id].duration, actions[action_id].recurring, actions[action_id].refundable, true);
        return true;
    }


    //"ABC", 0, 0
    function refund(uint256 action_id, uint _action_history_id) payable public returns (bool) {
        require(msg.sender == device_owner);
        require(actions[action_id].available == true);
        require(actions[action_id].refundable == true);
        require(action_history[action_id][_action_history_id].available == true);
        require(action_history[action_id][_action_history_id].id == action_id);
        require(action_history[action_id][_action_history_id].refunded == false);
        rawbot.modifyBalance(msg.sender, actions[action_id].price);
        emit Refund(action_id, _action_history_id, actions[action_id].price, now);
        return true;
    }

    //"ABC", 0, 0
    function refundAutomatic(uint256 action_id, uint256 _action_history_id) payable public returns (bool success) {
        require(actions[action_id].available == true);
        require(actions[action_id].refundable == true);
        require(action_history[action_id][_action_history_id].available == true);
        require(action_history[action_id][_action_history_id].id == action_id);
        require(action_history[action_id][_action_history_id].refunded == false);
        uint256 time_passed = now - (action_history[action_id][_action_history_id].time + actions[action_id].duration);
        require(time_passed < 0);
        emit RefundAutomatic(action_id, _action_history_id, actions[action_id].price, now);
        return true;
    }

    function getActionPrice(uint256 action_id) public view returns (uint) {
        return actions[action_id].price;
    }

    function isRefundable(uint256 action_id) public view returns (bool) {
        return actions[action_id].refundable;
    }

    function getDeviceOwner() public view returns (address) {
        return device_owner;
    }

    function getDeviceName() public view returns (string) {
        return device_name;
    }

    function getDeviceSerialNumber() public view returns (string) {
        return device_serial_number;
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();

        RA[] storage temp_recurring_action_array;
        for (uint i = 0; i < recurring_action_array.length; i++) {
            require(action_history[id][hid].id == id);

            uint256 id = recurring_action_array[i].action_id;
            uint256 hid = recurring_action_array[i].history_id;

            uint _days = actions[id].duration * 1 days;
            uint _time = action_history[id][hid].time;
            uint difference = now - (_days + _time);
            if (difference > 0) {
                disableAction(id);
            } else {
                temp_recurring_action_array.push(RA(recurring_action_array[i].action_id, recurring_action_array[i].history_id, recurring_action_array[i].available));
            }

            recurring_action_array = temp_recurring_action_array;
            RECURRING_PAYMENT_STEP++;
        }

        emit RecurringPaymentLog("Recurring payment callback.");
    }
}