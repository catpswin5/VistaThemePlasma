/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 * SPDX-FileCopyrightText: 2022 Ismael Asensio <isma.af@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.private.weather
import org.kde.kcmutils as KCM

Item {
    id: root

    property alias cfg_watermarkVisible: watermarkVisible.checked
    property alias cfg_watermarkStyle: watermarkStyle.currentIndex
    property alias cfg_watermarkGenuine: genuineVisible.checked
    property alias cfg_watermarkTrueGenuine: trueNotGenuine.checked

    property string cfg_customText1
    property string cfg_customText2
    property string cfg_customText3

    property alias cfg_fakeSidebar: fakeSidebar.checked
    property alias cfg_sidebarSize: sidebarSize.text

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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Kirigami.Units.gridUnit*4
        anchors.rightMargin: Kirigami.Units.gridUnit*4

        CustomGroupBox {
            Layout.fillWidth: true

            title: "Desktop watermark"

            ColumnLayout {
                anchors.fill: parent

                CheckBox {
                    id: watermarkVisible
                    text: "Enabled"
                }

                RowLayout {
                    Text {
                        text: "Style:"
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        id: watermarkStyle
                        enabled: watermarkVisible.checked

                        model: [
                            "Windows Vista",
                            "VistaThemePlasma",
                            "Custom"
                        ]
                    }
                }

                TextField {
                    id: customText1
                    enabled: watermarkStyle.currentIndex === 2
                    Layout.fillWidth: true

                    placeholderText: i18n("Windows Vista™")

                    text: root.cfg_customText1

                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        if (enabled) {
                            root.cfg_customText1 = text;
                        }
                    }
                }
                TextField {
                    id: customText2
                    enabled: watermarkStyle.currentIndex === 2
                    Layout.fillWidth: true

                    placeholderText: i18n("Build 6002")

                    text: root.cfg_customText2

                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        if (enabled) {
                            root.cfg_customText2 = text;
                        }
                    }
                }
                TextField {
                    id: customText3
                    enabled: watermarkStyle.currentIndex === 2
                    Layout.fillWidth: true

                    placeholderText: i18n("This copy of Windows is not genuine")

                    text: root.cfg_customText3

                    inputMethodHints: Qt.ImhNoPredictiveText

                    onTextChanged: {
                        if (enabled) {
                            root.cfg_customText3 = text;
                        }
                    }
                }

                CheckBox {
                    id: genuineVisible
                    enabled: watermarkVisible.checked
                    text: 'Show "Copy is not genuine" text'
                }
                CheckBox {
                    id: trueNotGenuine
                    visible: genuineVisible.checked
                    text: "TRUE non-genuine copy"
                }
            }
        }
        CustomGroupBox {
            Layout.fillWidth: true

            title: "Fake Sidebar"

            ColumnLayout {
                anchors.fill: parent

                spacing: 0

                CheckBox {
                    id: fakeSidebar
                    text: "Enabled"
                }
                RowLayout {
                    Text {
                        text: i18n("Sidebar size:")

                        opacity: fakeSidebar.checked ? 1.0 : 0.2
                    }
                    TextField {
                        id: sidebarSize

                        enabled: fakeSidebar.checked
                        text: Plasmoid.configuration.sidebarSize
                        onTextChanged: {
                            if(isNaN(Number(sidebarSize.text))) sidebarSize.text = Plasmoid.configuration.sidebarSize;
                        }
                    }
                }
            }
        }
    }
}
