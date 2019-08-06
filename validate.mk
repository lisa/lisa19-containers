FETCH_IMAGE_FILENAME ?= image.tar
FETCH_ROOT ?= download
FETCH_OPTS ?= -repo=$(REGISTRY) -image=$(IMG) -tag=$(VERSION)
FETCH_CMD ?= $(PULL_BINARY) $(FETCH_OPTS)

.PHONY: validate-options
validate-options:
	$(AT)if [[ $(REGISTRY) != "docker.io" ]]; then \
		echo "[validate-options] Warning: $(REGISTRY) may not be supported." ;\
	fi

.PHONY: fetch-arm64
fetch-arm64: validate-options pull-binary
	$(AT)echo "[fetch-arm64] Fetching the linux/arm64 tarball for $(REGISTRY)/$(IMG):$(VERSION) to $(FETCH_ROOT)/arm64/$(FETCH_IMAGE_FILENAME)" ;\
	\rm -rf $(FETCH_ROOT)/arm64 || true ;\
	mkdir -p $(FETCH_ROOT)/arm64 ;\
	$(FETCH_CMD) -arch arm64 -os linux -saveTo $(FETCH_ROOT)/arm64/$(FETCH_IMAGE_FILENAME) $(redirect)

.PHONY: fetch-amd64
fetch-amd64: validate-options pull-binary
	$(AT)echo "[fetch-amd64] Fetching the linux/amd64 tarball for $(REGISTRY)/$(IMG):$(VERSION) to $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME)" ;\
	\rm -rf $(FETCH_ROOT)/amd64 || true ;\
	mkdir -p $(FETCH_ROOT)/amd64 ;\
	$(FETCH_CMD) -arch amd64 -os linux -saveTo $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME) $(redirect)

.PHONY: fetch
fetch: validate-options pull-binary
	$(AT)echo "[fetch] Fetching $(REGISTRY)/$(IMG):$(VERSION) to $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME) without specifying a platform." ;\
	\rm -rf $(FETCH_ROOT)/default || true ;\
	mkdir -p $(FETCH_ROOT)/default ;\
	$(FETCH_CMD) $(FETCH_OPTS) -saveTo $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME) $(redirect)

.PHONY: validate-default
validate-default: fetch
	$(AT)echo "[validate-default] Determining which os/arch was downloaded to $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME)" ;\
	cd $(FETCH_ROOT)/default ;\
	tar xf $(FETCH_IMAGE_FILENAME) ;\
	find . -name "*.tar.gz" -exec tar xzf {} \; ;\
	detectedarch="$$(cat sha256* | jq -r '.architecture')" ;\
	detectedos="$$(cat sha256* | jq -r '.os')" ;\
	echo "[validate-default] Detected $${detectedos}/$${detectedarch} from $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME) manifest." ;\
	echo "[validate-default] Binary from compressed tarball: $$(file -e elf proof)" ;\
	cd ../..

.PHONY: validate-arm64
validate-arm64: fetch-arm64
	$(AT)echo "[validate-arm64] Determining if linux/arm64 was downloaded to $(FETCH_ROOT)/arm64/$(FETCH_IMAGE_FILENAME)" ;\
	cd $(FETCH_ROOT)/arm64 ;\
	tar xf $(FETCH_IMAGE_FILENAME) ;\
	find . -name "*.tar.gz" -exec tar xzf {} \; ;\
	detectedarch="$$(cat sha256* | jq -r '.architecture')" ;\
	detectedos="$$(cat sha256* | jq -r '.os')" ;\
	echo "[validate-default] Detected $${detectedos}/$${detectedarch} from $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME) manifest." ;\
	echo "[validate-default] Binary from compressed tarball: $$(file -e elf proof)" ;\
	cd ../..

.PHONY: validate-amd64
validate-amd64: fetch-amd64
	$(AT)echo "[validate-amd64] Determining if linux/amd64 was downloaded to $(FETCH_ROOT)/amd64/$(FETCH_IMAGE_FILENAME)" ;\
	cd $(FETCH_ROOT)/amd64 ;\
	tar xf $(FETCH_IMAGE_FILENAME) ;\
	find . -name "*.tar.gz" -exec tar xzf {} \; ;\
	detectedarch="$$(cat sha256* | jq -r '.architecture')" ;\
	detectedos="$$(cat sha256* | jq -r '.os')" ;\
	echo "[validate-default] Detected $${detectedos}/$${detectedarch} from $(FETCH_ROOT)/default/$(FETCH_IMAGE_FILENAME) manifest." ;\
	echo "[validate-default] Binary from compressed tarball: $$(file -e elf proof)" ;\
	cd ../..

.PHONY: clean-fetches
clean-fetches:
	$(AT)echo "[clean-fetches] Cleaning saved downloaded tarballs" ;\
	for a in default $(ARCHES); do \
		rm -rf $(FETCH_ROOT)/$$a || true;\
	done

