class ArrayTools {
	static pop(array) {
		array.pop();
		return array;
	}

	static shift(array) {
		array.shift();
		return array;
	}

	static addElement(array, element) {
		array.push(element);
		return array;
	}

	static arraySize(array) {
		return array.length;
	}
}
