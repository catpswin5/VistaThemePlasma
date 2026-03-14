/*
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import Qt5Compat.GraphicalEffects

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: root

    property alias avatarPath: face.source

    implicitWidth: 190
    implicitHeight: 190

    Item {
        id: imageSource

        anchors.centerIn: parent

        width: 126
        height: 126

        LinearGradient {
            id: gradient

            anchors.fill: parent

            start: Qt.point(0,0)
            end: Qt.point(gradient.width, gradient.height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#eeecee" }
                GradientStop { position: 1.0; color: "#a39ea3" }
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 0.5 // because mockup says so...

            source: "user-symbolic"

            visible: (face.status == Image.Error || face.status == Image.Null)
        }

        Image {
            id: face

            anchors.fill: parent

            source: avatarPath
            fillMode: Image.PreserveAspectCrop
        }
    }

    Image {
        anchors.fill: parent
        source: "../images/pfp/user.png"
    }
}
