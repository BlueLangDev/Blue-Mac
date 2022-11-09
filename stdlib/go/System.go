package main

import (
	"os/exec"
	"os"
   "time"
   "fmt"
)

func runcmd(command dynamic) {

    cmd := exec.Command(command.(string))

    cmd.Run()
}

func close(exitcode dynamic) {
    os.Exit(exitcode.(int))
}

func getTime() dynamic {
   return time.Now()
}

func getDate() dynamic {
   return time.Now().UTC()
}

func varTrace(vari dynamic) {
   fmt.Println(vari)
}