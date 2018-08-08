pragma solidity ^0.4.24;

import "./StandardToken.sol";
import "./Oraclize.sol";

contract Rawbot is usingOraclize, StandardToken {
    address public _rawbot_team;
    address[] public exchange_addresses;
    mapping(address => User) public user;

    event OraclizeLog(string _description, uint256 _time);

    uint256 public ETH_PRICE = 0;
    uint256 public last_price_update = 0;
    PRICE_CHECKING_STATUS public price_status;

    enum PRICE_CHECKING_STATUS {
        NEEDED, PENDING, FETCHED
    }

    struct User {
        uint256 allowed_to_exchange;
        ExchangeHistory[] exchange_history;
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

    constructor() StandardToken(20000000, "Rawbot Test 1", "RWT") public payable {
        _rawbot_team = msg.sender;
        balanceOf[_rawbot_team] = (totalSupply * 1) / 5;
        totalSupply -= balanceOf[_rawbot_team];
        price_status = PRICE_CHECKING_STATUS.NEEDED;
        // fetchEthereumPrice(15);
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

    function withdraw(uint value) public payable returns (bool) {
        require(getExchangeLeftOf(msg.sender) > 0);
        require(getExchangeLeftOf(msg.sender) >= value);
        require(balanceOf[msg.sender] >= value);
        uint256 ether_to_send = (value * 1e18) / (2 * ETH_PRICE);
        msg.sender.transfer(ether_to_send);
        balanceOf[msg.sender] -= value;
        user[msg.sender].allowed_to_exchange -= value;
        emit ExchangeToEther(msg.sender, value, ether_to_send);
        return true;
    }

    function getAddresses() view public returns (address[]) {
        return exchange_addresses;
    }

    function getExchangeLeftOf(address _address) view public returns (uint256){
        return user[_address].allowed_to_exchange;
    }

    function getEthereumPrice() public view returns (uint) {
        return ETH_PRICE;
    }

    function getBalance(address _address) external view returns (uint256){
        return balanceOf[_address];
    }

    function modifyBalance(address _address, uint256 amount) external returns (bool) {
        require(balanceOf[_address] + amount >= 0);
        balanceOf[_address] += amount;
    }

    function fetchEthereumPrice(uint timing) public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit OraclizeLog("Oraclize query was NOT sent, please add some ETH to cover for the query fee", now);
        } else {
            emit OraclizeLog("Oraclize query was sent, standing by for the answer..", now);
            oraclize_query(timing, "URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
        }
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        ETH_PRICE = parseInt(result);
        emit OraclizeLog(result, now);
        last_price_update = now;
        price_status = PRICE_CHECKING_STATUS.FETCHED;
    }
}