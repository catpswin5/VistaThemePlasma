/*
    SPDX-FileCopyrightText: 2013-2015 Sebastian Kügler <sebas@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kwindowsystem

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

import org.kde.kwindowsystem 1.0

ColumnLayout {

    KSvg.FrameSvgItem {
        z: -1

        anchors.margins: -5
        anchors.fill: text

        id: tooltipBackground
        imagePath: "solid/widgets/tooltip"
        prefix: ""
    }
    Text {
        Layout.topMargin: -9
        id: text
        text: "Pinned program."
        font.pointSize: 9
    }
}
