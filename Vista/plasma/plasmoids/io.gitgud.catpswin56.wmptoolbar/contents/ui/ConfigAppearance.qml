/*
    SPDX-FileCopyrightText: 2013 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.19 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_toolbarIcon: toolbarIcon.currentIndex
    property string cfg_customIcon
    property alias cfg_hideToolbar: hideToolbar.checked
    property alias cfg_toolbarStyle: toolbarStyle.currentIndex
    property alias cfg_wmp11Basic: wmp11Basic.checked

    Kirigami.FormLayout {
        ColumnLayout {
            anchors.right: parent.right
            anchors.left: parent.left

            Label {
                text: "Icon to show in toolbar:"
            }
            ComboBox {
                id: toolbarIcon
                Layout.fillWidth: true

                Kirigami.FormData.label: i18n("Toolbar icon:")

                model: [
                    "Default texture icon",
                    "Media player icon",
                    "Album art",
                    "Custom icon"
                ]
            }
            Label {
                text: "Path to custom icon:"
                visible: toolbarIcon.currentIndex == 3
            }
            TextField {
                id: customIcon
                visible: toolbarIcon.currentIndex == 3
                Layout.fillWidth: true

                placeholderText: root.cfg_customIcon != "" ? root.cfg_customIcon : ""

                inputMethodHints: Qt.ImhNoPredictiveText

                onTextChanged: {
                    root.cfg_customIcon = text;
                }
            }
            CheckBox {
                id: hideToolbar
                text: "Hide toolbar when there is no multimedia app running:"
            }
            Label {
                text: "Toolbar style:"
            }
            ComboBox {
                id: toolbarStyle
                Layout.fillWidth: true

                Kirigami.FormData.label: i18n("Toolbar style:")

                model: [
                    "WMP 10",
                    "WMP 11"
                ]
            }
            CheckBox {
                id: wmp11Basic
                text: "Use basic variant"
                visible: toolbarStyle.currentIndex == "1"
            }
        }
    }
}
