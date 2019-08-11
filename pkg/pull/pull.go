package pull

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"os"

	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1"
	"github.com/google/go-containerregistry/pkg/v1/remote"
	"github.com/google/go-containerregistry/pkg/v1/tarball"
)

// Image represents the container image to pull down
type Image struct {
	Repo  string // eg docker.io
	Image string // eg thedoh/lisa19
	Tag   string // eg 19.08.1
}

// Pull a repo/image:tag to destination
func Pull(destination string, img *Image, platform *v1.Platform) {
	if platform != nil {
		fmt.Printf("Saving %s/%s:%s (%s/%s) to %s\n", img.Repo, img.Image, img.Tag, platform.OS, platform.Architecture, destination)
	} else {
		fmt.Printf("Saving %s/%s:%s to %s\n", img.Repo, img.Image, img.Tag, destination)
	}

	ref, err := name.ParseReference(fmt.Sprintf("%s/%s:%s", img.Repo, img.Image, img.Tag), name.WeakValidation)
	if err != nil {
		fmt.Printf("Error parsing %s/%s:%s into a reference: %s", img.Repo, img.Image, img.Tag, err)
		os.Exit(1)
	}
	transport := http.DefaultTransport.(*http.Transport)

	transport.TLSClientConfig = &tls.Config{}

	var remoteImage v1.Image

	if platform != nil {
		remoteImage, err = remote.Image(ref, remote.WithTransport(transport), remote.WithPlatform(*platform))
	} else {
		remoteImage, err = remote.Image(ref, remote.WithTransport(transport))
	}

	if err != nil {
		fmt.Printf("Couldn't fetch the image %s/%s:%s, err=%s\n", img.Repo, img.Image, img.Tag, err)
	}

	a, err := remoteImage.Manifest()
	if err != nil {
		fmt.Printf("Couldn't find a manifest: %s\n", err)
	} else {
		fmt.Printf("manifest.config.platform = %+v\n", a.Config.Platform)
		fmt.Printf("manifest layers= %+v\n", a.Layers)
	}

	if err != nil {
		fmt.Printf("Error fetching remote image details: %s\n", err)
		os.Exit(1)
	}
	fmt.Printf("Remote Image: %+v\n", remoteImage)

	dstref, err := name.NewTag("temporary/tag", name.WeakValidation)
	if err != nil {
		fmt.Printf("Couldn't allocate a temp tag for saving the tarball: %s\n", err)
		os.Exit(1)
	}

	tarball.WriteToFile(destination, dstref, remoteImage)

}
