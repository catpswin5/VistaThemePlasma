# SPDX-FileCopyrightText: 2021 Alexander Lohnau <alexander.lohnau@gmx.de>
# SPDX-License-Identifier: BSD-3-Clause

set PATH "/usr/bin:$PATH"

# LD_LIBRARY_PATH only needed if you are building without rpath
# set -x LD_LIBRARY_PATH "/usr/lib:$LD_LIBRARY_PATH"

if test -z "$XDG_DATA_DIRS"
    set -x --path XDG_DATA_DIRS /usr/local/share/ /usr/share/
end
set -x --path XDG_DATA_DIRS "/usr/share" $XDG_DATA_DIRS

if test -z "$XDG_CONFIG_DIRS"
    set -x --path XDG_CONFIG_DIRS /etc/xdg
end
set -x --path XDG_CONFIG_DIRS "/etc/xdg" $XDG_CONFIG_DIRS

set -x --path QT_PLUGIN_PATH "/usr/lib/qt6/plugins" $QT_PLUGIN_PATH
set -x --path QML2_IMPORT_PATH "/usr/lib/qt6/qml" $QML2_IMPORT_PATH

set -x --path QT_QUICK_CONTROLS_STYLE_PATH "/usr/lib/qt6/qml/QtQuick/Controls.2/" $QT_QUICK_CONTROLS_STYLE_PATH
