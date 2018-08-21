pragma solidity ^0.4.24;

import "./Rawbot.sol";
import "./Oraclize.sol";

contract Device is usingOraclize {

    struct RA {
        string device_name;
        uint256 recurring_action_id;
        uint256 recurring_action_history_id;
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

    event AddIPFSHash(uint, string);
    event RecurringPaymentLog(string);

    event Refund(uint, uint, uint, uint);
    event RefundAutomatic(uint, uint, uint, uint);
    event RecurrentRefund(uint, uint, uint, uint);
    event RecurrentRefundAutomatic(uint, uint, uint, uint);

    event ActionAdd(string, uint, string, uint256, uint256, bool, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);

    event RecurringActionAdd(string, uint, string, uint256, uint256, bool, bool);
    event RecurringActionEnable(string, uint, string, uint256, uint256, bool);
    event RecurringActionDisable(string, uint, string, uint256, uint256, bool);

    string private device_name;
    string private device_serial_number;
    address private device_owner;

    Action[] actions;
    RecurringAction[] recurring_actions;

    mapping(uint256 => ActionHistory[]) private action_history;
    mapping(uint256 => ActionHistory[]) private recurring_action_history;

    RA[] recurring_action_array;
    Rawbot private rawbot;
    address public constant rawbot_address = 0x5238527616882251df1ae2c5353dc6cf0a515fdc;
    uint public hash_index = 0;
    mapping(uint => string) ipfs_hash;


    uint256 public RECURRING_PAYMENT_STEP = 0;

    constructor(address _device_owner, string _device_serial_number, string _device_name) payable public {
        device_owner = _device_owner;
        rawbot = Rawbot(rawbot_address);
    }

    function addImageHash(string _hash) public returns (bool) {
        ipfs_hash[hash_index] = _hash;
        emit AddIPFSHash(hash_index, _hash);
        hash_index++;
        return true;
    }

    //"ABC", "Open", 20, 20, true
    function addAction(string device_serial_number, string action_name, uint256 action_price, uint256 action_duration, bool refundable) public payable returns (bool){
        require(device_owner == msg.sender);
        actions.push(Action(actions.length, action_name, action_price, action_duration, refundable, true));
        emit ActionAdd(device_serial_number, actions.length, action_name, action_price, action_duration, refundable, true);
        return true;
    }

    //"ABC", "Open", 20, 20, true
    function addRecurringAction(string device_serial_number, string action_name, uint256 action_price, uint256 _days, bool refundable) public payable returns (bool){
        require(device_owner == msg.sender);
        recurring_actions.push(RecurringAction(recurring_actions.length, action_name, action_price, _days, refundable, true));
        emit ActionAdd(device_serial_number, recurring_actions.length, action_name, action_price, _days, refundable, true);
        return true;
    }

    //"ABC", 0
    function enableAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        require(actions[action_id].available == true, "Device action id is not available");
        require(rawbot.getBalance(msg.sender) >= actions[action_id].price, "User doesn't have enough balance");
        rawbot.modifyBalance(msg.sender, - actions[action_id].price);
        rawbot.modifyBalance(device_owner, actions[action_id].price);
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, true, false, true));
        emit ActionEnable(device_serial_number, action_id, actions[action_id].name, actions[action_id].price, actions[action_id].duration, true);
        return true;
    }

    //"ABC", 0
    function enableRecurringAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        if (oraclize_getPrice("URL") > address(this).balance) {
            return false;
        } else {
            require(actions[action_id].available == true, "Device action id is not available");
            require(rawbot.getBalance(msg.sender) >= recurring_actions[action_id].price, "User doesn't have enough balance");
            recurring_action_history[action_id].push(ActionHistory(msg.sender, action_id, now, true, false, true));
            recurring_action_array.push(RA(device_serial_number, action_id, recurring_action_history[action_id].length - 1, true));
            rawbot.modifyBalance(msg.sender, - recurring_actions[action_id].price);
            rawbot.modifyBalance(device_owner, recurring_actions[action_id].price);
            oraclize_query(recurring_actions[action_id]._days * 60 * 60 * 24, "URL", "");
            RECURRING_PAYMENT_STEP = 1;
            emit ActionEnable(device_serial_number, action_id, recurring_actions[action_id].name, recurring_actions[action_id].price, recurring_actions[action_id]._days, true);
            return true;
        }
    }

    //"ABC", 0
    function disableAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        require(actions[action_id].available == true, "Device action id is not available");
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, false, false, true));
        emit ActionDisable(device_serial_number, action_id, actions[action_id].name, actions[action_id].price, actions[action_id].duration, true);
        return true;
    }

    //"ABC", 0
    function disableRecurringAction(string device_serial_number, uint256 action_id) public payable returns (bool success) {
        require(recurring_actions[action_id].available == true, "Device action id is not available");
        recurring_action_history[action_id].push(ActionHistory(msg.sender, action_id, now, false, false, true));
        emit ActionDisable(device_serial_number, action_id, recurring_actions[action_id].name, recurring_actions[action_id].price, recurring_actions[action_id]._days, true);
        return true;
    }

    //"ABC", 0, 0
    function refund(string device_serial_number, uint256 action_id, uint _action_history_id) payable public returns (bool) {
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
    function refundAutomatic(string device_serial_number, uint256 action_id, uint256 _action_history_id) payable public returns (bool success) {
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

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();

        RA[] storage temp_recurring_action_array;

        for (uint i = 0; i < recurring_action_array.length; i++) {
            require(recurring_action_history[raid][rahid].id == raid);
            string device_name = recurring_action_array[i].device_name;
            uint256 raid = recurring_action_array[i].recurring_action_id;
            uint256 rahid = recurring_action_array[i].recurring_action_history_id;

            uint _days = recurring_actions[raid]._days * 86400;
            uint _time = recurring_action_history[raid][rahid].time;
            uint difference = now - (_days + _time);
            if (difference > 0) {
                disableRecurringAction(device_name, raid);
            } else {
                temp_recurring_action_array.push(RA(recurring_action_array[i].device_name, recurring_action_array[i].recurring_action_id, recurring_action_array[i].recurring_action_history_id, recurring_action_array[i].available));
            }

            recurring_action_array = temp_recurring_action_array;
            RECURRING_PAYMENT_STEP++;
        }

        emit RecurringPaymentLog("Recurring payment callback.");
    }

    function getActionPrice(string device_serial_number, uint256 action_id) public view returns (uint) {
        return actions[action_id].price;
    }

    function isRefundable(string device_serial_number, uint256 action_id) public view returns (bool) {
        return actions[action_id].refundable;
    }

    function getDeviceOwner() public view returns (address) {
        return device_owner;
    }
}