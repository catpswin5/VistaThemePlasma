#!/bin/bash

OUTPUT=$(plasmashell --version)
IFS=' ' read -a array <<< "$OUTPUT"
VERSION="${array[1]}"
URL="https://invent.kde.org/plasma/polkit-kde-agent-1/-/archive/master/polkit-kde-agent-1-master.tar.gz"
ARCHIVE="polkit-kde-agent-1-master.tar.gz"
SRCDIR="polkit-kde-agent-1-master"

INSTALLDST="/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"

if [ ! -f ${INSTALLDST} ]; then
	INSTALLDST="/usr/lib64/libexec/polkit-kde-authentication-agent-1"
fi

if [ ! -d ./build/${SRCDIR} ]; then
	rm -rf build
	mkdir build
	echo "Downloading $ARCHIVE"
	curl $URL -o ./build/$ARCHIVE
	tar -xvf ./build/$ARCHIVE -C ./build/
	echo "Extracted $ARCHIVE"
fi

cp -r patches/* ./build/$SRCDIR/
cd ./build/$SRCDIR/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..
cmake --build .
sudo cp ./bin/polkit-kde-authentication-agent-1 $INSTALLDST

echo "Done. Restart your session for changes to apply."
