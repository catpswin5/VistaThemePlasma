/*
 *    SPDX-FileCopyrightText: 2013-2015 Sebastian Kügler <sebas@kde.org>
 *
 *    SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem
import org.kde.ksvg as KSvg

ColumnLayout {
    id: mainLayout

    property var batteryControl
    property var powerProfilesControl

    anchors.fill: parent
    anchors.topMargin: 8
    anchors.leftMargin: 10

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        spacing: Kirigami.Units.smallSpacing * 2

        FlyoutBatteryIcon {
            id: batteryIcon

            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium

            hasBattery: batteryControl.pluggedIn
            percent: batteryControl.percent
            pluggedIn: batteryControl.pluggedIn
            batteryType: batteryControl.type
            broken: batteryControl.capacity > 0 && batteryControl.capacity < 50
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.maximumWidth: 125
            wrapMode: Text.WordWrap
            text: batterymonitor.toolTipMainText
            opacity: 0.75
            visible: text !== ""
            maximumLineCount: 2
            color: "black"
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents.Label {
            text: i18n("Current power plan:")
            maximumLineCount: 1
            color: "black"
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            text: {
                if (powerProfilesControl.activeProfile == "") {
                    return i18n("Unknown")
                } else {
                    return powerProfilesControl.activeProfile;
                }
            }
            font.capitalization: Font.Capitalize
            color: "#1370ab"
            maximumLineCount: 1
        }

        Item { Layout.minimumWidth: 8 }
    }

    Item { Layout.minimumHeight: 8 }
}
