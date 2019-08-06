ARG GOARCH=amd64

FROM golang:1.12 as build

ARG GOARCH

RUN mkdir -p /go/src/github.com/lisa/lisa19-containers
WORKDIR /go/src/github.com/lisa/lisa19-containers

COPY proof.go .

# Should be able to run ./proof to get the arch we should be running as,
# decided at build time here.
RUN \
  CGO_ENABLED=0 GOARCH=${GOARCH} go build -ldflags '-extldflags "-static"' -a proof.go && \
  echo -n "$(go env GOOS)/$(go env GOARCH)" > proof.txt

######
FROM scratch
ARG GOARCH

COPY --from=build /go/src/github.com/lisa/lisa19-containers/proof /proof
COPY --from=build /go/src/github.com/lisa/lisa19-containers/proof.txt /proof.txt

LABEL \
  Architecture="${GOARCH}" \
  maintainer="Lisa Seelye <lisa@thedoh.com>"

CMD [ "/proof" ]