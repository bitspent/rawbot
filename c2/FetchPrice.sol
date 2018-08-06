pragma solidity ^0.4.24;

import "./Oraclize.sol";

contract FetchPrice is usingOraclize {
    event OraclizeLog(string _description, uint256 _time);

    uint256 public ETH_PRICE = 0;
    uint256 public oraclize_fee = 0;
    uint256 public last_price_update = 0;
    PRICE_CHECKING_STATUS public price_status;

    enum PRICE_CHECKING_STATUS {
        NEEDED, PENDING, FETCHED
    }

    constructor() public payable {

    }

    function getEthereumPrice() public view returns (uint) {
        return ETH_PRICE;
    }

    function fetchOraclizeFee() public payable {
        oraclize_fee = oraclize_getPrice("URL");
    }

    function fetchEthereumPrice(uint timing) public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit OraclizeLog("Oraclize query was NOT sent, please add some ETH to cover for the query fee", now);
        } else {
            emit OraclizeLog("Oraclize query was sent, standing by for the answer..", now);
            oraclize_fee = oraclize_getPrice("URL");
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