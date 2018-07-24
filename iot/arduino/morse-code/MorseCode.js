var five = require("johnny-five");
var board = new five.Board();

var morse = require("./morse-code");
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 3000 });
var speaker = null;
let busy = false;


wss.on('connection', function connection(ws) {
  ws.on('message', function incoming(message) {
    var message = message.toLocaleLowerCase();
    console.log('Received message: %s', message);
    console.log('Status: ' + (busy == true ? "busy" : "available"));
    if (!busy) {
      busy = true;
      speaker(message, function () {
        busy = false;
      });
    }
  });

  ws.send('Successfully connected');
});

board.on("ready", function () {
  speaker = morse(new five.Pin(7));
});