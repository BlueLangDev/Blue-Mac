def pop(array)
{
    return array.pop();
}

def shift(array)
{
    def element = array[0];
    array.remove(0);
    return element;
}

def arraySize(array)
{
    return len(array);
}