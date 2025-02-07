/*
 *    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
 *    SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *
 *    SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg as KSvg

PlasmaCore.ToolTipArea {
    id: tooltip

    property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property int expanderSize: Kirigami.Units.iconSizes.smallMedium - Kirigami.Units.smallSpacing / 2
    implicitWidth: expanderSize
    implicitHeight: expanderSize
    activeFocusOnTab: true

    Keys.onPressed: event => {
        switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Select:
                systemTrayState.expanded = !systemTrayState.expanded;
        }
    }

    subText: root.showHidden ? i18n("Hide hidden icons") : i18n("Show hidden icons")

    MouseArea {
        id: arrowMa

        anchors.fill: parent

        hoverEnabled: true

        onClicked: {
            if (root.showHidden) root.showHidden = false
                else root.showHidden = true
        }
    }

    KSvg.SvgItem {
        id: arrow

        z: -1

        anchors.centerIn: parent

        width: expanderSize + 1
        height: expanderSize

        KSvg.SvgItem {
            id: hoverButton
            z: -1 // To prevent layout issues with the MouseArea.
            anchors.fill: parent
            imagePath: Qt.resolvedUrl("svgs/systray.svg")
            elementId: {
                if(arrowMa.containsPress) return "pressed";
                if(arrowMa.containsMouse) return "hover";
                return "";
            }
        }

        imagePath: Qt.resolvedUrl("svgs/systray.svg")
        elementId: root.showHidden ? "collapse" : "expand"
    }
}
