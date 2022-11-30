package main

type dynamic = interface{}

func pop(array []dynamic) dynamic {
	length := len(array) - 1
	elem := array[length]
	array = append(array[:length], array[length+1:]...)
	return elem
}

func shift(array []dynamic) dynamic {
	length := 0
	elem := array[length]
	array = append(array[:length], array[length+1:]...)
	return elem
}

func arraySize(array []dynamic) dynamic {
	return len(array)
}
