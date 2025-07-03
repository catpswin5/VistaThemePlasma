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

RowLayout {
    id: mainLayout

    anchors.fill: parent
    anchors.topMargin: 8

    Kirigami.Icon {
        animated: false
        source: "audio-speakers"
        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
        Layout.leftMargin: 10
        Layout.bottomMargin: 8
    }

    ColumnLayout {
        spacing: 0

        Layout.rightMargin: 4
        Layout.bottomMargin: 10

        Kirigami.Heading {
            level: 3
            Layout.fillWidth: true
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            text: i18n("Volume: %1%", main.volumePercent(PreferredDevice.sink.volume))
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
            color: "black"
            maximumLineCount: 1
        }
    }
}
