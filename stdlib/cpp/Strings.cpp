#pragma once

#include <cstring>
#include <string>
#include <regex>

auto stringSize(auto text)
{
    return static_cast<int>(strlen(text));
}

auto stringReplace(auto text, const auto toReplace, const auto replacement)
{
    std::string str = text;
    return std::regex_replace(str, std::regex(toReplace), replacement);
}

auto stringSub(auto text, auto startInt, auto endInt)
{
    std::string str = text;
    return str.substr(startInt, endInt);
}