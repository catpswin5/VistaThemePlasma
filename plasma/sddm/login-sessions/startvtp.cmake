#!/bin/sh

export XDG_CONFIG_DIRS="/etc/xdg/vistathemeplasma:/etc/xdg:$XDG_CONFIG_DIRS"
export QML_DISABLE_DISTANCEFIELD=$(kreadconfig6 --file vistathemeplasmarc --group General --key qmlDisableDistanceField --default 1)
export USE_UAC_AGENT=1
export PLASMA_DEFAULT_SHELL=io.gitgud.catpswin56.desktop
startplasma-x11

