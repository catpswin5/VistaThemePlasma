#!/bin/bash

cd build/

BUILD_TOOL=make
if [ -f "build.ninja" ]; then
    BUILD_TOOL=ninja
fi
$SU_CMD $BUILD_TOOL uninstall
