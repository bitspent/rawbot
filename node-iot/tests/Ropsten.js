#!/usr/bin/env node
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('wss://ropsten.infura.io/ws'));

web3.eth.subscribe('pendingTransactions', function (error, result) {
    if (error)
        console.log(error);
})
    .on("data", function (transaction) {
        if (transaction != null) {
            web3.eth.getBlock("pending").then(result => {
                console.log(result)
            })
            web3.eth.getTransaction(transaction).then(object => {
                    if (object.to == null) {
                        return;
                    }
                    console.log(object.to);
                    // if (object.to != null) {
                    //     if (object.to === '0x17c2f280b11b9c2b34a91b7ffed5ced27b13b43a') {
                    //         console.log(object);
                    //     }
                    // }
                }
            ).catch(err => {

            })
        }
    });


