SHELL = bash -e
REVISION ?= 1
VERSION ?= $(shell date +%y.%m.$(REVISION))
IMG := thedoh/lisa19
REGISTRY ?= docker.io
ARCHES ?= arm64 amd64

FETCH_IMAGE_FILENAME ?= image.tar
FETCH_ROOT ?= download
FETCH_OPTS ?= -repo=docker.io -image=$(IMG) -tag=$(VERSION)
INSECURE ?=

# Verbosity
AT_ = @
AT = $(AT_$(V))
_redirect_ := 1>/dev/null
_redirect_1 :=
redirect = $(_redirect_$(V))
# /Verbosity

default: all

all: clean docker-build docker-multiarch docker-push

.PHONY: docker-build
docker-build:
	$(AT)for a in $(ARCHES); do \
		echo "[docker-build] Docker build $(REGISTRY)/$(IMG):$$a-$(VERSION) with GOARCH=$$a" ;\
		docker build --platform=linux/$$a --build-arg=GOARCH=$$a -t $(REGISTRY)/$(IMG):$$a-$(VERSION) . $(redirect) ;\
		$(call set_image_arch,$(REGISTRY)/$(IMG):$$a-$(VERSION),$$a) ;\
		docker tag $(REGISTRY)/$(IMG):$$a-$(VERSION) $(REGISTRY)/$(IMG):$$a-latest $(redirect) ;\
	done

.PHONY: docker-multiarch
docker-multiarch: docker-build
	$(AT)arches= ;\
	for a in $(ARCHES); do \
		echo "[docker-multiarch] Docker pushing 'intermediate' arch=$$a to $(REGISTRY)" ;\
		arches="$$arches $(REGISTRY)/$(IMG):$$a-$(VERSION)" ;\
		docker push $(REGISTRY)/$(IMG):$$a-$(VERSION) $(redirect) 1>/dev/null ;\
	done ;\
	echo "[docker-multiarch] Creating manifest with docker manifest create $(INSECURE) $(REGISTRY)/$(IMG):$(VERSION) $$arches" ;\
	docker manifest create $(INSECURE) $(REGISTRY)/$(IMG):$(VERSION) $$arches 1>/dev/null ;\
	for a in $(ARCHES); do \
		echo "[docker-multiarch] Annotating $(REGISTRY)/$(IMG):$(VERSION) with $(REGISTRY)/$(IMG):$$a-$(VERSION)" --os linux --arch $$a ;\
		docker manifest annotate $(REGISTRY)/$(IMG):$(VERSION) $(REGISTRY)/$(IMG):$$a-$(VERSION) --os linux --arch $$a 1>/dev/null ;\
	done

.PHONY: docker-push
docker-push: docker-build docker-multiarch
	$(AT)echo "[docker-push] Pushing $(REGISTRY)/$(IMG):$(VERSION) to $(REGISTRY)" ;\
	docker manifest push $(INSECURE) $(REGISTRY)/$(IMG):$(VERSION) 1>/dev/null

.PHONY: clean
clean:
	$(AT)for a in $(ARCHES); do \
		echo "[clean] Local image delete for $(REGISTRY)/$(IMG):$$a-$(VERSION) and $(REGISTRY)/$(IMG):$$a-latest" ;\
		docker rmi $(REGISTRY)/$(IMG):$$a-$(VERSION) &>/dev/null || true ;\
		docker rmi $(REGISTRY)/$(IMG):$$a-latest &>/dev/null || true ;\
	done ;\
	echo "[clean] Cleaning multiarch $(REGISTRY)/$(IMG):latest and $(REGISTRY)/$(IMG):$(VERSION)" ;\
	docker rmi $(REGISTRY)/$(IMG):latest &>/dev/null || true ;\
	docker rmi $(REGISTRY)/$(IMG):$(VERSION) &>/dev/null || true ;\
	rm -vrf ~/.docker/manifests/$(shell echo $(REGISTRY)/$(IMG) | tr '/' '_' | tr ':' '-')-$(VERSION) $(redirect) || true ;\
	
.PHONY: fetch-arm64
fetch-arm64:
	$(AT)echo "[fetch-arm64] Fetching the linux/arm64 tarball for $(REGISTRY)/$(IMG):$(VERSION) to $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME)" ;\
	\rm -rf $(FETCH_ROOT)/arm64 || true ;\
	mkdir -p $(FETCH_ROOT)/arm64 ;\
	go run cmd/main.go $(FETCH_OPTS) -arch arm64 -os linux -saveTo $(FETCH_ROOT)/arm64/$(FETCH_IMAGE_FILENAME) 1>/dev/null

.PHONY: fetch-amd64
fetch-amd64:
	$(AT)echo "[fetch-amd64] Fetching the linux/amd64 tarball for $(REGISTRY)/$(IMG):$(VERSION) to $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME)" ;\
	\rm -rf $(FETCH_ROOT)/amd64 || true ;\
	mkdir -p $(FETCH_ROOT)/amd64 ;\
	go run cmd/main.go $(FETCH_OPTS) -arch amd64 -os linux -saveTo $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME) 1>/dev/null

.PHONY: fetch
fetch:
	$(AT)echo "[fetch] Fetching mystery os/arch for $(REGISTRY)/$(IMG):$(VERSION) to $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME)" ;\
	\rm -rf $(FETCH_ROOT)/default || true ;\
	mkdir -p $(FETCH_ROOT)/default ;\
	go run cmd/main.go $(FETCH_OPTS) -saveTo $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME) 1>/dev/null

.PHONY: validate-default
validate-default: fetch
	$(AT)echo "[validate-default] Determining which os/arch was downloaded to $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME)" ;\
	cd $(FETCH_ROOT)/default ;\
	tar xf $(FETCH_IMAGE_FILENAME) ;\
	detectedarch="$$(cat sha256* | jq -r '.architecture')" ;\
	detectedos="$$(cat sha256* | jq -r '.os')" ;\
	echo "[validate-default] Detected $${detectedos}/$${detectedarch} from $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME)." ;\
	cd ../..

.PHONY: validate-arm64
validate-arm64: fetch-arm64
	$(AT)echo "[validate-arm64] Determining if linux/arm64 was downloaded to $(FETCH_ROOT)/arm64/$(FETCH_IMAGE_FILENAME)" ;\
	cd $(FETCH_ROOT)/arm64 ;\
	tar xf $(FETCH_IMAGE_FILENAME) ;\
	detectedarch="$$(cat sha256* | jq -r '.architecture')" ;\
	detectedos="$$(cat sha256* | jq -r '.os')" ;\
	echo "[validate-arm64] Detected $${detectedos}/$${detectedarch} from $(FETCH_ROOT)/arm64/$(FETCH_IMAGE_FILENAME)." ;\
	cd ../..

.PHONY: validate-amd64
validate-amd64: fetch-amd64
	$(AT)echo "[validate-amd64] Determining if linux/amd64 was downloaded to $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME)" ;\
	cd $(FETCH_ROOT)/amd64 ;\
	tar xf $(FETCH_IMAGE_FILENAME) ;\
	detectedarch="$$(cat sha256* | jq -r '.architecture')" ;\
	detectedos="$$(cat sha256* | jq -r '.os')" ;\
	echo "[validate-amd64] Detected $${detectedos}/$${detectedarch} from $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME)." ;\
	cd ../..

.PHONY: help
help:
	@echo "If using non-docker.io registry, you may need to set INSECURE=--insecure, for insecure registries"
	@echo "May override IMG, REVISION and/or VERSION and ARCHES"
	@echo "ARCHES defaults to: amd64 arm64"
	@echo "IMG defaults to thedoh/lisa19 (because that's the author's namespace)"
	@echo "Settings:"
	@echo " * IMG=$(IMG)"
	@echo " * REGISTRY=$(REGISTRY)"
	@echo " * ARCHES=$(ARCHES)"
	@echo " * REVISION=$(REVISION); VERSION=$(VERSION)"
	@echo " * INSECURE=$(INSECURE)"
	@echo " * Tagging $(REGISTRY)/$(IMG):$(VERSION)"

# Set image Architecture in manifest and replace it in the local registry
# 1 image:tag
# 2 Set Architecture to
define set_image_arch
	cpwd=$$(pwd) ;\
	set -o errexit ;\
	set -o nounset ;\
	set -o pipefail ;\
	savedir=$$(mktemp -d) ;\
	chmod 700 $$savedir ;\
	mkdir -p $$savedir/change ;\
	docker save $(1) > $$savedir/image.tar ;\
	cd $$savedir/change ;\
	tar xf ../image.tar ;\
	jsonfile=$$(find $$savedir/change -name "*.json" -not -name manifest.json) ;\
	origarch=$$(cat $$jsonfile | jq -r .architecture) ;\
	if [[ $(2) != $$origarch ]]; then \
		docker rmi $(1) $(redirect) ;\
		echo "[set_image_arch] changing from $${origarch} to $(2) for $(1)" ;\
		sed -i -e "s,\"architecture\":\"$${origarch}\",\"architecture\":\"$(2)\"," $$jsonfile ;\
		tar cf - * | docker load $(redirect) ;\
		cd .. ;\
	fi ;\
	cd $$cpwd ;\
	\rm -rf -- $$savedir
endef