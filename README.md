# Rawbot

[![N|Solid](http://rawbot.org/img/rawbot_logo_colored.png)](http://rawbot.org)

Rawbot is a framework, more precisely a collection of configurations/scripts/hacks with an underlying currency named RAW with the purpose of facilitating the implementation of payment gateways to activate digital services on a variety of IoT enabled devices such as Raspberry Pi, Arduino, Beagleboard, particle, drones, electric cars and more.

Rawbot utilizes RAW coin, an Ethereum guaranteed token that can be exchanged to ETH through a smart contract at any moment.

We have acquired experience in use cases from different Industries to address technical issues that may arise during the process on both client and merchant level, this experience will be invested in supporting users to achieve a seamless implementation.

## Methods
 - addAction(address, string _device_serial_number, string _action_name, uint256 _action_price, uint256 _action_duration): bool
 - addDevice(address _address, string _device_serial_number, string _device_name): bool
 - disableAction(address _device_address, string _device_serial_number, uint256 _action_id): bool
 - enableAction(address _device_address, string _device_serial_number, uint256 _action_id): bool
 - withdraw(uint value): bool

## Getters

## Contact
  - Website: http://rawbot.org
  - Whitepaper: http://rawbot.org/rawbot_whitepaper.pdf
