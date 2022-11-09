package typesystem;

using StringTools;

class StaticType {
	private static var reg = ~/"([^"]*?)"/g;

	public static function typeOf(value:String):String {
		if (!value.contains('"') && value.contains('.') && !Math.isNaN(Std.parseFloat(value)) && value.split('').length <= 8
			&& !value.replace(" ", "").startsWith("["))
			return "float";
		if (!value.contains('"') && value.contains('.') && !Math.isNaN(Std.parseFloat(value)) && value.split('').length >= 8
			&& !value.replace(" ", "").startsWith("["))
			return "double";
		if (!value.contains('"')
			&& !value.contains('.')
			&& !Math.isNaN(Std.parseFloat(value))
			&& !value.replace(" ", "").startsWith("["))
			return "int";
		if (value.replace(' ', "").startsWith('"')
			&& value.replace('"', "").split('').length > 1
			&& !value.replace(" ", "").startsWith("["))
			return "string";
		if (value.replace(' ', "").startsWith('"')
			&& value.replace('"', "").split('').length == 1
			&& !value.replace(" ", "").startsWith("["))
			return "char";
		if (!value.contains('"')
			&& (value.replace(" ", "") == "true" || value.replace(" ", "") == "false")
			&& !value.replace(" ", "").startsWith("["))
			return "bool";
		if (value.replace(" ", "").startsWith("["))
			return "array";
		return "null";
	}
}
