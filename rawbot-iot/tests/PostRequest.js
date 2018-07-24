var request = require('request');

var options = {
    url: 'https://api.scriptrapps.io/raspberrypi/blink.js',
    method: 'POST',
    headers: {
        'User-Agent': 'request',
        'Authorization': ' bearer UDA5MzU1N0U4OTpzY3JpcHRyOjNEQ0M3M0YwMEJEMkJEQTJBQ0M1NDhCQUExOTY4RThG'
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
        var info = JSON.parse(body);
        console.log(info.response.result);
    }
}

request(options, callback);