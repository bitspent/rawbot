var Cylon = require("cylon");
var piinfo = require('piinfo');
let duration = 10;
let RaspberryPICylon = Cylon.robot({
    connections: {
        raspi: {adaptor: 'raspi'}
    },

    devices: {
        led: {driver: 'led', pin: 12}
    },

    work: function (my) {
        my.led.toggle();

        setTimeout(() => {
            my.led.toggle();
        }, duration);
    }
});

function getHardwareInfo() {
    return {
        serial: piinfo.serial(),
        hardware: piinfo.hardware(),
        revision: piinfo.revision()
    }
}

let hardwareInfo = {};
setTimeout(() => {
    hardwareInfo = getHardwareInfo();
    console.log(hardwareInfo)
}, 2500);

let rawbot = require('./node-rawbot');

rawbot.eventEmitter.on('enable action', (object) => {
    let serial_number = object.response.returnValues['1'];
    let action_id = object.response.returnValues['2'];
    let action_name = object.response.returnValues['3'];
    let action_cost = object.response.returnValues['4'];
    let action_duration = object.response.returnValues['5'];

    if (object.success) {
        if (hardwareInfo.serial !== serial_number) {
            console.log("Error, wrong serial number!");
            return;
        }
        if (action_duration) {
            duration = action_duration * 1000;
            RaspberryPICylon.start();
        }
    }
    console.log(object)
});

rawbot.eventEmitter.on('addAction', (object) => {

});