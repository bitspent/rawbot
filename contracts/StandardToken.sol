pragma solidity ^0.4.24;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}
import "./Owned.sol";
import "./FetchPrice.sol";

contract StandardToken is Owned, FetchPrice {

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public initSupply;
    address _rawbot_team;
    mapping(address => bool) public frozenAccount;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /*
        ERC-223 related
    */

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event ExchangeToEther(address _address, uint256 _amount_received, uint256 _amount_to_give);
    event ExchangeToRaw(address _address, uint256 _amount_received, uint256 _amount_to_give);

    /*
        Devices related
    */
    address[] public exchange_addresses;
    string[] public device_serial_numbers;

    mapping(address => mapping(string => Device)) devices;
    mapping(address => ActionHistory[]) public actionsHistoryOf;
    mapping(address => User) public historyOf;

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        initSupply = initialSupply * 10 ** uint256(decimals);
        _rawbot_team = msg.sender;
        balanceOf[_rawbot_team] = (totalSupply * 1) / 5;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
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

    function getBalance(address _address) public view returns (uint256){
        return balanceOf[_address];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddresses() view public returns (address[]) {
        return exchange_addresses;
    }

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


    event SendErrorMessage(string _error_message);
    event AddDevice(address _owner_address, address _device_address, string _device_serial_number, string _device_name, bool _success);
    event ActionAdd(string, uint, string, uint256, uint256, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);

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
    // "0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 1
    function performAction(address _device_address, string _device_serial_number, uint256 _action_id) public payable returns (bool success) {

        return true;
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Open", 20, 20
    function addAction(address _device_address, string _device_serial_number, string _action_name, uint256 _action_price, uint256 _action_duration) public returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            uint256 actions_length = devices[_device_address][_device_serial_number].device_actions.length;
            devices[_device_address][_device_serial_number].device_actions.push(Action(actions_length, _action_name, _action_price, _action_duration, true));
            emit ActionAdd(_device_serial_number, actions_length, _action_name, _action_price, _action_duration, true);
            return true;
        }
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 0
    function enableAction(address _device_address, string _device_serial_number, uint256 _action_id) public payable returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        }

        if (devices[_device_address][_device_serial_number].device_actions[_action_id].available == false) {
            emit SendErrorMessage("Device action id is not available.");
            return false;
        }

        if (balanceOf[msg.sender] < devices[_device_address][_device_serial_number].device_actions[_action_id].action_price) {
            emit SendErrorMessage("User doesn't have enough balance to perform action.");
            return false;
        }

        balanceOf[msg.sender] -= devices[_device_address][_device_serial_number].device_actions[_action_id].action_price;
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

    function getDeviceActionOf(address _device_address, string _device_serial_number, uint256 _index) public view returns (uint256, string, uint256, uint256, bool) {
        Action storage current_device_action = devices[_device_address][_device_serial_number].device_actions[_index];
        return (current_device_action.action_id, current_device_action.action_name, current_device_action.action_price, current_device_action.action_duration, current_device_action.available);
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
}