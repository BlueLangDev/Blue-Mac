package main

import "net"

var socketsArray = []net.Conn{}
var trackedSocketsArray = []dynamic{}

func socketMake(tag dynamic) {
	trackedSocketsArray = append(trackedSocketsArray, tag)
}

func socketConnect(tag dynamic, port dynamic, host dynamic) {
	sock, error_ := net.Dial("tcp", host.(string)+":"+string(port.(int)))
	if error_ != nil {
		panic(error_)
	}
	socketsArray = append(socketsArray, sock)
}

func socketWrite(tag dynamic, data dynamic) {
	for i := 0; i < len(trackedSocketsArray); i++ {
		if trackedSocketsArray[i] == tag {
			_, err := (trackedSocketsArray[i].(net.Conn)).Write([]byte(data.(string)))
			if err != nil {
			}
		}
	}
}

func socketRead(tag dynamic) dynamic {
	for i := 0; i < len(trackedSocketsArray); i++ {
		if trackedSocketsArray[i] == tag {
			recvData := make([]byte, 1024)
			socketsArray[i].Read(recvData)
			return string(recvData)
		}
	}
	return nil
}

func socketDestroy(tag dynamic) {
	for i := 0; i < len(trackedSocketsArray); i++ {
		if trackedSocketsArray[i] == tag {
			trackedSocketsArray = append(trackedSocketsArray[:i], trackedSocketsArray[i+1:]...)
			defer (trackedSocketsArray[i].(net.Conn)).Close()
			socketsArray = append(socketsArray[:i], socketsArray[i+1:]...)
		}
	}
}
