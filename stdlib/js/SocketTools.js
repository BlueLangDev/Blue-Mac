net = require('net');

socketsArray = [];
trackedSocketsArray = [];

lastRead = "";

module.exports = class SocketTools {
    static socketMake(tag) {
        var sock = new net.Socket();
        socketsArray.push(sock);
        trackedSocketsArray.push(tag);
    }

    static socketConnect(tag, port, host) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                var sock = socketsArray[i];
                sock.connect(port, host);
                sock.on('data', (data) => {
                    lastRead = data;
                })
            }
        }
    }

    static socketWrite(tag, data) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                var extractedSock = socketsArray[i];
                extractedSock.write(`${data}`);
            }
        }
    }

    static socketRead(tag) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                return lastRead;
            }
        }
    }

    static socketDestroy(tag, data) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                var extractedSock = socketsArray[i];
                extractedSock.destroy();
                trackedSocketsArray.remove(trackedSocketsArray[i]);
                socketsArray.remove(extractedSock);
            }
        }
    }
}