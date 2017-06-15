#!/bin/bash

export ARCH=$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(go env GOARCH)

sh download-dockerimages.sh -c $(uname -m)-1.0.0-beta -f $(uname -m)-1.0.0-beta


