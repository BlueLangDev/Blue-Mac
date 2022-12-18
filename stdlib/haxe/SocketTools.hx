package export.hxsrc;

import sys.net.Socket;

class SocketTools {
	static var socketsArray:Array<Socket> = [];
	static var trackedSocketsArray:Array<Dynamic> = [];

	public static function socketMake(tag:Dynamic) {
		socketsArray.push(new Socket());
		trackedSocketsArray.push(tag);
	}

	public static function socketConnect(tag:Dynamic, host:Dynamic, port:Dynamic) {
		for (i in 0...trackedSocketsArray.length) {
			if (Std.string(trackedSocketsArray[i]) == Std.string(tag)) {
				socketsArray[i].setBlocking(true);
				socketsArray[i].connect(new Host(host), port);
				break;
			}
		}
	}

	public static function socketWrite(tag:Dynamic, data:Dynamic) {
		for (i in 0...trackedSocketsArray.length) {
			if (Std.string(trackedSocketsArray[i]) == Std.string(tag)) {
				socketsArray[i].write(data);
				break;
			}
		}
	}

	public static function socketRead(tag:Dynamic) {
		for (i in 0...trackedSocketsArray.length) {
			if (Std.string(trackedSocketsArray[i]) == Std.string(tag)) {
				return socketsArray[i].read();
			}
		}
	}

	public static function socketDestroy(tag:Dynamic) {
		for (i in 0...trackedSocketsArray.length) {
			if (Std.string(trackedSocketsArray[i]) == Std.string(tag)) {
				socketsArray[i].close();
				break;
			}
		}
	}
}
