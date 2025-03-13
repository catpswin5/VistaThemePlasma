/*
    SPDX-FileCopyrightText: 2013 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: root

    property alias cfg_toolbarIcon: toolbarIcon.currentIndex
    property string cfg_customIcon
    property alias cfg_hideToolbar: hideToolbar.checked
    property alias cfg_toolbarStyle: toolbarStyle.currentIndex
    property alias cfg_wmp11Basic: wmp11Basic.checked

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
        anchors.right: parent.right
        anchors.left: parent.left

        CustomGroupBox {
            Layout.fillWidth: true

            title: i18n("Apperance")

            ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true

                    Text { text: i18n("Icon to show in toolbar:") }
                    ComboBox {
                        id: toolbarIcon

                        model: [
                            i18n("Default texture icon"),
                            i18n("Media player icon"),
                            i18n("Album art"),
                            i18n("Custom icon")
                        ]
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    visible: toolbarIcon.currentIndex == 3

                    Text { text: i18n("Path to custom icon:") }
                    TextField {
                        id: customIcon

                        Layout.fillWidth: true

                        text: Plasmoid.configuration.customIcon
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onTextChanged: root.cfg_customIcon = text;
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    Text { text: i18n("Toolbar style:") }
                    ComboBox {
                        id: toolbarStyle

                        model: [
                            "WMP 10 (Unfinished)",
                            "WMP 11"
                        ]
                    }
                }
            }
        }
        CustomGroupBox {
            Layout.fillWidth: true

            title: i18n("WMP 11 specific tweaks")

            visible: toolbarStyle.currentIndex == 1

            CheckBox {
                id: wmp11Basic
                text: i18n("Use basic variant")
            }
        }
        CustomGroupBox {
            Layout.fillWidth: true

            title: i18n("Tweaks")

            ColumnLayout {
                CheckBox {
                    id: hideToolbar
                    text: i18n("Hide toolbar when there is no multimedia app running")
                }
            }
        }
    }
}
