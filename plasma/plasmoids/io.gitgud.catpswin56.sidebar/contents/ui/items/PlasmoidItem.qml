/*
 *  SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid as Plasmoid

AbstractItem {
    id: plasmoidContainer

    property Plasmoid.PlasmoidItem applet

    text: applet ? applet.plasmoid.title : ""

    itemId: applet ? applet.plasmoid.id : ""
    status: applet ? applet.plasmoid.status : PlasmaCore.Types.UnknownStatus
    active: root.activeApplet !== applet

    onClicked: (mouse) => {
        if (applet) {
            if (mouse.button === Qt.RightButton) {
                plasmoid.showPlasmoidMenu(applet, mouse.x, mouse.y);
            }
        }
    }
}
