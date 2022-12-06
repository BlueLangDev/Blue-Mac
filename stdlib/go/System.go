package main

import (
	"fmt"
	"os"
	"os/exec"
)

func runcmd(command dynamic) {

	cmd := exec.Command(command.(string))

	cmd.Run()
}

func shutdown(exitcode dynamic) {
	os.Exit(exitcode.(int))
}

func varTrace(vari dynamic) {
	fmt.Println(vari)
}
