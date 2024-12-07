/*
 *    SPDX-FileCopyrightText: 2013-2015 Sebastian Kügler <sebas@kde.org>
 *
 *    SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem 1.0
import org.kde.ksvg as KSvg

import org.kde.plasma.private.volume

Item {
    property int preferredTextWidth: Kirigami.Units.gridUnit * 10
    property bool compositing: KWindowSystem.isPlatformX11 ? KX11Extras.compositingActive : true
    //KWindowSystem { id: kwindowsystem }

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
    RowLayout {
        id: mainLayout
        anchors.centerIn: parent

        Kirigami.Icon {
            animated: false
            source: "audio-speakers"
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            Layout.leftMargin: -Kirigami.Units.smallSpacing*2/1.6
        }

        ColumnLayout {
            Layout.maximumWidth: preferredTextWidth
            spacing: 0

            Kirigami.Heading {
                level: 3
                Layout.fillWidth: true
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                text: i18n("Volume at %1%", main.volumePercent(PreferredDevice.sink.volume))
                textFormat: Text.PlainText
                color: "#003399"
                visible: text !== ""
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: {
                    let lines = [];
                    if (PreferredDevice.sink && main.paSinkFilterModel.count > 1 && !isDummyOutput(PreferredDevice.sink)) {
                        lines.push(nodeName(PreferredDevice.sink))
                    }
                    return lines.join("\n");
                }
                opacity: 0.75
                visible: text !== ""
                maximumLineCount: 8
            }
        }
    }
}

