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

RowLayout {
    id: mainLayout

    property var time

    anchors.fill: parent
    anchors.topMargin: 8

    spacing: 8

    Image {
        source: "pngs/calendar.png"
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        Layout.leftMargin: 10
        Layout.bottomMargin: 8
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: time
        opacity: 0.75
        visible: text !== ""
        color: "black"
        maximumLineCount: 1
        Layout.rightMargin: 4
        Layout.bottomMargin: 10
    }
}

