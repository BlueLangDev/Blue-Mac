class SocketTools {
    net = require('net');

    socketsArray = [];
    trackedSocketsArray = [];

    lastRead = "";

    static socketMake(tag) {
        sock = new net.Socket();
        socketsArray.push(sock);
        trackedSocketsArray.push(tag);
    }

    static socketConnect(tag, port, host) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                sock = socketsArray[i];
                sock.connect(port, host);
                socket.on('data', (data) => {
                    lastRead = data;
                })
            }
        }
    }

    static socketWrite(tag, data) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                extractedSock = socketsArray[i];
                extractedSock.write(`${data}`);
            }
        }
    }

    static socketRead(tag, data) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                return lastRead;
            }
        }
    }

    static socketDestroy(tag, data) {
        for (var i = 0; i < trackedSocketsArray.length; i++) {
            if (trackedSocketsArray[i] == tag) {
                extractedSock = socketsArray[i];
                extractedSock.destroy();
                trackedSocketsArray.remove(trackedSocketsArray[i]);
                socketsArray.remove(extractedSock);
            }
        }
    }
}