#pragma once

#include <math.h>
#include <any>

static auto arcsine(auto x)
{
    if (x.type() == typeid(double))
        return any_cast<double>(asin(*any_cast<double>(&x)));
}

static auto arccos(auto x)
{
    if (x.type() == typeid(double))
        return any_cast<double>(acos(*any_cast<double>(&x)));
}

static auto cosine(auto x)
{
    if (x.type() == typeid(double))
        return any_cast<double>(cos(*any_cast<double>(&x)));
}

static auto sine(auto x)
{
    if (x.type() == typeid(double))
        return any_cast<double>(sin(*any_cast<double>(&x)));
}

static auto floorValue(auto x)
{
    if (x.type() == typeid(double))
        return any_cast<double>(floor(*any_cast<double>(&x)));
}