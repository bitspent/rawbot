pragma solidity ^0.4.24;

contract DeviceData {
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    uint256 public initSupply;

    uint256 ETH_PRICE = 500;
    address public _rawbot_team;
    address[] public exchange_addresses;
    string[] public device_serial_numbers;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event ExchangeToEther(address, uint256, uint256);
    event ExchangeToRaw(address, uint256, uint256);
    event Testing(string);

    event SendErrorMessage(string);
    event AddDevice(address, address, string, string, bool);
    event ActionAdd(string, uint, string, uint256, uint256, bool);
    event ActionEnable(string, uint, string, uint256, uint256, bool);
    event ActionDisable(string, uint, string, uint256, uint256, bool);

    mapping(address => User) public user;
    mapping(address => mapping(string => Device)) devices;
    mapping(address => mapping(string => uint)) deviceActionsLength;
    mapping(address => mapping(string => uint)) deviceActionsHistoryLength;
    mapping(address => mapping(string => mapping(uint => Action))) deviceActions;
    mapping(address => mapping(string => mapping(uint => ActionHistory))) deviceActionsHistory;
    mapping(address => bool) public frozenAccount;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

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
        bool enable;
        bool refunded;
        bool available;
    }

    struct Device {
        string name;
        uint256 balance;
        address owner;
        bool busy;
        bool available;
    }

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
}