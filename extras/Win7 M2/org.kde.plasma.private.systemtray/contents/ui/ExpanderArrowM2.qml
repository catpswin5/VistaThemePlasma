/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg as KSvg

PlasmaCore.ToolTipArea {
    id: tooltip

    readonly property int arrowAnimationDuration: Kirigami.Units.shortDuration
    property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property int iconSize: Kirigami.Units.smallMedium
    implicitWidth: 8
    implicitHeight: 8
    activeFocusOnTab: true

    Accessible.name: subText
    Accessible.description: i18n("Show all the items in the system tray in a popup")
    Accessible.role: Accessible.Button
    Accessible.onPressAction: systemTrayState.expanded = !systemTrayState.expanded

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            systemTrayState.expanded = !systemTrayState.expanded;
        }
    }

    subText: systemTrayState.expanded ? i18n("Close popup") : i18n("Show hidden icons")

    property bool wasExpanded

    property bool flyoutExpanded: systemTrayState.expanded
    onFlyoutExpandedChanged: {
        if(flyoutExpanded) {
            tooltip.hideImmediately();
        }
    }

    TapHandler {
        id: tapHandlerExpander
        onPressedChanged: {
            if (pressed) {
                tooltip.wasExpanded = systemTrayState.expanded;
            }
        }
        onTapped: {
            systemTrayState.expanded = !tooltip.wasExpanded;
            expandedRepresentation.hiddenLayout.currentIndex = -1;
        }
    }

    KSvg.SvgItem {
        id: arrow

        anchors.centerIn: parent

        width: 6
        height: 8

        imagePath: "widgets/arrows"
        elementId: {
            if (systemTrayState.expanded && expandedRepresentation.hiddenLayout.visible) return "down-arrow"
                else return "up-arrow"
        }
    }
    KSvg.SvgItem {
        id: hoverButton
        z: -1
        anchors.fill: parent
        anchors.margins: -Kirigami.Units.smallSpacing
        imagePath: Qt.resolvedUrl("svgs/systray.svg")
        elementId: {
            if(tooltip.containsPress || (systemTrayState.expanded && expandedRepresentation.hiddenLayout.visible)) return "m2-hover";
            if(tooltip.containsMouse) return "m2-hover";
            return "normal"; // The normal state actually just makes the button invisible.
        }
    }
}
