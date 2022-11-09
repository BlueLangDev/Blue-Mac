#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <any>
#include <iterator>
#include <cstring>
#include <string>
#include <iostream>
#include <exception>

using namespace std;

auto pop(auto &&array)
{
    return array[(int)std::size(array)];
}

auto shift(auto &&array)
{
    return array[0];
}

auto add(auto &&array, auto element)
{
    array[(int)std::size(array) + 1] = element;
}

auto &&arraySize(auto &&array)
{
    return (int)std::size(array);
}