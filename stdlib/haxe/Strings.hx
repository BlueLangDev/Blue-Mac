package export.hxsrc;

using StringTools;

class Strings {
	public static function stringSize(text:Dynamic) {
		return Std.string(text).length;
	}

	public static function stringReplace(text:Dynamic, toReplace:Dynamic, replacement:Dynamic) {
		return Std.string(text).replace(toReplace, replacement);
	}

	public static function stringSub(text:Dynamic, firstInt:Dynamic, secondInt:Dynamic) {
		return Std.string(text).subString(firstInt, secondInt);
	}
}
