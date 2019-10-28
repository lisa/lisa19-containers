#!/bin/bash

set -e

IMG=thedoh/lisa19
REGISTRY=docker.io
VERSION=19.10.1

# Plan B with GCR:
#IMG=dulcet-iterator-213018
#REGISTRY=us.gcr.io
#VERSION=19.10.1


pause() {
  local step="${1}"
  ps1
  echo -n "# Next step: ${step}"
  read
}

ps1() {
  echo -ne "\033[01;32m${USER}@$(hostname -s) \033[01;34m$(basename $(pwd)) \$ \033[00m"
}

echocmd() {
  echo "$(ps1)$@"
}

docmd() {
  echocmd $@
  $@
}

step0() {
  local registry="${1}" img="${2}" version="${3}"
  # Mindful of tokens in ~/.docker/config.json
  docmd grep experimental ~/.docker/config.json
  
  docmd cd ~/go/src/github.com/lisa/lisa19-containers
  
  pause "This is what we'll be building"
  docmd export REGISTRY=${registry}
  docmd export IMG=${img}
  docmd export VERSION=${version}
  docmd make REGISTRY=${registry} IMG=${img} VERSION=${version} clean
}

step1() {
  local registry="${1}" img="${2}" version="${3}"
  
  docmd docker build --no-cache --platform=linux/amd64 --build-arg=GOARCH=amd64 -t ${REGISTRY}/${IMG}:amd64-${VERSION} .
  pause "ARM64 image next"
  docmd docker build --no-cache --platform=linux/arm64 --build-arg=GOARCH=arm64 -t ${REGISTRY}/${IMG}:arm64-${VERSION} . 
}

step2() {
  local registry="${1}" img="${2}" version="${3}" origpwd=$(pwd) savedir=$(mktemp -d) jsontemp=$(mktemp -t XXXXX)
  chmod 700 $jsontemp $savedir
  # Set our way back home and get ready to fix our arm64 image to amd64.
  echocmd 'origpwd=$(pwd)'
  echocmd 'savedir=$(mktemp -d)'
  echocmd "mkdir -p \$savedir/change"
  mkdir -p $savedir/change &>/dev/null
  echocmd "docker save ${REGISTRY}/${IMG}:arm64-${VERSION} 2>/dev/null 1> \$savedir/image.tar"
  docker save ${REGISTRY}/${IMG}:arm64-${VERSION} 2>/dev/null 1> $savedir/image.tar
  pause "untar the image to access its metadata"
  
  echocmd "cd \$savedir/change"
  cd $savedir/change
  echocmd tar xf \$savedir/image.tar
  tar xf $savedir/image.tar
  docmd ls -l
  
  pause "find the JSON config file"
  echocmd 'jsonfile=$(jq -r ".[0].Config" manifest.json)'
  jsonfile=$(jq -r ".[0].Config" manifest.json)
  
  pause "notice the original metadata says amd64"
  echocmd jq '{architecture: .architecture, ID: .config.Image}' \$jsonfile
  jq '{architecture: .architecture, ID: .config.Image}' $jsonfile
  
  pause "Change from amd64 to arm64 using a temp file"
  echocmd "jq '.architecture = \"arm64\"' \$jsonfile > \$jsontemp"
  jq '.architecture = "arm64"' $jsonfile > $jsontemp
  echocmd /bin/mv -f -- \$jsontemp \$jsonfile
  /bin/mv -f -- $jsontemp $jsonfile

  pause "Check to make sure the config JSON file says arm64 now"
  echocmd jq '{architecture: .architecture, ID: .config.Image}' \$jsonfile
  jq '{architecture: .architecture, ID: .config.Image}' $jsonfile
  
  pause "delete the image with the incorrect metadata"
  docmd docker rmi ${REGISTRY}/${IMG}:arm64-${VERSION}
  
  pause "Re-compress the ARM64 image and load it back into Docker, then clean up the temp space"
  echocmd 'tar cf - * | docker load'
  tar cf - * | docker load

  docmd cd $origpwd
  echocmd "/bin/rm -rf -- \$savedir"
  /bin/rm -rf -- $savedir &>/dev/null
}

step3() {
  local registry="${1}" img="${2}" version="${3}"
  docmd docker push ${registry}/${img}:amd64-${version}
  pause "push ARM64 image to ${registry}"
  docmd docker push ${registry}/${img}:arm64-${version}
}

step4() {
  local registry="${1}" img="${2}" version="${3}"
  docmd docker manifest create ${registry}/${img}:${version} ${registry}/${img}:arm64-${version} ${registry}/${img}:amd64-${version}
  
  pause "add a reference to the amd64 image to the manifest list"
  docmd docker manifest annotate ${registry}/${img}:${version} ${registry}/${img}:amd64-${version} --os linux --arch amd64
  pause "now add arm64"
  docmd docker manifest annotate ${registry}/${img}:${version} ${registry}/${img}:arm64-${version} --os linux --arch arm64
}

step5() {
  local registry="${1}" img="${2}" version="${3}"
  docmd docker manifest push ${registry}/${img}:${version}
}


step6() {
  local registry="${1}" img="${2}" version="${3}"
  docmd make REGISTRY=${registry} IMG=${img} VERSION=${version} clean
  
  pause "ask docker.io if ${img}:${version} has a linux/amd64 manifest, and run it"
  docmd docker pull --platform linux/amd64 ${registry}/${img}:${version}
  docmd docker run --rm -i ${registry}/${img}:${version}
  
  pause "clean slate again"
  docmd make REGISTRY=${registry} IMG=${img} VERSION=${version} clean
  
  pause "now repeat for linux/arm64 and see what it gives us"
  docmd docker pull --platform linux/arm64 ${registry}/${img}:${version}
  set +e
  docmd docker run --rm -i ${registry}/${img}:${version}
  set -e
  if [[ $(uname -s) == "Darwin" ]]; then
    pause "note about Docker on Mac and binfmt_misc: binfmt_misc lets a mac run arm64 binaries in the Docker VM"
  fi
}

pause "initial setup"
step0 ${REGISTRY} ${IMG} ${VERSION}
pause "1 build constituent images"
step1 ${REGISTRY} ${IMG} ${VERSION}

pause "2 fix ARM64 metadata"
step2 ${REGISTRY} ${IMG} ${VERSION}

pause "3 push constituent images up to docker.io"
step3 ${REGISTRY} ${IMG} ${VERSION}

pause "4 build the manifest list for the image"
step4 ${REGISTRY} ${IMG} ${VERSION}

pause "5 Push the manifest list to docker.io"
step5 ${REGISTRY} ${IMG} ${VERSION}

pause "6 clean slate, and validate the list-based image"
step6 ${REGISTRY} ${IMG} ${VERSION}

docmd echo 'Manual steps all done!'
make REGISTRY=${REGISTRY} IMG=${IMG} VERSION=${VERSION} clean &>/dev/null
