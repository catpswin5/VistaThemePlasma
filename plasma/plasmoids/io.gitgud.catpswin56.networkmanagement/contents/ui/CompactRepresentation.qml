/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

MouseArea {
    id: root

    required property bool airplaneModeAvailable
    required property string iconName

    hoverEnabled: true

    acceptedButtons: airplaneModeAvailable ? Qt.LeftButton | Qt.MiddleButton : Qt.LeftButton

    property bool wasExpanded

    onPressed: wasExpanded = mainWindow.expanded
    onClicked: mouse => {
        if (airplaneModeAvailable && mouse.button === Qt.MiddleButton) {
            mainWindow.planeModeSwitchAction.trigger();
        } else {
            mainWindow.expanded = !wasExpanded;
        }
    }

    Kirigami.Icon {
        id: connectionIcon

        anchors.fill: parent
        source: root.iconName
    }

    // Component.onCompleted: {
    //     fullRepresentationItem.connectionModel = fullRepresentationItem.networkModelComponent.createObject(fullRepresentationItem)
    // }
}
