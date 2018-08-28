App = {
    web3Provider: null,
    contracts: {},
    account: null,
    init: function () {
        return App.initWeb3();
    },
    RawbotInstance: null,
    RawbotAddress: null,

    initWeb3: function () {
        if (typeof web3 !== 'undefined') {
            App.web3Provider = web3.currentProvider;
        } else {
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
        }
        web3 = new Web3(App.web3Provider);
        return App.initContract();
    },

    initContract: function () {
        $.getJSON('Rawbot.json', function (data) {
            var RawbotContract = web3.eth.contract(data.abi);
            var address = data.networks["1535475760790"].address;
            App.RawbotInstance = RawbotContract.at(address);
            App.RawbotAddress = address;
            console.log("Contract address: " + App.RawbotAddress);
            web3.eth.getAccounts(function (error, accounts) {
                if (error) {
                } else {
                    App.account = accounts[0];
                    console.log("User address: " + App.account);
                }
            });
        });
        return App.bindEvents();
    },

    bindEvents: function () {
        $(document).on('click', '#button_purchase', App.buy);
        $(document).on('click', '#button_withdraw', App.withdraw);
        // $(document).on('click', '.btn-refund-raw', App.refundRaw);
        // $(document).on('click', '.btn-add-device', App.add_device);
        // $(document).on('click', '.btn-lengthcontracts-device-contract', App.show_devices_amount);
    },

    getBalanceEthereum: function () {
        web3.eth.getBalance(App.account, function (err, result) {
            if (!err) {
                console.log("[ETH] Balance: " + result.valueOf() / 1e18);
                $("#balance_eth").html(result.valueOf() / 1e18);
            }
        });
    },

    getBalanceRawbot: function () {
        App.RawbotInstance.getBalance(App.account, function (err, result) {
            if (!err) {
                console.log("[RAWBOT] Balance: " + result.valueOf() / 1e18);
                $("#balance_rawbot").html(result.valueOf() / 1e18);
            }
        });
    },

    buy: function () {
        let rawbot_text = $("#input_rawbot_buy").val();
        let rawbot_amount = +rawbot_text;
        console.log(rawbot_amount);
        $.ajax({
            type: "GET",
            url: "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD",
            success: function (data) {
                let eth_price = data.USD;
                console.log(eth_price);
                let total_usd = rawbot_amount * 0.5;
                let ethereum = (total_usd / eth_price) * 1e18;
                console.log(ethereum);

                web3.eth.sendTransaction({
                    from: App.account,
                    to: App.RawbotAddress,
                    value: ethereum
                }, function (err, txHash) {
                    if (!err) {
                        console.log(txHash)
                        $('#txHash').html('Transaction hash: <a href="https://ropsten.etherscan.io/tx/' + txHash + '" target="_blank">' + txHash + '</a>');
                    } else {
                        console.log(err);
                    }
                });
            },
            error: function (data) {
                console.log(data)
            }
        });
    },

    withdraw: function () {
        let rawbot = $("#input_rawbot_buy").val();
        console.log(abcd);
    },

    getDevice: function (address, serial_number) {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getDevice.call(address, serial_number, function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getDeviceActions: function (address, serial_number) {
        App.getActionLengthOf(address, serial_number)
            .then(length => {
                if (length > 0) {
                    for (let i = 0; i < length; i++) {
                        App.getDeviceActionOf(address, serial_number, i).then(action => {
                            let t = "<tr>";
                            t += "<td>" + action[0] + "</td>";
                            t += "<td>" + action[1] + "</td>";
                            t += "<td>" + action[2] + "</td>";
                            t += "<td>" + action[3] + "</td>";
                            t += "<td>" + action[4] + "</td>";
                            t += "<td>" + action[5] + "</td>";
                            t += "<td><button type='button' class='btn btn-primary' onclick='App.enableAction(\"0x577ccfbd7b0ee9e557029775c531552a65d9e11d\", \"ABC1\"," + action[0] + ")'>Enable</button></td>";
                            $("#device_actions").prepend(t);
                        }).catch(errAction => {
                            console.log(errAction);
                        })
                    }
                }
            }).catch(errLength => {
            console.log(errLength);
        });
    },

    getDeviceActionOf: function (address, serial_number, index) {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getDeviceActionOf.call(address, serial_number, index, function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getDeviceActionHistoryOf: function (address, serial_number, index) {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getDeviceActionHistoryOf.call(address, serial_number, index, function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getActionLengthOf: function (address, serial_number) {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getActionLengthOf.call(address, serial_number, function (error, result) {
                if (!error) {
                    return resolve(result.c[0]);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getHistoryLengthOf: function (address, serial_number) {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getHistoryLengthOf.call(address, serial_number, function (error, result) {
                if (!error) {
                    return resolve(result.c[0]);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getAddresses: function () {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getAddresses.call(function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getEthereumPrice: function () {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getEthereumPrice.call(function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getCurrentSupply: function () {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getCurrentSupply.call(function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getBalance: function (address) {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getBalance.call(address, function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getContractBalance: function () {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getContractBalance.call(function (error, result) {
                if (!error) {
                    return resolve(result);
                } else {
                    return reject(error);
                }
            });
        });
    },

    getTotalDevices: function () {
        return new Promise((resolve, reject) => {
            App.RawbotInstance.getTotalDevices.call(function (error, result) {
                if (!error) {
                    return resolve(result.c[0]);
                } else {
                    return reject(error);
                }
            });
        });
    },


    buyRaw: function (event) {
        event.preventDefault();
        var raw_amount = $('#raw_amount_input').val();
        var total_raw_usd = raw_amount * 0.5;
        // console.log()

        $.ajax({
            type: "GET",
            url: "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD",
            success: function (data) {
                if (data['USD'] != null) {
                    var eth_price = data['USD'];

                    var eth_amount = total_raw_usd / 500;
                    var eth_amount_wei = eth_amount * 1e18;
                    console.log("Raw amount: " + raw_amount);
                    console.log("Total Raw USD: " + total_raw_usd);
                    console.log("ETH price: " + eth_price);
                    console.log("ETH amount: " + eth_amount);
                    console.log("ETH amount WEI: " + eth_amount_wei);
                    web3.eth.sendTransaction({
                        from: App.account,
                        to: App.ContractAddress,
                        value: eth_amount_wei
                    }, function (err, txHash) {
                        if (!err) {
                            $('#txHash').html('Transaction hash: <a href="https://ropsten.etherscan.io/tx/' + txHash + '" target="_blank">' + txHash + '</a>');
                        } else {
                            console.log(err);
                        }
                    });


                } else {

                }
            },
            error: function (data) {
                console.log(data)
            },
        });
    },

    addAction: function (address, serial_number) {
        let action_price = $('#action_price').val();
        let action_duration = $('#action_duration').val();
        let action_name = $('#action_name').val();
        App.RawbotInstance.addAction(address, serial_number, action_name, action_price, action_duration, {
            from: App.account
        }, function (err, res) {
            if (err) {
                console.log(err);
            } else {
                $("#tx_hash_addAction").html("Track your tx: <a href='https://ropsten.etherscan.io/tx/" + res + "' target='_blank'>" + res + "</a>");
            }
        });
    },

    enableAction: function (address, serial_number, action_id) {
        App.RawbotInstance.enableAction(address, serial_number, action_id, {
            from: App.account
        }, function (err, res) {
            if (err) {
                console.log(err);
            } else {
                alert("Track your tx: https://ropsten.etherscan.io/tx/" + res);
            }
        });
    },
};

$(function () {
    App.init();
    setTimeout(() => {
        App.getBalanceRawbot();
        App.getBalanceEthereum();
    }, 2000);
});