/*
    SPDX-FileCopyrightText: 2013 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

KCM.SimpleKCM {
    property alias cfg_groupPopups: groupPopups.checked
    property alias cfg_onlyGroupWhenFull: onlyGroupWhenFull.checked
    property alias cfg_showOnlyCurrentScreen: showOnlyCurrentScreen.checked
    property alias cfg_showOnlyCurrentDesktop: showOnlyCurrentDesktop.checked
    property alias cfg_showOnlyCurrentActivity: showOnlyCurrentActivity.checked
    property alias cfg_showOnlyMinimized: showOnlyMinimized.checked
    property alias cfg_minimizeActiveTaskOnClick: minimizeActive.checked
    property alias cfg_unhideOnAttention: unhideOnAttention.checked

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

            title: "Grouping"

            ColumnLayout {
                Layout.fillWidth: true

                CheckBox {
                    id: groupPopups
                    text: i18n("Group tasks together")
                }
                CheckBox {
                    id: onlyGroupWhenFull

                    text: i18n("Group only when the Task Manager is full")
                    enabled: groupPopups.checked
                }
            }
        }

        CustomGroupBox {
            Layout.fillWidth: true

            title: "Task"

            ColumnLayout {
                Layout.fillWidth: true

                CheckBox {
                    id: minimizeActive

                    text: i18n("Clicking minimizes the task")
                }

                CheckBox {
                    id: unhideOnAttention

                    text: i18n("Unhide panel when attention is wanted")
                }

                RowLayout {
                    Text { Layout.alignment: Qt.AlignTop; text: "Show only tasks:" }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        CheckBox {
                            id: showOnlyCurrentScreen
                            text: i18n("From current screen")
                        }

                        CheckBox {
                            id: showOnlyCurrentDesktop
                            text: i18n("From current desktop")
                        }

                        CheckBox {
                            id: showOnlyCurrentActivity
                            text: i18n("From current activity")
                        }

                        CheckBox {
                            id: showOnlyMinimized

                            text: i18n("That are minimized")

                            visible: false
                        }
                    }
                }
            }
        }
    }
}
