#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <time.h>
#include <cstring>
#include <sstream>
#include <string>
#include <cstddef>
#include <cstdio>
#include <variant>
#include <typeinfo>
#include <any>
#include "ArrayTools.cpp"

using namespace std;

auto runcmd(auto command)
{
    system(command);
}

auto shutdown(auto exit_code)
{
    exit(exit_code);
}

auto varTrace(auto variable)
{
    any vari = (any)variable;

    if (vari.type() == typeid(DynamicType))
    {
        auto newVari = any_cast<DynamicType>(vari);
        if (newVari.varToCast.type() == typeid(int))
        {
            cout << any_cast<int>(newVari.varToCast) << endl;
            return;
        }
        else if (newVari.varToCast.type() == typeid(double))
        {
            cout << any_cast<double>(newVari.varToCast) << endl;
            return;
        }
        else if (newVari.varToCast.type() == typeid(const char *))
        {
            cout << any_cast<const char *>(newVari.varToCast) << endl;
            return;
        }
        else if (newVari.varToCast.type() == typeid(bool))
        {
            if (any_cast<bool>(newVari.varToCast) == true)
                cout << "true" << endl;
            else
                cout << "false" << endl;
            return;
        }
    }
    else
    {
        if (vari.type() == typeid(int))
        {
            cout << any_cast<int>(vari) << endl;
            return;
        }
        else if (vari.type() == typeid(double))
        {
            cout << any_cast<double>(vari) << endl;
            return;
        }
        else if (vari.type() == typeid(const char *))
        {
            cout << any_cast<const char *>(vari) << endl;
            return;
        }
        else if (vari.type() == typeid(string))
        {
            cout << any_cast<string>(vari) << endl;
            return;
        }
        else if (vari.type() == typeid(bool))
        {
            if (any_cast<bool>(vari) == true)
                cout << "true" << endl;
            else
                cout << "false" << endl;
            return;
        }
    }
}