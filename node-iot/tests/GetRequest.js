var request = require('request');

var options = {
    url: 'https://api.github.com/repos/request/request',
    method: 'GET',
    headers: {
        'User-Agent': 'request',
        'Authorization': ' bearer UDA5MzU1N0U4OTpzY3JpcHRyOjNEQ0M3M0YwMEJEMkJEQTJBQ0M1NDhCQUExOTY4RThG'
    }
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
        var info = JSON.parse(body);
        console.log(info.stargazers_count + " Stars");
        console.log(info.forks_count + " Forks");
    }
}

request(options, callback);