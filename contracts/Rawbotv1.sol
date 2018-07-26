pragma solidity ^0.4.24;

import "./Owned.sol";
import "./StandardToken.sol";
//import "./Oraclize.sol";

contract Rawbot is Owned, StandardToken {
    // , usingOraclize
    struct ExchangeAmount {
        uint256 raw_amount;
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

    struct PendingExchange {
        address _address;
        uint256 _value;
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
        string device_serial_number;
        string device_name;
        address user;
        address device_address;
        uint256 time;
    }

    struct Device {
        string device_serial_number;
        string device_name;
        uint256 device_balance;
        address device_owner;
        address device_address;
        bool available;
    }

    enum PRICE_CHECKING_STATUS {
        NEEDED, PENDING, FETCHED
    }

    event LogConstructorInitiated(string nextStep);
    event LogPriceUpdated(uint256 price);
    event LogNewOraclizeQuery(string description);

    event SendErrorMessage(string _error_message);
    event AddDevice(address _owner_address, address _device_address, string _device_serial_number, string _device_name, bool _success);
    event FrozenFunds(address target, bool frozen);

    event ActionAdd(string, uint, string, uint256, uint256, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);

    event ExchangeToEther(address _address, uint256 _amount_received, uint256 _amount_to_give);
    event ExchangeToRaw(address _address, uint256 _amount_received, uint256 _amount_to_give);

    uint256 public ETH_PRICE = 500;
    uint256 public oraclize_fee;
    uint256 public last_price_update;
    uint256 pending_exchange_index = 0;

    PendingExchange[] public pending;
    address[] public exchange_addresses;
    string[] public device_serial_numbers;
    PRICE_CHECKING_STATUS public price_status;

    mapping(address => ActionHistory[]) public actionsHistoryOf;
    mapping(string => Device) devices;
    mapping(address => bool) public frozenAccount;
    mapping(string => Action[]) actions;
    mapping(address => ExchangeAmount) public exchangeOf;
    mapping(address => ExchangeHistory[]) public exchangeHistoryOf;

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
        if (exchangeOf[msg.sender].raw_amount >= 0 && exchangeOf[msg.sender].raw_amount >= value && balanceOf[msg.sender] >= value) {
            msg.sender.transfer(((value / 2) / ETH_PRICE) * 1e18);
            balanceOf[msg.sender] -= value * 10 ** 18;
            exchangeOf[msg.sender].raw_amount -= value * 10 ** 18;
            emit ExchangeToEther(msg.sender, value, ((value / 2) / ETH_PRICE) * 1e18);
            return true;
        } else {
            return false;
        }
    }

    function() payable public {
        //        AddPendingExchange(msg.sender, msg.value);
        TestPayable();
        //        if (price_status == PRICE_CHECKING_STATUS.NEEDED) {
        //            price_status = PRICE_CHECKING_STATUS.PENDING;
        //            // fetchEthereumPrice();
        //        } else if (price_status == PRICE_CHECKING_STATUS.PENDING) {
        //        } else if (price_status == PRICE_CHECKING_STATUS.FETCHED) {
        //            if (now - last_price_update < 300) {
        //                ExecuteAllExchanges();
        //            } else {
        //                price_status = PRICE_CHECKING_STATUS.PENDING;
        //                // fetchEthereumPrice();
        //            }
        //        } else {
        //        }
    }

    function TestPayable() payable public {
        uint256 raw_amount = msg.value * ETH_PRICE * 2;
        balanceOf[msg.sender] += raw_amount;
        transfer(msg.sender, raw_amount);
        exchangeOf[msg.sender].raw_amount += raw_amount;
        addExchangeHistory(msg.sender, raw_amount, msg.value, ETH_PRICE, now);
        emit ExchangeToRaw(msg.sender, msg.value, raw_amount);
    }

    function AddPendingExchange(address _address, uint256 _value) public {
        pending.push(PendingExchange(_address, _value));
    }

    function addExchangeHistory(address _address, uint256 _raw_amount, uint256 _eth_received, uint256 _eth_price, uint256 _time_ms) public returns (bool){
        exchangeHistoryOf[_address].push(ExchangeHistory(_raw_amount, 0, _eth_received, _eth_price, _time_ms, true));
        if (exchangeOf[_address].available == false) {
            exchange_addresses.push(_address);
        }
        return true;
    }

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Raspberry PI 3"
    function addDevice(address _address, string _device_serial_number, string _device_name) public returns (bool success) {
        if (devices[_device_serial_number].available == false) {
            devices[_device_serial_number] = Device(_device_serial_number, _device_name, 0, msg.sender, _address, true);
            device_serial_numbers.push(_device_serial_number);
            emit AddDevice(msg.sender, _address, _device_serial_number, _device_name, true);
            return true;
        } else {
            emit SendErrorMessage("Device serial number is already available.");
            return false;
        }
    }

    //"ABC1", "Open", 20, 20
    function addAction(string _device_serial_number, string _action_name, uint256 _action_price, uint256 _action_duration) public returns (bool success) {
        if (devices[_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            uint256 actions_length = actions[_device_serial_number].length;
            actions[_device_serial_number].push(Action(actions_length, _action_name, _action_price, _action_duration, false, true));
            emit ActionAdd(_device_serial_number, actions_length, _action_name, _action_price, _action_duration, true);
            return true;
        }
    }

    //"ABC1", 1
    function enableAction(string _device_serial_number, uint256 _action_id) public payable returns (bool success) {
        if (devices[_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            actions[_device_serial_number][_action_id].action_enabled = true;
            actionsHistoryOf[msg.sender].push(ActionHistory(_action_id, actions[_device_serial_number][_action_id].action_name, actions[_device_serial_number][_action_id].action_price, actions[_device_serial_number][_action_id].action_duration, _device_serial_number, devices[_device_serial_number].device_name, msg.sender, devices[_device_serial_number].device_address, now));
            emit ActionEnable(_device_serial_number, _action_id, actions[_device_serial_number][_action_id].action_name, actions[_device_serial_number][_action_id].action_price, actions[_device_serial_number][_action_id].action_duration, true);
            return true;
        }
    }

    //"ABC1", 1
    function disableAction(string _device_serial_number, uint256 _action_id) public returns (bool success) {
        if (devices[_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        } else {
            actions[_device_serial_number][_action_id].action_enabled = false;
            actionsHistoryOf[msg.sender].push(ActionHistory(_action_id, actions[_device_serial_number][_action_id].action_name, actions[_device_serial_number][_action_id].action_price, actions[_device_serial_number][_action_id].action_duration, _device_serial_number, devices[_device_serial_number].device_name, msg.sender, devices[_device_serial_number].device_address, now));
            emit ActionDisable(_device_serial_number, _action_id, actions[_device_serial_number][_action_id].action_name, actions[_device_serial_number][_action_id].action_price, actions[_device_serial_number][_action_id].action_duration, true);
            return true;
        }
    }

    function getBalance(address _address) public view returns (uint256){
        return balanceOf[_address];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDeviceAction(string _device_serial_number, uint256 _action_id) public view returns (uint, string, uint256, uint256, bool){
        Action storage action = actions[_device_serial_number][_action_id];
        return (action.action_id, action.action_name, action.action_price, action.action_duration, action.action_enabled);
    }

    function getTotalDevices() public view returns (uint) {
        return (device_serial_numbers.length);
    }

    function getExchangesOf(address _address) view public returns (uint256){
        return exchangeOf[_address].raw_amount;
    }

    //gives error
    // function getDevice(string _device_serial_number) public view returns (string, string, uint256, address){
    //     return (devices[_device_serial_number].device_serial_number, devices[_device_serial_number].device_name, devices[_device_serial_number].device_balance, devices[_device_serial_number].device_address);
    // }

    // function getActionsLengthOf(string _device_serial_number) view public returns (uint256) {
    //     return actions[_device_serial_number].length;
    // }

    // function getActionOf(string _device_serial_number, uint256 _action_id) view public returns (uint256, string, uint256, uint256, bool, bool) {
    //     return (actions[_device_serial_number][_action_id].action_id,
    //     actions[_device_serial_number][_action_id].action_name,
    //     actions[_device_serial_number][_action_id].action_price,
    //     actions[_device_serial_number][_action_id].action_duration,
    //     actions[_device_serial_number][_action_id].action_enabled,
    //     actions[_device_serial_number][_action_id].available);
    // }

    // function getAddresses() view public returns (address[]) {
    //     return exchange_addresses;
    // }

    // function getEthereumPrice() public view returns (uint) {
    //     return ETH_PRICE;
    // }

    //    function fetchOraclizeFee() public payable {
    //        oraclize_fee = oraclize_getPrice("URL");
    //    }
    //
    //    function fetchEthereumPrice() public payable {
    //        if (oraclize_getPrice("URL") > address(this).balance) {
    //            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
    //        } else {
    //            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
    //            oraclize_fee = oraclize_getPrice("URL");
    //            oraclize_query(0, "URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    //        }
    //    }
    //
    //    function initEthereumPrice() public payable {
    //        if (oraclize_getPrice("URL") > address(this).balance) {
    //            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
    //        } else {
    //            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
    //            oraclize_fee = oraclize_getPrice("URL");
    //            oraclize_query(15, "URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    //        }
    //    }
    //
    //    function __callback(bytes32 myid, string result) {
    //        if (msg.sender != oraclize_cbAddress()) revert();
    //        ETH_PRICE = parseInt(result);
    //        emit LogPriceUpdated(ETH_PRICE);
    //        last_price_update = now;
    //        price_status = PRICE_CHECKING_STATUS.FETCHED;
    //        ExecuteAllExchanges();
    //    }
}