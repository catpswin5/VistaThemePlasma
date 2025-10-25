/*
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Layouts 1.13

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore

import org.kde.kirigami 2.13 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property bool cfg_scaleIconsToFit
    property int cfg_iconSpacing

    property alias cfg_gapSize: gapSize.value
    property alias cfg_dontOffset: dontOffset.checked

    property alias cfg_batteryEnabled: batteryEnabled.checked
    property alias cfg_networkEnabled: networkEnabled.checked
    property alias cfg_soundEnabled: soundEnabled.checked

    property alias cfg_showPinButton: pinButton.checked

    component CustomGroupBox: QQC2.GroupBox {
        id: gbox
        label: QQC2.Label {
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
        CustomGroupBox {
            id: iconSizeGroup

            Layout.fillWidth: true

            title: i18n("Icon Size")

            ColumnLayout {
                spacing: 0

                QQC2.RadioButton {
                    enabled: !Kirigami.Settings.tabletMode
                    text: i18n("Small")
                    checked: cfg_scaleIconsToFit == false && !Kirigami.Settings.tabletMode
                    onToggled: cfg_scaleIconsToFit = !checked
                }
                QQC2.RadioButton {
                    id: automaticRadioButton
                    enabled: !Kirigami.Settings.tabletMode
                    text: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? i18n("Scale with Panel height")
                    : i18n("Scale with Panel width")
                    checked: cfg_scaleIconsToFit == true || Kirigami.Settings.tabletMode
                    onToggled: cfg_scaleIconsToFit = checked
                }
                QQC2.Label {
                    visible: Kirigami.Settings.tabletMode
                    text: i18n("Automatically enabled when in Touch Mode")
                    font: Kirigami.Theme.smallFont
                }
            }

        }

        CustomGroupBox {
            id: iconSettings

            Layout.fillWidth: true

            title: i18n("Icon Settings")

            ColumnLayout {
                spacing: 0

                RowLayout {
                    Text { text: i18n("Gap size:") }

                    QQC2.SpinBox {
                        id: gapSize
                        from: 0
                    }
                }

                QQC2.CheckBox {
                    id: dontOffset
                    text: i18n("Don't offset icons")
                }
            }
        }

        CustomGroupBox {
            id: systemIcons

            Layout.fillWidth: true

            title: i18n("System Icons")

            ColumnLayout {
                spacing: 0

                QQC2.CheckBox {
                    id: batteryEnabled
                    text: i18n("Battery")
                }

                QQC2.CheckBox {
                    id: networkEnabled
                    text: i18n("Network")
                }

                QQC2.CheckBox {
                    id: soundEnabled
                    text: i18n("Sound")
                }
            }
        }

        CustomGroupBox {
            id: flyoutSettings

            Layout.fillWidth: true

            title: i18n("Flyout settings")

            ColumnLayout {
                spacing: 0

                QQC2.CheckBox {
                    id: pinButton
                    text: i18n("Disable pin button")
                }
            }
        }
    }
}
