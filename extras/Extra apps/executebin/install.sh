#!/bin/sh

mkdir build
cd ./build/
qmake6 ../executebin.pro
make
sudo make install
