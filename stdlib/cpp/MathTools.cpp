#pragma once

#include <math.h>
#include <any>

static auto arcsine(auto y)
{
    any x = (any)y;
    if (x.type() == typeid(double))
        return any_cast<double>(asin(*any_cast<double>(&x)));
}

static auto arccos(auto y)
{
    any x = (any)y;
    if (x.type() == typeid(double))
        return any_cast<double>(acos(*any_cast<double>(&x)));
}

static auto cosine(auto y)
{
    any x = (any)y;
    if (x.type() == typeid(double))
        return any_cast<double>(cos(*any_cast<double>(&x)));
}

static auto sine(auto y)
{
    any x = (any)y;
    if (x.type() == typeid(double))
        return any_cast<double>(sin(*any_cast<double>(&x)));
}

static auto floorValue(auto y)
{
    any x = (any)y;
    if (x.type() == typeid(double))
        return any_cast<double>(floor(*any_cast<double>(&x)));
}