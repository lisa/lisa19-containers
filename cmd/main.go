package main

import (
	"flag"
	"fmt"
	"os"
	"runtime"

	"github.com/google/go-containerregistry/pkg/v1"

	lisa19 "github.com/lisa/lisa19-containers/pkg/pull"
)

var (
	arch        = flag.String("arch", runtime.GOARCH, "Pretend to be this arch")
	flagOS      = flag.String("os", runtime.GOOS, "Pretend to be this OS")
	destination = flag.String("saveTo", "", "What file to save the downloaded image?")

	repo      = flag.String("repo", "docker.io", "Repo for the image")
	imageName = flag.String("image", "thedoh/lisa19", "Image name")
	imageTag  = flag.String("tag", "19.08.3", "Image tag to use")
)

func main() {
	flag.Parse()

	plat := &v1.Platform{
		Architecture: *arch,
		OS:           *flagOS,
	}

	img := &lisa19.Image{
		Repo:  *repo,
		Image: *imageName,
		Tag:   *imageTag,
	}
	if *destination == "" {
		fmt.Printf("You must specify a place to save the image with -saveTo\n")
		os.Exit(1)
	}

	// if we're running on our arch, do not explicitly set the platform
	if plat.Architecture == runtime.GOARCH && plat.OS == runtime.GOOS {
		plat = nil
	}

	lisa19.Pull(*destination, img, plat)
}
