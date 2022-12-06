package export.hxsrc;

class System {
	public static function runcmd(command:Dynamic) {
		Sys.command(command);
	}

	public static function shutdown(exitCode:Dynamic) {
		Sys.exit(exitCode);
	}

	public static function varTrace(variable:Dynamic) {
		Sys.println(variable);
	}
}
