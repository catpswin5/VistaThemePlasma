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

        Image {
            anchors.fill: face
            source: "/usr/share/vistathemeplasma/fallback-picture.png"
            visible: face.status === Image.Null || face.status === Image.Error
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
