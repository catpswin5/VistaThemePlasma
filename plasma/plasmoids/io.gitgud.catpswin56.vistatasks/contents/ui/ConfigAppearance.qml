/*
 *    SPDX-FileCopyrightText: 2013 Eike Hein <hein@kde.org>
 *
 *    SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.19 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    readonly property bool iconOnly: Plasmoid.configuration.showLabels //Plasmoid.pluginName === "org.kde.plasma.icontasks"

    property bool cfg_showLabels: true // TODO: remove this

    property alias cfg_showPreviews: showPreviews.checked
    property alias cfg_disableHottracking: disableHottracking.checked
    property alias cfg_disableJumplists: disableJumplists.checked
    property alias cfg_draggingEnabled: draggingEnabled.checked
    property alias cfg_enableAnimations: enableAnimations.checked
    property alias cfg_showMore: showMore.checked

    component CustomGroupBox: GroupBox {
        id: gbox
        label: Label {
            id: lbl
            x: gbox.leftPadding + 2
            y: lbl.implicitHeight/2-gbox.bottomPadding-1
            width: lbl.implicitWidth
            text: gbox.title
            elide: Text.ElideRight
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -2
                anchors.rightMargin: -2
                color: Kirigami.Theme.backgroundColor
                z: -1
            }
        }
        background: Rectangle {
            y: gbox.topPadding - gbox.bottomPadding*2
            width: parent.width
            height: parent.height - gbox.topPadding + gbox.bottomPadding*2
            color: "transparent"
            border.color: "#d5dfe5"
            radius: 3
        }
    }

    ColumnLayout {
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
        }

        spacing: 0

        CheckBox {
            id: showPreviews
            text: i18n("Enable window previews")
        }
        CheckBox {
            id: disableHottracking
            text: i18n("Disable hot tracking")
        }
        CheckBox {
            id: disableJumplists
            text: i18n("Use traditional context menus instead of jumplists")
        }
        CheckBox {
            id: showMore
            enabled: disableJumplists.checked
            text: i18n("Show more items in context menus")
        }
        CheckBox {
            id: enableAnimations
            text: i18n("Enable extra animations")
        }
        CheckBox {
            id: draggingEnabled
            text: i18n("Enable dragging")
        }
    }
}

