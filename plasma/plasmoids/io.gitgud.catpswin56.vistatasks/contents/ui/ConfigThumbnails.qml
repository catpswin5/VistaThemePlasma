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
    property alias cfg_showPreviews: showPreviews.checked
    property alias cfg_extPreviewFunc: extFunctionality.checked

    property alias cfg_showPreviewClose: showPreviewClose.checked
    property alias cfg_windowPeek: windowPeek.checked
    property alias cfg_showPreviewMpris: showPreviewMpris.checked
    property alias cfg_showPreviewMute: showPreviewMute.checked
    property alias cfg_previewGroupEnabled: previewGroupEnabled.checked

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
                color: gbox.enabled ? Kirigami.Theme.backgroundColor : "white"
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

            title: i18n("General")

            ColumnLayout {
                Layout.fillWidth: true

                CheckBox {
                    id: showPreviews
                    text: i18n("Enable window previews")
                }
                CheckBox {
                    id: extFunctionality
                    text: i18n("Enable extended functionality")
                }
            }
        }

        CustomGroupBox {
            Layout.fillWidth: true

            title: i18n("Extended functionality")

            enabled: extFunctionality.checked

            ColumnLayout {
                Layout.fillWidth: true

                CheckBox {
                    id: showPreviewClose
                    text: i18n("Show close button")
                }
                CheckBox {
                    id: windowPeek
                    text: i18n("Enable window peek")
                }
                CheckBox {
                    id: showPreviewMpris
                    text: i18n("Show MPRIS controls")
                }
                CheckBox {
                    id: showPreviewMute
                    text: i18n("Show mute button")
                }
                CheckBox {
                    id: previewGroupEnabled
                    text: i18n("Use grouped previews for grouped tasks")
                }
            }
        }
    }
}

