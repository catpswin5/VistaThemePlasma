/*
 *  SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    readonly property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical || (plasmoid.formFactor == PlasmaCore.Types.Planar && plasmoid.height > plasmoid.width)

    property alias cfg_maxSectionCount: maxSectionCount.value
    property alias cfg_showLauncherNames: showLauncherNames.checked
    property alias cfg_enablePopup: enablePopup.checked
    property alias cfg_extraPadding: extraPadding.checked
    property alias cfg_extraPaddingSize: extraPaddingSize.value

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: maxSectionCount

            Kirigami.FormData.label: vertical ? i18nc("@label:spinbox", "Maximum columns:") : i18nc("@label:spinbox", "Maximum rows:")

            from: 1
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showLauncherNames

            Kirigami.FormData.label: i18nc("@title:group", "Appearance:")

            text: i18nc("@option:check", "Show launcher names")
        }

        QQC2.CheckBox {
            id: enablePopup
            text: i18nc("@option:check", "Enable popup")
            enabled: false
        }

        QQC2.CheckBox {
            id: extraPadding
            text: i18nc("@option:check", "Extra padding")
        }

        QQC2.SpinBox {
            id: extraPaddingSize

            Kirigami.FormData.label: i18n("Size of the extra padding: ")

            from: 0
        }


        Item {
            Kirigami.FormData.isSection: true
        }
    }
}
