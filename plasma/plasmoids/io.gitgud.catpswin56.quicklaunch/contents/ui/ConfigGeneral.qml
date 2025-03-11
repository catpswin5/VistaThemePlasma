/*
 *  SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    readonly property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical || (plasmoid.formFactor == PlasmaCore.Types.Planar && plasmoid.height > plasmoid.width)

    property alias cfg_maxSectionCount: maxSectionCount.value

    property alias cfg_showLauncherNames: showLauncherNames.checked
    property alias cfg_enablePopup: enablePopup.checked
    property alias cfg_extraPadding: extraPadding.checked
    property alias cfg_extraPaddingSize: extraPaddingSize.value
    property alias cfg_hoverFadeAnim: hoverFadeAnim.checked

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
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
        }

        QQC2.SpinBox {
            id: maxSectionCount

            Kirigami.FormData.label: vertical ? i18nc("@label:spinbox", "Maximum columns:") : i18nc("@label:spinbox", "Maximum rows:")

            from: 1
            visible: false
        }

        CustomGroupBox {
            Layout.fillWidth: true

            title: "Appearance"

            ColumnLayout {
                Layout.fillWidth: true

                QQC2.CheckBox {
                    id: showLauncherNames

                    text: i18n("Show launcher names")
                }

                QQC2.CheckBox {
                    id: enablePopup

                    text: i18n("Enable popup")
                    enabled: false
                }

                QQC2.CheckBox {
                    id: extraPadding

                    text: i18n("Extra padding")
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text { text: i18n("Extra padding size (px)") }
                    QQC2.SpinBox { id: extraPaddingSize; from: 0 }
                }
            }
        }

        CustomGroupBox {
            Layout.fillWidth: true

            title: "Tweaks"

            QQC2.CheckBox {
                id: hoverFadeAnim

                text: i18n("Enable hover fade animation")
            }
        }
    }
}
