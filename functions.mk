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