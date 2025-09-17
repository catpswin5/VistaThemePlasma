/*
 *    SPDX-FileCopyrightText: 2013 Eike Hein <hein@kde.org>
 *
 *    SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_disableHottracking: disableHottracking.checked
    property alias cfg_disableJumplists: disableJumplists.checked
    property alias cfg_draggingEnabled: draggingEnabled.checked
    property alias cfg_showMore: showMore.checked
    property alias cfg_showProgress: showProgress.checked
    property alias cfg_hoverFadeAnim: hoverFadeAnim.checked

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

        CustomGroupBox {
            Layout.fillWidth: true

            title: "Tweaks"

            ColumnLayout {
                Layout.fillWidth: true

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
                    id: draggingEnabled
                    text: i18n("Enable dragging")
                }
                CheckBox {
                    id: showProgress
                    text: i18n("Show app progress bar")
                }
                CheckBox {
                    id: hoverFadeAnim
                    enabled: disableHottracking.checked
                    text: i18n("Enable hover fade animation")
                }
            }
        }
    }
}

