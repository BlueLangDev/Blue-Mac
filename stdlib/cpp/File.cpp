#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <string>

using namespace std;

static auto read(auto filen)
{
    ifstream ifstr(filen);
    string content;
    content.assign((istreambuf_iterator<char>(ifstr)),
                   (istreambuf_iterator<char>()));

    return content;
}

static auto write(auto filen, auto newcont)
{
    auto num = 0;
    auto openedfile = fopen(filen, "w");

    if (openedfile != NULL)
    {
        fputs(newcont, openedfile);
        fclose(openedfile);
    }
    fclose(openedfile);
}
