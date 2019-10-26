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
		fmt.Printf("Couldn't find proof file at %s. ", proofFile)
	} else {
		fmt.Printf("At build time, this image was built to run on %s. ", p)
	}

	fmt.Printf("The platform that is being run on is %s/%s\n", runtime.GOOS, runtime.GOARCH)
}
