let rawbot = require('../../node-rawbot');

rawbot.eventEmitter.on('addDevice', (object) => {
    console.log(object)
})