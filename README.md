# lisa19-containers

Demo containers for @lisa's [LISA19 conference talk](https://thedoh.dev/conferences.html).

This repository contains infrastructure for a total of three images:

* Single arch amd64 image
* Single arch arm64 image
* Multi-arch arm64 and amd64 image

Each image is designed to prove the architecture by having a per-arch binary and a text file containing further proof.

The repository contains code to utilize google/go-containerregistry to pull specific images and save as tarballs; it is not included in the aforementioned image(s).