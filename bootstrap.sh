#!/bin/bash

export ARCH=$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(go env GOARCH)

sh download-dockerimages.sh -c $(uname -m)-v1.0.0-alpha2 -f $(uname -m)-v1.0.0-alpha2


