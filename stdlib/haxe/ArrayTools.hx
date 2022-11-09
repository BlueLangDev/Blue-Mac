package export.hxsrc;

class ArrayTools {
	public static function pop(array:Dynamic):Dynamic {
		return array[array.length];
		array[array.length] = null;
	}

	public static function shift(array:Dynamic):Dynamic {
		return array[0];
		array[0] = null;
	}

	public static function add(array:Dynamic, element:Dynamic):Dynamic {
		array[array.length + 1] = element;
		return null;
	}

	public static function arraySize(array:Dynamic):Dynamic {
		return array.length;
	}
}
