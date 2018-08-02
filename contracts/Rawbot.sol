pragma solidity ^0.4.24;

import "./StandardToken.sol";

contract Rawbot is StandardToken {
    uint256 ETH_PRICE = 500;
    address[] public exchange_addresses;
    string[] public device_serial_numbers;

    struct User {
        uint256 allowed_to_exchange;
        ExchangeHistory[] exchange_history;
        ActionHistory[] action_history;
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

    struct Action {
        uint256 id;
        string name;
        uint256 price;
        uint256 duration;
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
        bool refunded;
    }

    struct Device {
        string name;
        uint256 balance;
        address owner;
        Action[] actions;
        ActionHistory[] history;
        bool busy;
        bool available;
    }

    event SendErrorMessage(string _error_message);
    event AddDevice(address _owner_address, address _device_address, string _device_serial_number, string _device_name, bool _success);
    event ActionAdd(string, uint, string, uint256, uint256, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);
    event Testing(string);

    mapping(address => mapping(string => Device)) devices;
    mapping(address => User) public user;

    constructor() StandardToken(20000000, "Rawbot Test 1", "RWT") public payable {
        // price_status = PRICE_CHECKING_STATUS.NEEDED;
        // initEthereumPrice();
        user[msg.sender].available = true;
        user[msg.sender].allowed_to_exchange += 4000000;
    }

    function() payable public {
        uint256 raw_amount = (msg.value * ETH_PRICE * 2) / 1e18;
        totalSupply -= raw_amount;
        balanceOf[msg.sender] += raw_amount;
        transfer(msg.sender, raw_amount);

        user[msg.sender].exchange_history.push(ExchangeHistory(raw_amount, 0, msg.value, ETH_PRICE, now, true));
        if (user[msg.sender].available == false) {
            exchange_addresses.push(msg.sender);
        }
        user[msg.sender].allowed_to_exchange += raw_amount;
        emit ExchangeToRaw(msg.sender, msg.value, raw_amount);
    }

    function withdraw(uint value) public returns (bool success) {
        if (user[msg.sender].allowed_to_exchange > 0 && user[msg.sender].allowed_to_exchange >= value && balanceOf[msg.sender] >= value) {
            uint256 ether_to_send = (value * 1e18) / (2 * ETH_PRICE);
            msg.sender.transfer(ether_to_send);
            balanceOf[msg.sender] -= value;
            user[msg.sender].allowed_to_exchange -= value;
            emit ExchangeToEther(msg.sender, value, ether_to_send);
            return true;
        }
        return false;
    }

    function withdrawFromDevice(address _address, string _device_serial_number, uint value) public returns (bool success) {
        if (devices[_address][_device_serial_number].owner != msg.sender) {
            return false;
        }

        if (devices[_address][_device_serial_number].balance < value) {
            return false;
        }

        devices[_address][_device_serial_number].balance -= value;
        balanceOf[msg.sender] -= value;
        return true;
    }

    function TestingFunction() public {
        addDevice(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", "Raspberry PI 3");
        addAction(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", "Open", 20, 20, true);
        enableAction(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", 0);
        disableAction(0x577ccfbd7b0ee9e557029775c531552a65d9e11d, "ABC1", 0);
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Raspberry PI 3"
    function addDevice(address _address, string _device_serial_number, string _device_name) public returns (bool success) {
        if (devices[_address][_device_serial_number].available == false) {
            Device storage current_device = devices[_address][_device_serial_number];
            current_device.name = _device_name;
            current_device.balance = 0;
            current_device.owner = msg.sender;
            current_device.busy = false;
            current_device.available = true;
            device_serial_numbers.push(_device_serial_number);
            emit AddDevice(msg.sender, _address, _device_serial_number, _device_name, true);
            return true;
        }

        emit SendErrorMessage("Device serial number is already available on the same address.");
        return false;
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Open", 20, 20, true
    function addAction(address _device_address, string _device_serial_number, string _action_name, uint256 _action_price, uint256 _action_duration, bool _refundable) public payable returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        }

        uint256 actions_length = devices[_device_address][_device_serial_number].actions.length;
        devices[_device_address][_device_serial_number].actions.push(Action(actions_length, _action_name, _action_price, _action_duration, _refundable, true));
        emit ActionAdd(_device_serial_number, actions_length, _action_name, _action_price, _action_duration, true);
        return true;
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 0
    function enableAction(address _device_address, string _device_serial_number, uint256 _action_id) public payable returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        }

        if (devices[_device_address][_device_serial_number].busy == true) {
            emit SendErrorMessage("Device serial number is busy.");
            return false;
        }

        if (devices[_device_address][_device_serial_number].actions[_action_id].available == false) {
            emit SendErrorMessage("Device action id is not available.");
            return false;
        }

        if (balanceOf[msg.sender] < devices[_device_address][_device_serial_number].actions[_action_id].price) {
            emit SendErrorMessage("User doesn't have enough balance to perform action.");
            return false;
        }

        devices[_device_address][_device_serial_number].busy = true;
        balanceOf[msg.sender] -= devices[_device_address][_device_serial_number].actions[_action_id].price;
        balanceOf[devices[_device_address][_device_serial_number].owner] += devices[_device_address][_device_serial_number].actions[_action_id].price;

        user[msg.sender].action_history.push(ActionHistory(
                msg.sender,
                _action_id,
                devices[_device_address][_device_serial_number].actions[_action_id].name,
                devices[_device_address][_device_serial_number].actions[_action_id].price,
                devices[_device_address][_device_serial_number].actions[_action_id].duration,
                now,
                false
            ));
        emit ActionEnable(
            _device_serial_number,
            _action_id,
            devices[_device_address][_device_serial_number].actions[_action_id].name,
            devices[_device_address][_device_serial_number].actions[_action_id].price,
            devices[_device_address][_device_serial_number].actions[_action_id].duration,
            true);
        return true;
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 1
    function disableAction(address _device_address, string _device_serial_number, uint256 _action_id) public returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        }

        devices[_device_address][_device_serial_number].busy = false;
        ActionHistory storage action_history;
        action_history.id = _action_id;
        action_history.name = devices[_device_address][_device_serial_number].actions[_action_id].name;
        action_history.price = devices[_device_address][_device_serial_number].actions[_action_id].price;
        action_history.duration = devices[_device_address][_device_serial_number].actions[_action_id].duration;
        action_history.time = now;
        devices[_device_address][_device_serial_number].history.push(action_history);

        user[msg.sender].action_history.push(ActionHistory(
                msg.sender,
                _action_id,
                devices[_device_address][_device_serial_number].actions[_action_id].name,
                devices[_device_address][_device_serial_number].actions[_action_id].price,
                devices[_device_address][_device_serial_number].actions[_action_id].duration,
                now,
                false
            ));
        emit ActionDisable(
            _device_serial_number,
            _action_id,
            devices[_device_address][_device_serial_number].actions[_action_id].name,
            devices[_device_address][_device_serial_number].actions[_action_id].price,
            devices[_device_address][_device_serial_number].actions[_action_id].duration,
            true);
        return true;
    }

    function getTotalDevices() public view returns (uint) {
        return (device_serial_numbers.length);
    }

    function getExchangeLeftOf(address _address) view public returns (uint256){
        return user[_address].allowed_to_exchange;
    }

    // "0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1"
    function getDevice(address _device_address, string _device_serial_number) public view returns (string, uint256, address, bool){
        Device storage current_device = devices[_device_address][_device_serial_number];
        return (current_device.name, current_device.balance, current_device.owner, current_device.available);
    }

    function getDeviceActionOf(address _device_address, string _device_serial_number, uint256 _index) public view returns (uint256, string, uint256, uint256, bool) {
        Action storage current_device_action = devices[_device_address][_device_serial_number].actions[_index];
        return (current_device_action.id, current_device_action.name, current_device_action.price, current_device_action.duration, current_device_action.available);
    }

    function getDeviceActionHistoryOf(address _device_address, string _device_serial_number, uint256 _index) public view returns (uint256, string, uint256, uint256, address, uint256) {
        ActionHistory storage current_device_history = devices[_device_address][_device_serial_number].history[_index];
        return (current_device_history.id, current_device_history.name, current_device_history.price, current_device_history.duration, current_device_history.user, current_device_history.time);
    }

    function getActionLengthOf(address _device_address, string _device_serial_number) view public returns (uint256) {
        return devices[_device_address][_device_serial_number].actions.length;
    }

    function getHistoryLengthOf(address _device_address, string _device_serial_number) view public returns (uint256) {
        return devices[_device_address][_device_serial_number].history.length;
    }

    function getAddresses() view public returns (address[]) {
        return exchange_addresses;
    }
}