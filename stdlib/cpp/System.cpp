#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <time.h>
#include <cstring>
#include <string>
#include <cstddef>
#include <cstdio>
#include <typeinfo>
#include <any>

using namespace std;

auto runcmd(auto command)
{
    system(command);
    return NULL;
}

auto close(auto exit_code)
{
    exit(exit_code);
    return NULL;
}

auto getDate()
{
    return time(nullptr);
}

auto getTime()
{
    const time_t *time;

    return _wctime(time);
}

auto varTrace(auto variable)
{
    any vari = (any) variable;

    if (vari.type() == typeid(int))
    {
        cout << any_cast<int>(vari) << endl;
    }
    else if (vari.type() == typeid(double))
    {
        cout << any_cast<double>(vari) << endl;
    }
    else if (vari.type() == typeid(const char*))
    {
        cout << any_cast<const char*>(vari) << endl;
    }
    else if (vari.type() == typeid(bool))
    {
        cout << any_cast<bool>(vari) << endl;
    }
    return NULL;
}