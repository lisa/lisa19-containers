FETCH_IMAGE_FILENAME ?= image.tar
FETCH_ROOT ?= download
FETCH_OPTS ?= -repo=docker.io -image=$(IMG) -tag=$(VERSION)

.PHONY: validate-options
validate-options:
	$(AT)if [[ $(REGISTRY) != "docker.io" ]]; then \
		echo "[validate-options] Warning: $(REGISTRY) may not be supported." ;\
	fi

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
