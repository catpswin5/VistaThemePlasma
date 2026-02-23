#!/bin/sh

export XDG_CONFIG_DIRS="/etc/xdg/vistathemeplasma:/etc/xdg:$XDG_CONFIG_DIRS"
export QML_DISABLE_DISTANCEFIELD=@QML_DISABLE_DISTANCEFIELD@
export USE_UAC_AGENT=1
export PLASMA_DEFAULT_SHELL=io.gitgud.catpswin56.desktop
@CMAKE_INSTALL_FULL_LIBEXECDIR@/plasma-dbus-run-session-if-needed ${CMAKE_INSTALL_FULL_BINDIR}/startplasma-wayland
