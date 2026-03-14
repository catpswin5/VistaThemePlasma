/*
    SPDX-FileCopyrightText: 2021 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick

import org.kde.plasma.workspace.keyboardlayout as Keyboards

Item {
    id: inputPanel

    readonly property bool active: Keyboards.KWinVirtualKeyboard.visible
    property bool activated: false

    x: Qt.inputMethod.keyboardRectangle.x
    y: Qt.inputMethod.keyboardRectangle.y

    width: Qt.inputMethod.keyboardRectangle.width
    height: Qt.inputMethod.keyboardRectangle.height

    visible: Keyboards.KWinVirtualKeyboard.visible

    onActivatedChanged: if (activated) {
        Keyboards.KWinVirtualKeyboard.enabled = true
    }
}
