package main

import (
	"fmt"
	"io/ioutil"
	"runtime"
)

const proofFile string = "/proof.txt"

func main() {

	p, err := ioutil.ReadFile(proofFile)
	if err != nil {
		fmt.Printf("Couldn't find proof file at %s\n", proofFile)
	} else {
		fmt.Printf("Proof file says arch should be: %s\n", p)
	}

	fmt.Printf("Running on %s/%s\n", runtime.GOARCH, runtime.GOOS)
}
