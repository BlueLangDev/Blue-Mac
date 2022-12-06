#pragma once

#include <math.h>
#include <any>

static auto arcsine(auto y)
{
    std::any x = (std::any)y;
    if (x.type() == typeid(double))
        return std::any_cast<double>(asin(*std::any_cast<double>(&x)));
}

static auto arccos(auto y)
{
    std::any x = (std::any)y;
    if (x.type() == typeid(double))
        return std::any_cast<double>(acos(*std::any_cast<double>(&x)));
}

static auto cosine(auto y)
{
    std::any x = (std::any)y;
    if (x.type() == typeid(double))
        return std::any_cast<double>(cos(*std::any_cast<double>(&x)));
}

static auto sine(auto y)
{
    std::any x = (std::any)y;
    if (x.type() == typeid(double))
        return std::any_cast<double>(sin(*std::any_cast<double>(&x)));
}

static auto floorValue(auto y)
{
    std::any x = (std::any)y;
    if (x.type() == typeid(double))
        return std::any_cast<double>(floor(*std::any_cast<double>(&x)));
}