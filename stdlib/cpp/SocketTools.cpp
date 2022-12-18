#pragma once

#include <vector>
#ifdef _WIN32
#include <winsock2.h>
#endif
#ifdef __APPLE__
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#endif
#ifdef __linux__
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#endif
#include <iostream>
#include <string>

bool didInit = false;
bool printReceived = false;

auto sentDataPrefix = "";
auto recievedDataPrefix = "";

std::vector<SOCKET> socketsArray = {};
std::vector<int> socketsArrayL = {};
std::vector<std::string> trackedSocketsArray = {};

struct addrinfo *result = NULL,
                *ptr = NULL,
                *hints = NULL;

struct sockaddr_in serv_addr;

int lastIResult = 0;

auto socketMake(auto tag)
{
#ifdef _WIN32

    ZeroMemory(&hints, sizeof(hints));
    hints->ai_family = AF_UNSPEC;
    hints->ai_socktype = SOCK_STREAM;
    hints->ai_protocol = IPPROTO_TCP;

    if (!didInit)
    {
        WSADATA d;
        WSAStartup(MAKEWORD(2, 2), &d);
        didInit = true;
    }

    SOCKET sock = INVALID_SOCKET;
    socketsArray.push_back(sock);
    trackedSocketsArray.push_back(tag);
#endif
#ifdef __linux__
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    socketsArrayL.push_back(sock);
    trackedSocketsArray.push_back(tag);
#endif
#ifdef __APPLE__
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    socketsArrayL.push_back(sock);
    trackedSocketsArray.push_back(tag);
#endif
}

auto socketConnect(auto tag, auto port, auto host)
{
#ifdef _WIN32
    int iResult = getaddrinfo(host, port, &hints, &result);
    if (iResult != 0)
        WSACleanup();
    ptr = result;

    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            socketsArray[i] = socket(ptr->ai_family, ptr->ai_socktype,
                                            ptr->ai_protocol);

            iResult = connect(socketsArray[i], ptr->ai_addr, (int)ptr->ai_addrlen);
            if (iResult == SOCKET_ERROR)
            {
                closesocket(socketsArray[i]);
                socketsArray[i] = INVALID_SOCKET;
            }

            if (socketsArray[i] == INVALID_SOCKET)
                WSACleanup();
            lastIResult = iResult;
            break;
        }
    }
#endif
#ifdef __linux__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            serv_addr.sin_family = AF_INET;
            serv_addr.sin_port = htons(port);

            inet_pton(AF_INET, host, &serv_addr.sin_addr);
            socketsArray[i] = connect(socketsArray[i], (struct sockaddr *)&serv_addr,
                                             sizeof(serv_addr));
            break;
        }
    }
#endif
#ifdef __APPLE__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            serv_addr.sin_family = AF_INET;
            serv_addr.sin_port = htons(port);

            inet_pton(AF_INET, host, &serv_addr.sin_addr);
            socketsArray[i] = connect(socketsArray[i], (struct sockaddr *)&serv_addr,
                                             sizeof(serv_addr));
            break;
        }
    }
#endif
}

auto socketWrite(auto tag, auto data)
{
#ifdef _WIN32
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            lastIResult = send(trackedSocketsArray[i], data, (int)strlen(data), 0);
            if (lastIResult == SOCKET_ERROR)
            {
                closesocket(socketsArray[i]);
                WSACleanup();
            }
            break;
        }
    }
#endif
#ifdef __linux__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            send(trackedSocketsArray[i], data, strlen(data), 0);
            break;
        }
    }
#endif
#ifdef __APPLE__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            send(trackedSocketsArray[i], data, strlen(data), 0);
            break;
        }
    }
#endif
}

auto socketRead(auto tag, auto messageSize)
{
#ifdef _WIN32
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {

        if (trackedSocketsArray[i] == tag)
        {
            int recvbuflen = 1024;
            char recvbuf[1024];
            lastIResult = recv(socketsArray[i], recvbuf, recvbuflen, 0);
            return lastIResult;
        }
    }
#endif
#ifdef __linux__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {

        if (trackedSocketsArray[i] == tag)
        {   
            int recvbuflen = 1024;
            char recvbuf[1024];
            auto recieved = read(socketsArray[i], recvbuf, recvbuflen);
            std::string data = recvbuf;
            return data;
        }
    }
#endif
#ifdef __APPLE__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {

        if (trackedSocketsArray[i] == tag)
        {
            int recvbuflen = 1024;
            char recvbuf[1024];
            auto recieved = read(socketsArray[i], recvbuf, recvbuflen);
            std::string data = recvbuf;
            return data;
        }
    }
#endif
}

auto socketDestroy(auto tag)
{
#ifdef _WIN32
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {

        if (trackedSocketsArray[i] == tag)
        {
            lastIResult = shutdown(socketsArray[i], SD_SEND);
            if (lastIResult == SOCKET_ERROR)
            {
                closesocket(socketsArray[i]);
                WSACleanup();
            }
            trackedSocketsArray.erase(std::find(trackedSocketsArray.begin(), trackedSocketsArray.end(), trackedSocketsArray[i]));
            socketsArray.erase(std::find(socketsArray.begin(), socketsArray.end(), socketsArray[i]));
            break;
        }
    }
#endif
#ifdef __linux__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            close(trackedSocketsArray[i]);
            trackedSocketsArray.erase(std::find(trackedSocketsArray.begin(), trackedSocketsArray.end(), trackedSocketsArray[i]));
            socketsArray.erase(std::find(socketsArray.begin(), socketsArray.end(), socketsArray[i]));
        }
    }
#endif
#ifdef __APPLE__
    for (int i = 0; i < trackedSocketsArray.size(); i++)
    {
        if (trackedSocketsArray[i] == tag)
        {
            close(trackedSocketsArray[i]);
            trackedSocketsArray.erase(std::find(trackedSocketsArray.begin(), trackedSocketsArray.end(), trackedSocketsArray[i]));
            socketsArray.erase(std::find(socketsArray.begin(), socketsArray.end(), socketsArray[i]));
        }
    }
#endif
}