/*
    SPDX-FileCopyrightText: 2010 Marco Martin <notmart@gmail.com>
    SPDX-FileCopyrightText: 2016 Jan Grulich <jgrulich@redhat.com>
    SPDX-FileCopyrightText: 2020 George Vogiatzis <gvgeo@protonmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import org.kde.plasma.networkmanagement as PlasmaNM

MouseArea {
    id: listItem

    property bool checked: false
    property bool separator: false
    property bool wirelessSeparator: separator && (appletProxyModel.data(appletProxyModel.index(0, 0), PlasmaNM.NetworkModel.SectionRole) !== "Available connections")
    property rect highlightRect: Qt.rect(0, 0, width, height)

    width: parent.width

    // Sections have spacing above but not below. Will use 2 of them below.
    height: separator ? (wirelessSeparator ? 32 : 16) : parent.height
    hoverEnabled: true

    Rectangle {
        id: separatorLine
        anchors {
            right: parent.right
            left: parent.left
            top: parent.top
        }

        states: [
            State {
                name: "separator"
                when: listItem.separator && !listItem.wirelessSeparator

                AnchorChanges {
                    target: separatorLine

                    anchors.top: undefined
                    anchors.right: listItem.right
                    anchors.left: listItem.left
                    anchors.verticalCenter: listItem.verticalCenter
                }
            },
            State {
                name: "wirelessSeparator"
                when: listItem.wirelessSeparator

                AnchorChanges {
                    target: separatorLine

                    anchors.top: listItem.top
                    anchors.right: listItem.right
                    anchors.left: listItem.left
                    anchors.verticalCenter: undefined
                }
            }
        ]
        color: "#cbcbcb"
        height: 1
        width: parent.width
        visible: separator
    }

    Text {
        anchors.fill: parent

        text: i18n("Wireless Network Connection")
        color: "#40555a"
        verticalAlignment: Text.AlignVCenter
        leftPadding: 10

        visible: wirelessSeparator
    }

    KSvg.FrameSvgItem {
        id: background
        imagePath: "widgets/listitem"
        prefix: "normal"
        anchors.fill: parent
        visible: separator ? false : true
    }

    KSvg.FrameSvgItem {
        id: pressed
        imagePath: "widgets/listitem"
        prefix: "pressed"
        opacity: checked ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

        x: highlightRect.x
        y: highlightRect.y
        height: highlightRect.height
        width: highlightRect.width
    }

    Component.onCompleted: console.log(appletProxyModel.data(appletProxyModel.index(0, 0), PlasmaNM.NetworkModel.SectionRole) + "\n\n\n\n\n");
}
