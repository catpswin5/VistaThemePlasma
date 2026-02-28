/*
    SPDX-FileCopyrightText: 2017 Martin Gräßlin <mgraesslin@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.VirtualKeyboard 2.4

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

InputPanel {
    id: inputPanel

    property bool activated: false

    width: parent.width

    active: activated && Qt.inputMethod.visible

    states: [
        State {
            name: "visible"
            when: inputPanel.active

            PropertyChanges {
                target: inputPanel

                visible: true
            }
        },
        State {
            name: "hidden"
            when: !inputPanel.active

            PropertyChanges {
                target: inputPanel

                visible: false
            }
        }
    ]

}
