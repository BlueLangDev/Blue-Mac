package export.hxsrc;

class System {
	public static function runcmd(command:Dynamic) {
		Sys.command(command);
	}

	public static function close(exitCode:Dynamic) {
		Sys.exit(exitCode);
	}

	public static function getDate():Dynamic {
		return Date.now();
	}

	public static function getTime():Dynamic {
		return Sys.time();
	}

	public static function varTrace(variable:Dynamic) {
		Sys.println(variable);
	}
}
