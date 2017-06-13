#!/bin/bash -eu

##################################################
# This script pulls docker images from hyperledger
# docker hub repository and Tag it as
# hyperledger/fabric-<image> latest tag
##################################################

#Set ARCH variable i.e ppc64le,s390x,x86_64,i386
ARCH=`uname -m`

dockerFabricPull() {
  local FABRIC_TAG=$1
  for IMAGES in peer orderer couchdb ccenv javaenv kafka zookeeper; do
      echo "==> FABRIC IMAGE: $IMAGES"
      echo
      docker pull talium/fabric-$IMAGES:$FABRIC_TAG
      docker tag talium/fabric-$IMAGES:$FABRIC_TAG talium/fabric-$IMAGES
  done
}

dockerCaPull() {
      local CA_TAG=$1
      echo "==> FABRIC CA IMAGE"
      echo
      docker pull talium/fabric-ca:$CA_TAG
      docker tag talium/fabric-ca:$CA_TAG talium/fabric-ca
}
usage() {
      echo "Description "
      echo
      echo "Pulls docker images from talium dockerhub repository"
      echo "tag as talium/fabric-<image>:latest"
      echo
      echo "USAGE: "
      echo
      echo "./download-dockerimages.sh [-c <fabric-ca tag>] [-f <fabric tag>]"
      echo "      -c fabric-ca docker image tag"
      echo "      -f fabric docker image tag"
      echo
      echo
      echo "EXAMPLE:"
      echo "./download-dockerimages.sh -c x86_64-1.0.0-alpha -f x86_64-1.0.0-alpha"
      echo
      echo "By default, pulls fabric-ca and fabric 1.0.0-alpha docker images"
      echo "from talium dockerhub"
      exit 0
}

while getopts "\?hc:f:" opt; do
  case "$opt" in
     c) CA_TAG="$OPTARG"
        echo "Pull CA IMAGES"
        ;;

     f) FABRIC_TAG="$OPTARG"
        echo "Pull FABRIC TAG"
        ;;
     \?|h) usage
        echo "Print Usage"
        ;;
  esac
done

: ${CA_TAG:="$ARCH-1.0.0-alpha"}
: ${FABRIC_TAG:="$ARCH-1.0.0-alpha"}

echo "===> Pulling fabric Images"
dockerFabricPull ${FABRIC_TAG}

echo "===> Pulling fabric ca Image"
dockerCaPull ${CA_TAG}
echo
echo "===> List out talium docker images"
docker images | grep talium*
