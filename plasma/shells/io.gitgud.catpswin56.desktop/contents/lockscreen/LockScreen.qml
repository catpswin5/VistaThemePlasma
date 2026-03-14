/*
 * SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
 * SPDX-FileCopyrightText: 2023 Nate Graham <nate@kde.org>
 * SPDX-FileCopyrightText: 2026 catpswin56 <catpswin5@proton.me>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick

import org.kde.plasma.private.sessions
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

Item {
    id: lockScreen

    property bool locked: false

    signal unlockRequested()

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    SessionManagement { id: sessionManagment }

    Rectangle {
        anchors.fill: parent
        color: "#1D5F7A"
    }

    AuthUI {
        id: authUI

        anchors.fill: parent

        capsLockOn: capsLockState.locked
        switchUserVisible: sessionManagment.canSwitchUser
        onSwitchUserClicked: sessionManagment.switchUser()
    }
}
