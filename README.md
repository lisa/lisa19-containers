# lisa19-containers

Demo containers for @lisa's [LISA19 conference talk](https://thedoh.dev/conferences.html).

This repository contains infrastructure for a total of three images:

* Single arch amd64 image
* Single arch arm64 image
* Multi-arch arm64 and amd64 image

Each image is designed to prove the architecture by having a per-arch binary and a text file containing further proof.

The repository contains code to utilize google/go-containerregistry to pull specific images and save as tarballs; it is not included in the aforementioned image(s).

# Makefiles

There are many Makefiles present in the repository; they are listed and described here.

* `Makefile.simple` - A simplified Makefile that is stripped down to the minimum required (also requires `functions.mk`)
* `Makefile` - A more polished Makefile which attempts to keep the screen clear of unnecessary output
  * `functions.mk` - Required, primarily for the `set_image_arch` function defined within
  * `validate.mk` - Used for part of the demo to validate characteristics of the the built images
  * `verbose.mk` - Controls `Makefile` verbosity (eg `make -f Makefile V=1` for more verbosity)
  * `app.mk` - Used for the `validate.mk` to build a helper Go program for fetching images
