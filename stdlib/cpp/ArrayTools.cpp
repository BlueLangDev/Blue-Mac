#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <any>
#include <iterator>
#include <string>
#include <iostream>
#include <exception>
#include <vector>

using namespace std;

auto pop(auto &&array)
{
    auto element = array[(int)std::size(array) - 1];
    for (int i = 0; i < (int)std::size(array) - 1; i++)
        array[i] = array[i + 1];
    array[(int)std::size(array) - 1] = NULL;
    return element;
}

auto shift(auto &&array)
{
    auto element = array[0];
    for (int i = 1; i < (int)std::size(array); i++)
        array[i] = array[i + 1];
    array[(int)std::size(array) - 1] = NULL;
    return element;
}

auto arraySize(auto &&array)
{
    return (int)std::size(array);
}