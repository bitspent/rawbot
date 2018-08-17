pragma solidity ^0.4.24;

import "./StandardToken.sol";
import "./Oraclize.sol";
import "./MerchantManager.sol";

contract Rawbot is usingOraclize, StandardToken {

    address private _rawbot_team;
    address[] private exchange_addresses;
    address private ContractMerchantManagerAddress;
    mapping(address => User) private user;

    uint public index_starter = 0;
    uint public index_checker = 0;
    mapping(uint => transaction_exchange) transaction_exchanges;

    event OraclizeLog(string _description, uint256 _time);

    uint256 private ETH_PRICE = 500;
    uint256 private last_price_update = 0;
    PRICE_CHECKING_STATUS public price_status;

    enum PRICE_CHECKING_STATUS {
        NEEDED, PENDING, FETCHED
    }

    struct transaction_exchange {
        address _address;
        uint256 _eth;
        uint256 _time;
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

    /**
        Rawbot has 20,000,000 tokens.
        4,000,000 are held by the contract for the Rawbot team
        16,000,000 are circulating
    */
    constructor() StandardToken(20000000, "Rawbot Test 1", "RWT") public payable {
        _rawbot_team = msg.sender;
        balanceOf[_rawbot_team] = (totalSupply * 1) / 5;
        totalSupply -= balanceOf[_rawbot_team];
        price_status = PRICE_CHECKING_STATUS.NEEDED;
        //        fetchEthereumPrice(15);
        user[msg.sender].available = true;
        user[msg.sender].allowed_to_exchange += 4000000;
    }

    /**
        This method is used to receive Ethereum & transfer Raw coins in return to the user
        It adds them to transaction_exchanges mapping and executes all queued exchanges
        at the same time to avoid fetching Ethereum price at the same time
    */
    function() payable public {
        require(ETH_PRICE > 0, "ETH price isn't fetched yet");
        transaction_exchanges[index_starter] = transaction_exchange(msg.sender, msg.value, now);
        index_starter++;

        if (last_price_update - now > 300) {
            fetchEthereumPrice(0);
        } else {
            exchangeAll();
        }
    }

    /**
        This method is used to exchange Raw and get Ethereum in exchange
        It requires that the user has exchanged Ethereum to Raw previously
    */
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

    /**
        This method is used to modify user's balance externally
        It can only be used by created Merchant contract addresses
    */
    function modifyBalance(address _address, uint256 amount) external returns (bool) {
        MerchantManager merchantManager = MerchantManager(ContractMerchantManagerAddress);
        require(merchantManager.hasAccess(msg.sender) == true);
        require(balanceOf[_address] + amount >= 0);
        balanceOf[_address] += amount;
        return true;
    }

    /**
       This method is used to fetch the Ethereum price using Oraclize API
    */
    function fetchEthereumPrice(uint timing) onlyOwner public payable {
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
        exchangeAll();
    }

    /**
        This method is used to execute all queued exchanges at the same time
        Mapping is used instead of arrays to avoid gas spending
    */
    function exchangeAll() private {
        require(index_checker < index_starter);
        for (uint i = index_checker; i < index_starter; i++) {
            uint256 _eth = transaction_exchanges[index_checker]._eth;
            address _address = transaction_exchanges[index_checker]._address;
            uint256 time = transaction_exchanges[index_checker]._time;

            uint256 raw_amount = (_eth * ETH_PRICE * 2) / 1e18;
            totalSupply -= raw_amount;
            balanceOf[_address] += raw_amount;
            transfer(_address, raw_amount);

            user[_address].exchange_history.push(ExchangeHistory(raw_amount, 0, _eth, ETH_PRICE, time, true));
            if (user[_address].available == false) {
                exchange_addresses.push(_address);
            }
            user[_address].allowed_to_exchange += raw_amount;
            emit ExchangeToRaw(_address, _eth, raw_amount);
        }
        index_checker = index_starter;
    }

    /**
        This method is used to set the MerchantManager's address
        It's used to manipulate the modifyBalance function
    */
    function setContractMerchantManager(address _address) onlyOwner public returns (bool){
        ContractMerchantManagerAddress = _address;
        return true;
    }

    /**
        This method returns the MerchantManager's address
    */
    function getContractMerchantManager() public view returns (address) {
        return ContractMerchantManagerAddress;
    }

    /**
        This method returns the exchange addresses
    */
    function getAddresses() view public returns (address[]) {
        return exchange_addresses;
    }

    /**
        This method returns the amount of Raw left to exchange
    */
    function getExchangeLeftOf(address _address) view public returns (uint256){
        return user[_address].allowed_to_exchange;
    }

    /**
        This method returns the Ethereum price
    */
    function getEthereumPrice() public view returns (uint) {
        return ETH_PRICE;
    }

    /**
        This method returns the balance of a specific address
    */
    function getBalance(address _address) external view returns (uint256){
        return balanceOf[_address];
    }
}