pragma solidity ^0.4.24;

import "./Owned.sol";
import "./StandardToken.sol";
// import "./Oraclize.sol";, usingOraclize

contract Rawbot is Owned, StandardToken {

    uint256 public ETH_PRICE = 500;
    uint256 public oraclize_fee;
    uint256 public last_price_update;

    address[] public exchange_addresses;
    string[] public device_serial_numbers;
    PRICE_CHECKING_STATUS public price_status;

    mapping(address => mapping(string => Device)) devices;
    mapping(address => bool) public frozenAccount;
    mapping(address => ActionHistory[]) public actionsHistoryOf;

    mapping(address => User) public historyOf;

    struct User {
        uint256 allowed_to_exchange;
        ExchangeHistory[] history;
        bool available;
    }

    struct ExchangeHistory {
        uint256 raw_amount;
        uint256 raw_exchange;
        uint256 eth_received;
        uint256 eth_price;
        uint256 time_ms;
        bool available;
    }

    struct UserHistory {
        uint256 action_id;
        string action_name;
        uint256 action_price;
        uint256 action_duration;
        string device_serial_number;
        string device_name;
        address user;
        address device_address;
        uint256 time;
    }

    struct Action {
        uint256 action_id;
        string action_name;
        uint256 action_price;
        uint256 action_duration;
        bool action_enabled;
        bool available;
    }

    struct ActionHistory {
        uint256 action_id;
        string action_name;
        uint256 action_price;
        uint256 action_duration;
        address user;
        uint256 time;
    }

    struct Device {
        string device_name;
        uint256 device_balance;
        address device_owner;
        Action[] device_actions;
        ActionHistory[] device_history;
        bool available;
    }

    enum PRICE_CHECKING_STATUS {
        NEEDED, PENDING, FETCHED
    }

    event OraclizeLog(string _description, uint256 _time);
    event LogNewOraclizeQuery(string description);

    event SendErrorMessage(string _error_message);
    event AddDevice(address _owner_address, address _device_address, string _device_serial_number, string _device_name, bool _success);
    event FrozenFunds(address target, bool frozen);

    event ActionAdd(string, uint, string, uint256, uint256, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);

    event ExchangeToEther(address _address, uint256 _amount_received, uint256 _amount_to_give);
    event ExchangeToRaw(address _address, uint256 _amount_received, uint256 _amount_to_give);

    constructor() StandardToken(20000000, "Rawbot Test 1", "RWT") public payable {
        price_status = PRICE_CHECKING_STATUS.NEEDED;
        // initEthereumPrice();
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function increaseSupply() public onlyOwner {
        initSupply = initSupply * 2;
        totalSupply += initSupply;
    }

    function getCurrentSupply() public view returns (uint256){
        return initSupply;
    }

    function withdraw(uint value) public returns (bool success) {
        if (historyOf[msg.sender].allowed_to_exchange >= 0 && historyOf[msg.sender].allowed_to_exchange >= value && balanceOf[msg.sender] >= value) {
            msg.sender.transfer(((value / 2) / ETH_PRICE) * 1e18);
            balanceOf[msg.sender] -= value * 10 ** 18;
            historyOf[msg.sender].allowed_to_exchange -= value * 10 ** 18;
            emit ExchangeToEther(msg.sender, value, ((value / 2) / ETH_PRICE) * 1e18);
            return true;
        } else {
            return false;
        }
    }

    function() payable public {
        uint256 raw_amount = msg.value * ETH_PRICE * 2;
        balanceOf[msg.sender] += raw_amount;
        transfer(msg.sender, raw_amount);
        historyOf[msg.sender].allowed_to_exchange += raw_amount;
        addExchangeHistory(msg.sender, raw_amount, msg.value, ETH_PRICE, now);
        emit ExchangeToRaw(msg.sender, msg.value, raw_amount);
    }

    //"0xf1e7282908c481d2647fa1242fd411ed1d93d212", 100, 1e18, 500, 123123
    function addExchangeHistory(address _address, uint256 _raw_amount, uint256 _eth_received, uint256 _eth_price, uint256 _time_ms) public returns (bool){
        historyOf[msg.sender].history.push(ExchangeHistory(_raw_amount, 0, _eth_received, _eth_price, _time_ms, true));
        if (historyOf[_address].available == false) {
            exchange_addresses.push(_address);
        }
        return true;
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Raspberry PI 3"
    function addDevice(address _address, string _device_serial_number, string _device_name) public returns (bool success) {
        if (devices[_address][_device_serial_number].available == false) {
            Device storage current_device = devices[_address][_device_serial_number];
            current_device.device_name = _device_name;
            current_device.device_balance = 0;
            current_device.device_owner = msg.sender;
            current_device.available = true;
            device_serial_numbers.push(_device_serial_number);
            emit AddDevice(msg.sender, _address, _device_serial_number, _device_name, true);
            return true;
        } else {
            emit SendErrorMessage("Device serial number is already available on the same address.");
            return false;
        }
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Open", 20, 20
    function addAction(address _device_address, string _device_serial_number, string _action_name, uint256 _action_price, uint256 _action_duration) public returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            uint256 actions_length = devices[_device_address][_device_serial_number].device_actions.length;
            devices[_device_address][_device_serial_number].device_actions.push(Action(actions_length, _action_name, _action_price, _action_duration, false, true));
            emit ActionAdd(_device_serial_number, actions_length, _action_name, _action_price, _action_duration, true);
            return true;
        }
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 1
    function enableAction(address _device_address, string _device_serial_number, uint256 _action_id) public payable returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            // actions[_device_serial_number].devce[_action_id].action_enabled = true;
            ActionHistory storage action_history;
            action_history.action_id = _action_id;
            action_history.action_name = devices[_device_address][_device_serial_number].device_actions[_action_id].action_name;
            action_history.action_price = devices[_device_address][_device_serial_number].device_actions[_action_id].action_price;
            action_history.action_duration = devices[_device_address][_device_serial_number].device_actions[_action_id].action_duration;
            action_history.user = msg.sender;
            action_history.time = now;
            devices[_device_address][_device_serial_number].device_history.push(action_history);

            actionsHistoryOf[msg.sender].push(action_history);
            emit ActionEnable(
                _device_serial_number,
                _action_id,
                action_history.action_name,
                action_history.action_price,
                action_history.action_duration,
                true);
            return true;
        }
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 1
    function disableAction(address _device_address, string _device_serial_number, uint256 _action_id) public returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            ActionHistory storage action_history;
            action_history.action_id = _action_id;
            action_history.action_name = devices[_device_address][_device_serial_number].device_actions[_action_id].action_name;
            action_history.action_price = devices[_device_address][_device_serial_number].device_actions[_action_id].action_price;
            action_history.action_duration = devices[_device_address][_device_serial_number].device_actions[_action_id].action_duration;
            action_history.user = msg.sender;
            action_history.time = now;
            devices[_device_address][_device_serial_number].device_history.push(action_history);

            // devices[_device_address][_device_serial_number].device_actions[_action_id].action_enabled = false;
            // actionsHistoryOf[msg.sender].push(ActionHistory(_action_id, actions[_device_serial_number][_action_id].action_name, actions[_device_serial_number][_action_id].action_price, actions[_device_serial_number][_action_id].action_duration, _device_serial_number, devices[_device_serial_number].device_name, msg.sender, devices[_device_serial_number].device_address, now));
            emit ActionDisable(
                _device_serial_number,
                _action_id,
                action_history.action_name,
                action_history.action_price,
                action_history.action_duration,
                true);
            return true;
        }
    }

    function getBalance(address _address) public view returns (uint256){
        return balanceOf[_address];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalDevices() public view returns (uint) {
        return (device_serial_numbers.length);
    }

    function getExchangeLeftOf(address _address) view public returns (uint256){
        return historyOf[_address].allowed_to_exchange;
    }

    // "0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1"
    function getDevice(address _device_address, string _device_serial_number) public view returns (string, uint256, address, bool){
        Device storage current_device = devices[_device_address][_device_serial_number];
        return (current_device.device_name, current_device.device_balance, current_device.device_owner, current_device.available);
    }

    function getDeviceActionOf(address _device_address, string _device_serial_number, uint256 _index) public view returns (uint256, string, uint256, uint256, bool, bool) {
        Action storage current_device_action = devices[_device_address][_device_serial_number].device_actions[_index];
        return (current_device_action.action_id, current_device_action.action_name, current_device_action.action_price, current_device_action.action_duration, current_device_action.action_enabled, current_device_action.available);
    }

    function getDeviceActionHistoryOf(address _device_address, string _device_serial_number, uint256 _index) public view returns (uint256, string, uint256, uint256, address, uint256) {
        ActionHistory storage current_device_history = devices[_device_address][_device_serial_number].device_history[_index];
        return (current_device_history.action_id, current_device_history.action_name, current_device_history.action_price, current_device_history.action_duration, current_device_history.user, current_device_history.time);
    }

    function getActionLengthOf(address _device_address, string _device_serial_number) view public returns (uint256) {
        return devices[_device_address][_device_serial_number].device_actions.length;
    }

    function getHistoryLengthOf(address _device_address, string _device_serial_number) view public returns (uint256) {
        return devices[_device_address][_device_serial_number].device_history.length;
    }

    function getAddresses() view public returns (address[]) {
        return exchange_addresses;
    }

    function getEthereumPrice() public view returns (uint) {
        return ETH_PRICE;
    }

    // function fetchOraclizeFee() public payable {
    //     oraclize_fee = oraclize_getPrice("URL");
    // }

    // function fetchEthereumPrice() public payable {
    //     if (oraclize_getPrice("URL") > address(this).balance) {
    //         emit OraclizeLog("Oraclize query was NOT sent, please add some ETH to cover for the query fee", now);
    //     } else {
    //         emit OraclizeLog("Oraclize query was sent, standing by for the answer..", now);
    //         oraclize_fee = oraclize_getPrice("URL");
    //         oraclize_query(0, "URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    //     }
    // }

    // function initEthereumPrice() public payable {
    //     if (oraclize_getPrice("URL") > address(this).balance) {
    //         emit OraclizeLog("Oraclize query was NOT sent, please add some ETH to cover for the query fee", now);
    //     } else {
    //         emit OraclizeLog("Oraclize query was sent, standing by for the answer..", now);
    //         oraclize_fee = oraclize_getPrice("URL");
    //         oraclize_query(15, "URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    //     }
    // }

    // function __callback(bytes32 myid, string result) {
    //     if (msg.sender != oraclize_cbAddress()) revert();
    //     ETH_PRICE = parseInt(result);
    //     emit OraclizeLog(result, now);
    //     last_price_update = now;
    //     price_status = PRICE_CHECKING_STATUS.FETCHED;
    // }
}