package main

type dynamic = interface{}

func pop(array []dynamic) []dynamic {
	length := len(array) - 1
	array = append(array[:length], array[length+1:]...)
	return array
}

func shift(array []dynamic) []dynamic {
	length := 0
	array = append(array[:length], array[length+1:]...)
	return array
}

func addElement(array []dynamic, element dynamic) []dynamic {
	array = append(array, element)
	return array
}

func arraySize(array []dynamic) dynamic {
	return len(array)
}
