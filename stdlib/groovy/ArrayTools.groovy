def pop(array)
{
    return array[len(array)];
    array[len(array)] = NULL;
}

def shift(array)
{
    return array[0];
    array[0] = null;
}

def add(array, element)
{
    array[len(array) + 1] = element;
}

def arraySize(array)
{
    return len(array);
}