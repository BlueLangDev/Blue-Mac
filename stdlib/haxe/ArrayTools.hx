package export.hxsrc;

class ArrayTools {
	public static function pop(array:Dynamic):Dynamic {
		array.pop();
		return array;
	}

	public static function shift(array:Dynamic):Dynamic {
		array.shift();
		return array;
	}

	public static function addElement(array:Dynamic, element:Dynamic) {
		array.push(element);
		return array;
	}

	public static function arraySize(array:Dynamic):Dynamic {
		return array.length;
	}
}
