PULL_BINARY := $(shell pwd -P)/bin/pull

pull-binary: $(PULL_BINARY)

$(PULL_BINARY): cmd/main.go pkg/pull/pull.go
	$(AT)echo "[pull-binary] Compiling 'pull' binary to $(PULL_BINARY)" ;\
	mkdir $(shell pwd -P)/bin 2>/dev/null || true  ;\
	cd cmd ;\
	go build -o $(PULL_BINARY) ;\
	cd ..

.PHONY: pull-app-clean
pull-app-clean:
	$(AT)echo "[pull-app-clean] Cleaning 'pull' binary" ;\
	rm -f $(PULL_BINARY) || true
