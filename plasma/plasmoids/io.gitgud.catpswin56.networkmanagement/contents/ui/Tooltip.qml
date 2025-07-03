/*
 *    SPDX-FileCopyrightText: 2013-2015 Sebastian Kügler <sebas@kde.org>
 *
 *    SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem 1.0
import org.kde.ksvg as KSvg

ColumnLayout {
    id: mainLayout

    anchors.fill: parent
    anchors.topMargin: 8
    anchors.leftMargin: 10

    PlasmaComponents.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: {
            const regex = /W[a-z]+: /gm;
            const str = networkStatus.activeConnections;
            const regexdStr = str.replace(regex, '');
            return regexdStr;
        }
        opacity: 0.75
        color: "black"
        visible: text !== ""
        maximumLineCount: 1
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        spacing: Kirigami.Units.smallSpacing * 2

        Kirigami.Icon {
            animated: false
            source: "network"
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: 125
            wrapMode: Text.WordWrap
            text: {
                if(PlasmaNM.Configuration.airplaneModeEnabled) return i18nc("@info:tooltip", "Middle-click to turn off Airplane Mode");
                else if(airplaneModeAvailable) return i18nc("@info:tooltip", "Middle-click to turn on Airplane Mode");
                else return i18n("Currently connected to a network")
            }
            opacity: 0.75
            color: "black"
            visible: text !== ""
            maximumLineCount: 2
        }

        Item { Layout.minimumWidth: 8 }
    }

    Item { Layout.minimumHeight: 8 }
}

