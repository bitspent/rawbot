pragma solidity ^0.4.24;

import "./DeviceData.sol";

contract Device is DeviceData {

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Raspberry PI 3"
    function addDevice(address _address, string _device_serial_number, string _device_name) public returns (bool success) {
        if (devices[_address][_device_serial_number].available == true) {
            emit SendErrorMessage("Device serial number is already available on the same address.");
            return false;
        }
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

    //"0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", "Open", 20, 20, true
    function addAction(address _device_address, string _device_serial_number, string _action_name, uint256 _action_price, uint256 _action_duration, bool _refundable) public payable returns (bool success) {
        if (devices[_device_address][_device_serial_number].available == false) {
            emit SendErrorMessage("Device serial number is not available.");
            return false;
        }
        uint actions_length = deviceActionsLength[_device_address][_device_serial_number];
        deviceActions[_device_address][_device_serial_number][actions_length] = Action(actions_length, _action_name, _action_price, _action_duration, _refundable, true);
        emit ActionAdd(_device_serial_number, actions_length, _action_name, _action_price, _action_duration, true);
        deviceActionsLength[_device_address][_device_serial_number]++;
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

        if (deviceActions[_device_address][_device_serial_number][_action_id].available == false) {
            emit SendErrorMessage("Device action id is not available.");
            return false;
        }

        if (balanceOf[msg.sender] < deviceActions[_device_address][_device_serial_number][_action_id].price) {
            emit SendErrorMessage("User doesn't have enough balance to perform action.");
            return false;
        }

        devices[_device_address][_device_serial_number].busy = true;
        balanceOf[msg.sender] -= deviceActions[_device_address][_device_serial_number][_action_id].price;
        balanceOf[devices[_device_address][_device_serial_number].owner] += deviceActions[_device_address][_device_serial_number][_action_id].price;

        uint actions_length = deviceActionsHistoryLength[_device_address][_device_serial_number];
        deviceActionsHistory[_device_address][_device_serial_number][actions_length] = ActionHistory(msg.sender, _action_id, deviceActions[_device_address][_device_serial_number][_action_id].name, deviceActions[_device_address][_device_serial_number][_action_id].price, deviceActions[_device_address][_device_serial_number][_action_id].duration, now, true, false, true);
        user[msg.sender].action_history.push(ActionHistory(msg.sender, _action_id, deviceActions[_device_address][_device_serial_number][_action_id].name, deviceActions[_device_address][_device_serial_number][_action_id].price, deviceActions[_device_address][_device_serial_number][_action_id].duration, now, true, false, true));
        emit ActionEnable(_device_serial_number, _action_id, deviceActions[_device_address][_device_serial_number][_action_id].name, deviceActions[_device_address][_device_serial_number][_action_id].price, deviceActions[_device_address][_device_serial_number][_action_id].duration, true);
        deviceActionsHistoryLength[_device_address][_device_serial_number]++;
        return true;
    }

    function withdrawFromDevice(address _address, string _device_serial_number, uint value) public payable returns (bool success) {
        if (devices[_address][_device_serial_number].owner != msg.sender) {
            return false;
        }

        if (devices[_address][_device_serial_number].balance < value) {
            return false;
        }

        devices[_address][_device_serial_number].balance -= value;
        balanceOf[msg.sender] += value;
        return true;
    }

    //    "0x577ccfbd7b0ee9e557029775c531552a65d9e11d", "ABC1", 1
    //    function disableAction(address _device_address, string _device_serial_number, uint256 _action_id) public payable returns (bool success) {
    //        if (devices[_device_address][_device_serial_number].available == false) {
    //            emit SendErrorMessage("Device serial number is not available.");
    //            return false;
    //        }
    //
    //        if (deviceActions[_device_address][_device_serial_number][_action_id].available == false) {
    //            emit SendErrorMessage("Device action id is not available.");
    //            return false;
    //        }
    //
    //        uint actions_length = deviceActionsHistoryLength[_device_address][_device_serial_number];
    //        deviceActionsHistory[_device_address][_device_serial_number][actions_length] = ActionHistory(msg.sender, _action_id, deviceActions[_device_address][_device_serial_number][_action_id].name, deviceActions[_device_address][_device_serial_number][_action_id].price, deviceActions[_device_address][_device_serial_number][_action_id].duration, now, true, false, true);
    //        user[msg.sender].action_history.push(ActionHistory(msg.sender, _action_id, deviceActions[_device_address][_device_serial_number][_action_id].name, deviceActions[_device_address][_device_serial_number][_action_id].price, deviceActions[_device_address][_device_serial_number][_action_id].duration, now, false, false, true));
    //        emit ActionDisable(_device_serial_number, _action_id, deviceActions[_device_address][_device_serial_number][_action_id].name, deviceActions[_device_address][_device_serial_number][_action_id].price, deviceActions[_device_address][_device_serial_number][_action_id].duration, true);
    //        deviceActionsHistoryLength[_device_address][_device_serial_number]++;
    //        return true;
    //    }

    //    function refund(address _device_address, string _device_serial_number, uint256 _action_id, uint256 _action_history_id) payable public returns (bool success) {
    //        if (devices[_device_address][_device_serial_number].available == false) {
    //            emit SendErrorMessage("Device serial number is not available.");
    //            return false;
    //        }
    //
    //        if (deviceActions[_device_address][_device_serial_number][_action_id].refundable == false) {
    //            emit SendErrorMessage("Device action is not refundable.");
    //            return false;
    //        }
    //
    //        if (deviceActions[_device_address][_device_serial_number][_action_id].available == false) {
    //            emit SendErrorMessage("Device action id is not available.");
    //            return false;
    //        }
    //
    //        if (deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].available == false) {
    //            emit SendErrorMessage("Device history index is not available.");
    //            return false;
    //        }
    //
    //        if (deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].refunded == true) {
    //            emit SendErrorMessage("Device action has been refunded.");
    //            return false;
    //        }
    //
    //        if (deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].id != _action_id) {
    //            emit SendErrorMessage("Device history action id doesn't match the action id.");
    //            return false;
    //        }
    //
    //        //        if (deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].duration + deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].time < now) {
    //        //            emit SendErrorMessage("User cannot be refunded.");
    //        //            return false;
    //        //        }
    //
    //        balanceOf[devices[_device_address][_device_serial_number].owner] -= deviceActions[_device_address][_device_serial_number][_action_id].price;
    //        balanceOf[deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].user] += deviceActions[_device_address][_device_serial_number][_action_id].price;
    //        deviceActionsHistory[_device_address][_device_serial_number][_action_history_id].refunded = true;
    //    }
}