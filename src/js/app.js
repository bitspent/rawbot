App = {
    web3Provider: null,
    contracts: {},
    account: null,
    init: function () {
        return App.initWeb3();
    },
    ContractInstance: null,
    ContractAddress: null,
    DefaultContractInstance: null,

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
            var AdoptionArtifact = data;
            var RawbotContract = web3.eth.contract(data.abi);
            App.contracts.Rawbot = TruffleContract(AdoptionArtifact);
            App.contracts.Rawbot.setProvider(App.web3Provider);
            App.contracts.Rawbot.deployed().then(f => {
                App.ContractInstance = f;
                App.ContractAddress = f.contract.address;
                App.DefaultContractInstance = RawbotContract.at(f.contract.address);
                console.log("User address: " + App.account);
                console.log("Contract address: " + App.ContractAddress);
            });
            web3.eth.getAccounts(function (error, accounts) {
                if (error) {
                } else {
                    App.account = accounts[0];
                }
            });
        });

        return App.bindEvents();
    },

    bindEvents: function () {
        $(document).on('click', '.btn-buy-raw', App.buyRaw);
        $(document).on('click', '.btn-refund-raw', App.refundRaw);
        $(document).on('click', '.btn-add-device', App.add_device);
        $(document).on('click', '.btn-lengthcontracts-device-contract', App.show_devices_amount);
    },

    getContractAddress: function () {
        App.contracts.Rawbot.deployed().then(f => {
            alert('https://etherscan.io/address/' + f.contract.address);
        });
    },

    addresses: function () {
        // event.preventDefault();
        var Rawbot;
        App.contracts.Rawbot.deployed()
            .then(function (instance) {
                Rawbot = instance;
                console.log(Rawbot)
                return Rawbot.getAddresses.call();
            })
            .then(function (result) {
                alert(result);
            })
            .catch(function (err) {
                console.log(err.message);
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

    refundRaw: function (event) {
        event.preventDefault();
        var raw_amount = $('#raw_amount_output').val();

        App.ContractInstance.withdraw(raw_amount, {
            from: App.account
        }).then(response => {
            console.log(response)
        }).catch(err => {
            console.log(err)
        })
    },

    add_device: function (event) {
        // event.preventDefault();
        var serial_number = $(' #raw_device_add_device_serial_number').val();
        var device_name = $('#raw_device_add_device_name').val();


        App.DefaultContractInstance.addDevice(serial_number, device_name, {from: App.account}, function (error, result) {
            if (!error) {
                console.log(result)
            } else {
                console.log(error)
            }
        });
    },

    show_devices_amount: function (event) {
        event.preventDefault();
        App.contracts.Rawbot.deployed()
            .then(function (instance) {
                Rawbot = instance;
                return Rawbot.getDevicesLength.call();
            })
            .then(function (result) {
                $('#myAddedLengthDeviceContract').html("Amount of devices created: " + result);
            })
            .catch(function (err) {
                console.log(err.message);
            });
    },
};

$(function () {
    if (isUsingMobileDevice() && !isUsingTrustWallet()) {
        window.location.replace('https://links.trustwalletapp.com/xy7kAQY7gO');
    } else {
        App.init();
    }
});

function isUsingTrustWallet() {
    return navigator.userAgent.match(/Trust/i);
}

function isUsingMobileDevice() {
    return (navigator.userAgent.match(/Android/i)
        || navigator.userAgent.match(/webOS/i)
        || navigator.userAgent.match(/iPhone/i)
        || navigator.userAgent.match(/iPad/i)
        || navigator.userAgent.match(/iPod/i)
        || navigator.userAgent.match(/BlackBerry/i)
        || navigator.userAgent.match(/Windows Phone/i)
    );
}