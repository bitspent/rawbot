var lettersToMorse = {
    "a": "sl",
    "b": "lsss",
    "c": "lsls",
    "d": "lss",
    "e": "s",
    "f": "ssls",
    "g": "lls",
    "h": "ssss",
    "i": "ss",
    "j": "slll",
    "k": "lsl",
    "l": "slll",
    "m": "ll",
    "n": "ls",
    "o": "lll",
    "p": "slls",
    "q": "llsl",
    "r": "sls",
    "s": "sss",
    "t": "l",
    "u": "ssl",
    "v": "sssl",
    "w": "sll",
    "x": "lssl",
    "y": "lsll",
    "z": "llss",
    "1": "sllll",
    "2": "sslll",
    "3": "sssll",
    "4": "ssssl",
    "5": "sssss",
    "6": "lssss",
    "7": "llsss",
    "8": "lllss",
    "9": "lllls",
    "0": "lllll"
}

module.exports = function (pin) {
    var unit = 10;
    var gap = 10;

    console.log(pin.type);

    var beep = function (num, cb) {
        cb = cb || function () { };
        if (pin.type == "digital") {
            beepDigital(num, cb);
        }
        else {
            beepAnalog(num, cb);
        }
    }

    var beepDigital = function (num, cb) {
        if (num) {
            pin.high();
            pin.low();
            setTimeout(function () {
                beep(num - 1, cb);
            }, gap);
        }
        else {
            pin.low();
            setTimeout(cb, unit * gap);
        }
    }


    var beepAnalog = function (num, cb) {
        if (num) {
            pin.write(255);
            pin.write(0);
            setTimeout(function () {
                beep(num - 1, cb);
            }, gap);
        }
        else {
            pin.low();
            setTimeout(cb, unit * gap);
        }
    }

    var long = function (cb) {
        cb = cb || function () { };
        beep(3 * unit, cb);
    }

    var short = function (cb) {
        cb = cb || function () { };
        beep(unit, cb);
    }

    var pause = function (cb) {
        setTimeout(cb, 2 * unit * gap);
    }

    var space = function (cb) {
        setTimeout(cb, 4 * unit * gap);
    }

    var parse = function (str, cb) {
        if (str.length) {
            var l = str[0];
            process.stdout.write(l);
            str = str.slice(1);
            if (l == "s") {
                short(function () {
                    parse(str, cb);
                });
            }
            else {
                long(function () {
                    parse(str, cb);
                });
            }
        }
        else {
            process.stdout.write("\n");
            pause(cb);
        }
    }

    var say = function (msg, cb) {
        if (msg.length) {
            var l = msg[0];
            msg = msg.slice(1);
            var code = lettersToMorse[l];
            if (code) {
                process.stdout.write(l + ": ");
                parse(code, function () {
                    say(msg, cb);
                });
            }
            else if (l == " ") {
                space(function () {
                    say(msg, cb);
                });
            }
            else {
                say(msg, cb);
            }
        }
        else {
            cb();
        }
    }

    return say;
}