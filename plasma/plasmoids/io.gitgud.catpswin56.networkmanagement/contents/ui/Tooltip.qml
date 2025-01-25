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

Item {
    property int preferredTextWidth: Kirigami.Units.gridUnit * 10
    property bool compositing: KWindowSystem.isPlatformX11 ? KX11Extras.compositingActive : true

    // Used for margins
    KSvg.FrameSvgItem {
        id: tooltipSvg
        imagePath: compositing ? "widgets/tooltip" : "opaque/widgets/tooltip"
        visible: false
    }

    implicitWidth: mainLayout.implicitWidth - tooltipSvg.margins.left + Kirigami.Units.smallSpacing*4
    implicitHeight: mainLayout.implicitHeight - tooltipSvg.margins.left*2 + Kirigami.Units.smallSpacing*4

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    KSvg.FrameSvgItem {
        id: tooltipBackground
        imagePath: "solid/widgets/tooltip"
        prefix: ""
        anchors {
            //fill: parent
            top: parent.top
            left: parent.left
            leftMargin: -tooltipSvg.margins.left
            topMargin: -tooltipSvg.margins.top
        }

        width: mainLayout.width + tooltipSvg.margins.left + Kirigami.Units.smallSpacing*4
        height: mainLayout.height + Kirigami.Units.smallSpacing*4
    }
    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent

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
                Layout.leftMargin: -Kirigami.Units.smallSpacing*2/1.6
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 125
                wrapMode: Text.WordWrap
                text: {
                    if(PlasmaNM.Configuration.airplaneModeEnabled) return i18nc("@info:tooltip", "Middle-click to turn off Airplane Mode");
                    else if(airplaneModeAvailable) return i18nc("@info:tooltip", "Middle-click to turn on Airplane Mode");
                    else return "Currently connected to a network"
                }
                opacity: 0.75
                visible: text !== ""
                maximumLineCount: 2
            }
        }
    }
}

