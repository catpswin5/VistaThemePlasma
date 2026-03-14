/*
 *   Copyright 2014 Marco Martin <mart@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License version 2,
 *   or (at your option) any later version, as published by the Free
 *   Software Foundation
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Templates

import QtMultimedia

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

import aeroshell.utils as AeroShellUtils

import "../components"

Item {
    id: root
    z: -9

    property int stage

    onStageChanged: {
        if (stage == 6) {
            transitionAnim.opacity = 1;
        }
    }

    Rectangle {
        color: "#1D5F7A"
        anchors.fill: parent
    }

    property int framenumber: 1

    AeroShellUtils.SDDM { id: sddm }

    Image {
        id: bg
        anchors.fill: parent
        fillMode: Image.Stretch
        source: Qt.resolvedUrl("/usr/share/sddm/themes/" + sddm.currentSDDMTheme + "/background")
    }

    Status {
        id: statusText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -36
        statusText: i18nd("okular", "Welcome")
        speen: true
    }

    Image {
        id: watermark

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48 - (height / 2)

        anchors.horizontalCenter: parent.horizontalCenter

        source: "../images/watermark.png"
    }

    Rectangle {
        id: transitionAnim
        opacity: 0
        color: "black"
        anchors.fill: parent
        Behavior on opacity {
            NumberAnimation { duration: 640; }
        }
    }

    Component.onCompleted: executable.exec("kreadconfig6 --file \"/usr/share/sddm/themes/vista-theme-mod/theme.conf.user\" --group \"General\" --key \"background\"")
}
