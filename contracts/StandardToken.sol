pragma solidity ^0.4.24;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}
import "./Owned.sol";
// import "./FetchPrice.sol";
// import './SafeMath.sol';
import "./Device.sol";

contract StandardToken is Owned, Device {

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        initSupply = initialSupply * 10 ** uint256(decimals);
        _rawbot_team = msg.sender;
        balanceOf[_rawbot_team] = (totalSupply * 1) / 5;
        totalSupply -= balanceOf[_rawbot_team];
        name = tokenName;
        symbol = tokenSymbol;
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);
        // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Check for overflows
        require(!frozenAccount[_from]);
        // Check if sender is frozen
        require(!frozenAccount[_to]);
        // Check if recipient is frozen
        balanceOf[_from] -= _value;
        // Subtract from the sender
        balanceOf[_to] += _value;
        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
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

    function getBalance(address _address) public view returns (uint256){
        return balanceOf[_address];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
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

    function withdraw(uint value) public payable returns (bool success) {
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
}