/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

BorderImage {
    property PlasmoidItem plasmoidItem

    objectName: "io.gitgud.catpswin56.sidebar-Compact_Representation"

    border {
        left: 1
        right: 1
        top: 1
        bottom: 1
    }
    source: "../ui/pngs/header.png"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5

        spacing: 5

        Kirigami.Icon {
            implicitWidth: 16
            implicitHeight: 16

            source: plasmoidItem.plasmoid.icon
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: plasmoidItem.plasmoid.title
            font.pointSize: 9
            color: "white"
            elide: Text.ElideRight
        }
    }

    activeFocusOnTab: true

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            Plasmoid.activated();
            event.accepted = true; // BUG 481393: Prevent system tray from receiving the event
            break;
        }
    }

    Accessible.name: Plasmoid.title
    Accessible.description: plasmoidItem.toolTipSubText ?? ""
    Accessible.role: Accessible.Button

    MouseArea {
        id: mouseArea

        property bool wasExpanded: false

        anchors.fill: parent
        hoverEnabled: true
        onPressed: wasExpanded = plasmoidItem.expanded
        onClicked: plasmoidItem.expanded = !wasExpanded
    }
}
