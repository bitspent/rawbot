pragma solidity ^0.4.24;

import "./Rawbot.sol";
import "./Oraclize.sol";

contract Device is usingOraclize {
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
        bool enabled;
        bool refunded;
        bool available;
    }

    event AddIPFSHash(uint, string);
    event RecurringPaymentLog(string);

    event Refund(uint, uint, uint, uint);
    event RefundAutomatic(uint, uint, uint, uint);

    event ActionAdd(uint _id, string _name, uint256 _price, uint256 _duration, bool _recurring, bool _refundable, bool _available);
    event ActionEnable(uint _id, string _name, uint256 _price, uint256 _duration, bool _recurring, bool _refundable, bool _enable, bool _available);
    event ActionDisable(uint _id, string _name, uint256 _price, uint256 _duration, bool _recurring, bool _refundable, bool _disable, bool _available);

    string private device_name;
    string private device_serial_number;
    address private device_owner;

    mapping(uint => Action) private actions;
    uint private action_index = 0;
    Rawbot private rawbot;
    address private rawbot_address;
    uint private hash_index = 0;

    mapping(uint => string) private ipfs_hash;
    mapping(bytes32 => uint256) private query_ids;
    mapping(uint256 => ActionHistory[]) private action_history;

    //0x5df248769d99e87d15af3cced8e61e68b2764ef4, "ABC", "Raspberry PI 3"
    constructor(address _rawbot_address, address _device_owner, string _device_serial_number, string _device_name) payable public {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        device_owner = _device_owner;
        device_serial_number = _device_serial_number;
        device_name = _device_name;
        rawbot = Rawbot(_rawbot_address);
        rawbot_address = _rawbot_address;
    }

    function() payable public {

    }

    function addImageHash(string _hash) public returns (bool) {
        ipfs_hash[hash_index] = _hash;
        hash_index++;
        return true;
        emit AddIPFSHash(hash_index, _hash);
    }

    function withdraw(uint256 value) public payable returns (bool success) {
        require(device_owner == msg.sender);
        require(rawbot.getBalance(address(this)) >= value * 1e18);
        rawbot.modifyBalance(address(this), - value);
        rawbot.modifyBalance(device_owner, value);
        return true;
    }

    //"Open", 50, 0, true, false
    function addAction(string action_name, uint256 action_price, uint256 action_duration, bool recurring, bool refundable) public payable returns (bool){
        require(device_owner == msg.sender);
        actions[action_index] = Action(action_index, action_name, action_price, action_duration, recurring, refundable, true);
        emit ActionAdd(
            action_index,
            action_name,
            action_price,
            action_duration,
            recurring,
            refundable,
            true
        );
        action_index++;
        return true;
    }

    function _enableAction(uint256 action_id) private returns (bool success) {
        require(
            actions[action_id].available == true
            && actions[action_id].recurring == true
            && actions[action_id].price <= rawbot.getBalance(action_history[action_id][action_history[action_id].length - 1].user)
            && oraclize_getPrice("URL") < address(this).balance
        );

        bytes32 query_id = oraclize_query(actions[action_id].duration * 86400, "URL", "");
        query_ids[query_id] = action_id;

        rawbot.modifyBalance(action_history[action_id][action_history[action_id].length - 1].user, - actions[action_id].price);
        rawbot.modifyBalance(address(this), actions[action_id].price);
        action_history[action_id].push(ActionHistory(action_history[action_id][action_history[action_id].length - 1].user, action_id, now, true, false, true));
        return true;
        emit ActionEnable(
            action_id,
            actions[action_id].name,
            actions[action_id].price,
            actions[action_id].duration,
            actions[action_id].recurring,
            actions[action_id].refundable,
            true,
            true
        );
    }

    function _disableAction(uint256 action_id) private returns (bool success){
        require(
            actions[action_id].available == true
            && action_history[action_id][action_history[action_id].length - 1].enabled == true
        );
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, false, false, true));
        emit ActionDisable(action_id, actions[action_id].name, actions[action_id].price, actions[action_id].duration, actions[action_id].recurring, actions[action_id].refundable, true, true);
        return true;
    }

    function enableAction(uint256 action_id) public payable returns (bool success) {
        require(
            actions[action_id].available == true
            && rawbot.getBalance(msg.sender) >= actions[action_id].price
            && (action_history[action_id].length == 0 || action_history[action_id][action_history[action_id].length - 1].enabled == false)
            && oraclize_getPrice("URL") < address(this).balance
        );

        bytes32 query_id;
        if (actions[action_id].recurring == true) {
            query_id = oraclize_query((actions[action_id].duration), "URL", "");
            query_ids[query_id] = action_id;
        } else {
            query_id = oraclize_query(actions[action_id].duration, "URL", "");
            query_ids[query_id] = action_id;
        }

        rawbot.modifyBalance(msg.sender, - actions[action_id].price);
        rawbot.modifyBalance(address(this), actions[action_id].price);
        action_history[action_id].push(ActionHistory(msg.sender, action_id, now, true, false, true));

        emit ActionEnable(action_id,
            actions[action_id].name,
            actions[action_id].price,
            actions[action_id].duration,
            actions[action_id].recurring,
            actions[action_id].refundable,
            true,
            true
        );
        return true;
    }

    function disableAction(uint256 action_id) public payable returns (bool success) {
        require(
            actions[action_id].available == true
            && action_history[action_id][action_history[action_id].length - 1].enabled == true
            && action_history[action_id][action_history[action_id].length - 1].user == msg.sender
        );
        action_history[action_id][action_history[action_id].length - 1].enabled = false;
        emit ActionDisable(
            action_id,
            actions[action_id].name,
            actions[action_id].price,
            actions[action_id].duration,
            actions[action_id].recurring,
            actions[action_id].refundable,
            true,
            true
        );
        return true;
    }

    //0, 0
    function refund(uint256 action_id, uint _action_history_id) payable public returns (bool) {
        require(
            msg.sender == device_owner
            && actions[action_id].available == true
            && actions[action_id].refundable == true
            && action_history[action_id][_action_history_id].available == true
            && action_history[action_id][_action_history_id].id == action_id
            && action_history[action_id][_action_history_id].refunded == false
            && rawbot.getBalance(address(this)) >= actions[action_id].price
        );
        rawbot.modifyBalance(msg.sender, - actions[action_id].price);
        rawbot.modifyBalance(action_history[action_id][_action_history_id].user, actions[action_id].price);

        action_history[action_id][_action_history_id].enabled = false;
        action_history[action_id][_action_history_id].refunded = true;
        return true;
        emit Refund(
            action_id,
            _action_history_id,
            actions[action_id].price,
            now
        );
    }

    //0, 0
    function refundAutomatic(uint256 action_id, uint256 _action_history_id) payable public returns (bool success) {
        require(
            actions[action_id].available == true
            && actions[action_id].refundable == true
            && action_history[action_id][_action_history_id].available == true
            && action_history[action_id][_action_history_id].enabled == true
            && action_history[action_id][_action_history_id].refunded == false
            && action_history[action_id][_action_history_id].id == action_id
            && action_history[action_id][_action_history_id].user == msg.sender
            && rawbot.getBalance(address(this)) >= actions[action_id].price
            && (action_history[action_id][_action_history_id].time + actions[action_id].duration) - now > 0
        );

        rawbot.modifyBalance(msg.sender, + actions[action_id].price);
        rawbot.modifyBalance(address(this), - actions[action_id].price);

        action_history[action_id][_action_history_id].enabled = false;
        action_history[action_id][_action_history_id].refunded == true;
        return true;
        emit RefundAutomatic(
            action_id,
            _action_history_id,
            actions[action_id].price,
            now
        );
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        uint id = query_ids[myid];
        if (actions[id].recurring == false) {
            _disableAction(id);
        } else {
            _enableAction(id);
        }
        delete query_ids[myid];
        emit RecurringPaymentLog("Recurring payment callback.");
    }

    function getAction(uint256 action_id) public view returns (uint256, string, uint256, uint256, bool, bool, bool) {
        return (
        actions[action_id].id,
        actions[action_id].name,
        actions[action_id].price,
        actions[action_id].duration,
        actions[action_id].recurring,
        actions[action_id].refundable,
        actions[action_id].available
        );
    }

    function getActionHistory(uint256 action_id, uint256 action_history_index) public view returns (address, uint256, uint256, bool, bool, bool) {
        return (
        action_history[action_id][action_history_index].user,
        action_history[action_id][action_history_index].id,
        action_history[action_id][action_history_index].time,
        action_history[action_id][action_history_index].enabled,
        action_history[action_id][action_history_index].refunded,
        action_history[action_id][action_history_index].available
        );
    }

    function getLastActionHistory(uint256 action_id) public view returns (address, uint256, uint256, bool, bool, bool) {
        return (
        action_history[action_id][action_history[action_id].length - 1].user,
        action_history[action_id][action_history[action_id].length - 1].id,
        action_history[action_id][action_history[action_id].length - 1].time,
        action_history[action_id][action_history[action_id].length - 1].enabled,
        action_history[action_id][action_history[action_id].length - 1].refunded,
        action_history[action_id][action_history[action_id].length - 1].available
        );
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

    function getDeviceBalance() public view returns (uint256){
        return address(this).balance;
    }

    function getRawbotAddress() public view returns (address){
        return rawbot_address;
    }

    function getTotalActions() public view returns (uint){
        return action_index;
    }

    function getTotalHashes() public view returns (uint){
        return hash_index;
    }
}