package main

import (
	"os/exec"
	"os"
   "fmt"
)

func runcmd(command dynamic) {

    cmd := exec.Command(command.(string))

    cmd.Run()
}

func close(exitcode dynamic) {
    os.Exit(exitcode.(int))
}

func varTrace(vari dynamic) {
   fmt.Println(vari)
}