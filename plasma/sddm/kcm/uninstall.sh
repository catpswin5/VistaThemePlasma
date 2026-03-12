#!/bin/bash

BUILD_TOOL=make
SU_CMD=sudo
if [[ -z "$(command -v $SU_CMD)" ]]; then
    SU_CMD=doas
    if [[ -z "$(command -v $SU_CMD)" ]]; then
        echo "Neither sudo or doas were detected on the system."
        exit
    fi
fi

# install first
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr .
cmake --build build
$SU_CMD cmake --install build

# uninstall later
cd build/
if [ -f "build.ninja" ]; then
    BUILD_TOOL=ninja
fi
$SU_CMD $BUILD_TOOL uninstall
