/*
 *  Copyright 2015 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

Item {
    id: item

    signal clicked

    property alias text: label.text

    property bool isFramed: true
    property string prefix: ""
    property alias glyphWidth: glyphItem.width
    property alias glyphHeight: glyphItem.height

    property alias elementWidth: svgItem.implicitWidth
    property alias elementHeight: svgItem.implicitHeight

    property bool showLabel: false

    width: isFramed ? elementWidth : implicitWidth
    height: isFramed ? elementHeight : implicitHeight

    implicitWidth: contentArea.width
    implicitHeight: contentArea.height

    MouseArea {
        id: mouseArea

        anchors.fill: contentArea

        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        onClicked: item.clicked()
    }

    KSvg.FrameSvgItem {
        id: frameSvgItem

        anchors.fill: parent

        KSvg.SvgItem {
            id: glyphItem

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: mouseArea.containsPress ? 1 : 0
            anchors.verticalCenterOffset: mouseArea.containsPress ? 1 : 0

            imagePath: Qt.resolvedUrl("svgs/" + startStyles.currentStyle.styleName + "/" + "startmenu-buttons.svg")
            elementId: item.prefix

            z: 1
        }

        imagePath: Qt.resolvedUrl("svgs/" + startStyles.currentStyle.styleName + "/" + "startmenu-buttons.svg")
        prefix: item.prefix + (mouseArea.containsMouse ? (mouseArea.containsPress ? "-pressed": "-hover") : "")

        visible: item.isFramed
    }

    RowLayout {
        id: contentArea

        visible: !item.isFramed

        KSvg.SvgItem {
            id: svgItem

            imagePath: Qt.resolvedUrl("svgs/" + startStyles.currentStyle.styleName + "/" + "startmenu-buttons.svg")
            elementId: item.prefix + (mouseArea.containsMouse ? (mouseArea.containsPress ? "-pressed": "-hover") : "")
        }

        PlasmaComponents.Label {
            id: label

            Layout.fillWidth: true
            Layout.fillHeight: true

            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Sunken
            styleColor: "transparent"

            visible: item.showLabel
        }
    }
}
