#!/bin/sh

mkdir build
cd ./build/
qmake6 ../execbin.pro
make
sudo make install
