package main

type dynamic = interface{}

func pop(array []dynamic) dynamic {
    return array[len(array)]
}

func shift(array []dynamic) dynamic {
    return array[0]
}

func add(array []dynamic, element dynamic) {
    array[len(array) + 1] = element
}

func arraySize(array []dynamic) dynamic {
    return len(array);
}