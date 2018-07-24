var five = require("johnny-five");
var board = new five.Board();
let rawbot = require('node-rawbot');

let board_ready = false;

board.on("ready", function () {
    board_ready = true;
    turnOnLed(8);
});


function turnOnLed(number) {
    var led = new five.Led(number);
    led.on();
}

function turnOffLed(number) {
    var led = new five.Led(number);
    led.off();
}


rawbot.eventEmitter.on('enable action', (object) => {
    let serial_number = object.response.returnValues['1'];
    let action_id = object.response.returnValues['2'];
    let action_name = object.response.returnValues['3'];
    let action_cost = object.response.returnValues['4'];
    let action_duration = object.response.returnValues['5'];
    console.log(object)
    if (object.success) {
        setTimeout(() => {
            turnOffLed(8);
            turnOnLed(7);
        }, 1500);
    }
    console.log(object)
});

rawbot.eventEmitter.on('addAction', (object) => {

});