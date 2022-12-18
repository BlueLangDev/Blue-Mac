import java.net.Socket;

class SocketTools {

    def socketsArray = [];
    def trackedSocketsArray = [];

    def socketMake(tag) {
        trackedSocketsArray.add(tag);
    }
    
    def socketConnect(tag, port, host) {
        for (i = 0; i < len(trackedSocketsArray); i++) {
            if (trackedSocketsArray[i] == tag) {
                def socket = new Socket(host, port);
                socketsArray.add(socket);
            }
        }
    }
    
    def socketWrite(tag, data) {
        for (i = 0; i < len(trackedSocketsArray); i++) {
            if (trackedSocketsArray[i] == tag) {
                def sock = socketsArray[i];
                socket.withStreams { input, output ->
                    output << data
                }
            }
        }
    }

    def socketRead(tag) {
        socket.withStreams { input, output ->
            return input.newReader().readLine();
        }
    }

    def socketDestroy(tag) {
        for (i = 0; i < len(trackedSocketsArray); i++) {
            if (trackedSocketsArray[i] == tag) {
                socketsArray[i].close();
                trackedSocketsArray.remove(i);
                socketsArray.remove(i);
            }
        }
    }
}