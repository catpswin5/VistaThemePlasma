/*
    SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2025 catpswin56 <>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.ToolTipArea {
    id: appletRoot
    objectName: "io.gitgud.catpswin56.desktop-CompactApplet"

    property Item fullRepresentation
    property Item compactRepresentation
    property PlasmoidItem plasmoidItem

    anchors.fill: parent

    textFormat: plasmoidItem?.toolTipTextFormat ?? 0
    mainItem: plasmoidItem && plasmoidItem.toolTipItem ? plasmoidItem.toolTipItem : null
    mainText: plasmoidItem?.toolTipMainText ?? ""
    subText: plasmoidItem?.toolTipSubText ?? ""
    location: Plasmoid.location
    active: !plasmoidItem?.expanded ?? false

    Layout.minimumWidth: {
        switch (Plasmoid.formFactor) {
            case PlasmaCore.Types.Vertical:
                return 0;
            case PlasmaCore.Types.Horizontal:
                return height;
            default:
                return Kirigami.Units.gridUnit * 3;
        }
    }

    Layout.minimumHeight: {
        switch (Plasmoid.formFactor) {
            case PlasmaCore.Types.Vertical:
                return width;
            case PlasmaCore.Types.Horizontal:
                return 0;
            default:
                return Kirigami.Units.gridUnit * 3;
        }
    }

    onCompactRepresentationChanged: {
        if(compactRepresentation) {
            compactRepresentation.parent = appletRoot;
            compactRepresentation.anchors.fill = appletRoot;
            compactRepresentation.visible = true;
        }
        appletRoot.visible = true;
    }

    Connections {
        target: Plasmoid
        function onContextualActionsAboutToShow() {
            appletRoot.hideImmediately()
        }
    }
}

