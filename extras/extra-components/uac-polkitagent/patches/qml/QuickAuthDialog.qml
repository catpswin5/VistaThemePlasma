/*  This file is part of the KDE project
    SPDX-FileCopyrightText: 2021 Aleix Pol Gonzalez <aleixpol@kde.org>
    SPDX-FileCopyrightText: 2023 Devin Lin <devin@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtMultimedia

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.sounds
import org.kde.polkitkde

import org.kde.plasma.plasma5support as Plasma5Support

Kirigami.AbstractApplicationWindow {
    id: root
    title: i18n("Authentication Required")

    maximumHeight: intendedWindowHeight
    minimumHeight: intendedWindowHeight
    minimumWidth: intendedWindowWidth
    maximumWidth: intendedWindowWidth
    width: intendedWindowWidth
    height: intendedWindowHeight

    property alias password: passwordField.text
    property alias identitiesModel: identitiesCombo.model
    property alias identitiesCurrentIndex: identitiesCombo.currentIndex
    property alias selectedIdentity: identitiesCombo.currentValue

    // passed in by QuickAuthDialog.cpp
    property string mainText
    property string subtitle
    property string descriptionString
    property string descriptionActionId
    property string descriptionVendorName
    property string descriptionVendorUrl
    property string descriptionIcon

    property bool sevenLike: false

    signal accept()
    signal reject()
    signal userSelected()

    onSelectedIdentityChanged: userSelected()

    onAccept: {
        // disable password field while password is being checked
        if (passwordField.text !== "") {
            passwordField.enabled = false;
        }
    }

    color: "white"

    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: root.reject()
    }

    function rejectPassword() {
        passwordField.clear()
        passwordField.enabled = true
        passwordField.focus = true
    }

    function authenticationFailure() {
        authenticationError.visible = true;
        rejectPassword()
    }

    function request() {
        if (passwordField.text !== "") {
            rejectPassword()
        }
    }

    readonly property real intendedWindowWidth: (Kirigami.Units.largeSpacing * 57) - 5
    readonly property real intendedWindowHeight: mainContent.implicitHeight + bottomControls.height + (Kirigami.Units.largeSpacing * 2)
    onIntendedWindowHeightChanged: {
        minimumHeight = intendedWindowHeight;
        height = intendedWindowHeight;
        maximumHeight = intendedWindowHeight
    }

    onActiveChanged: {
        if (active) {
            // immediately focus on password field when window is focused
            passwordField.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            // immediately focus on password field on load
            passwordField.forceActiveFocus();
        } else {
            // reject on close
            root.reject();
        }
    }

    // select user combobox, we are displaying its popup
    property QQC2.ComboBox selectIdentityCombobox: QQC2.ComboBox {
        id: identitiesCombo
        visible: false
        textRole: "display"
        valueRole: "userRole"
        enabled: count > 0
        model: IdentitiesModel {
            id: identitiesModel
        }
    }

    // best code fr (thanks wacky ideal)
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var stdout = data["stdout"]
            exited(stdout)
            disconnectSource(sourceName) // cmd finished
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string stdout)
    }
    Connections {
        target: executable
        function onExited(stdout) {
            soundsModel.theme = stdout.trim() ? stdout.trim() : "ocean";
            for(var i = 0; i < soundsModel.rowCount(); i++) {
                var str = soundsModel.initialSourceUrl(i);
                if(str.includes("authentication-required") && !str.endsWith(".license")) {
                    authSound.setSource(str);
                    authSound.play();
                } else {
                    authSound.setSource("qrc:/qml/res/fallback.wav");
                    authSound.play();
                }
            }
        }
    }
    SoundsModel {
        id: soundsModel
    }
    MediaPlayer {
        id: authSound
        audioOutput: AudioOutput {  }
    }

    Column {
        id: mainContent

        anchors.fill: parent

        spacing: 16

        Rectangle {
            id: header

            anchors {
                right: parent.right
                left: parent.left
            }

            implicitHeight: 52

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 1.0; color: "#137798"}
                GradientStop { position: 0.0; color: "#073f6e"}
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing

                anchors {
                    fill: parent
                    leftMargin: Kirigami.Units.largeSpacing
                    rightMargin: Kirigami.Units.largeSpacing
                }

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignVCenter

                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium

                    source: "dialog-password"
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    level: 2
                    text: root.mainText
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: "white"
                }
            }
        }

        ColumnLayout {
            id: contentItem

            anchors {
                right: parent.right
                left: parent.left
                margins: 20
            }

            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                id: content

                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 50

                spacing: Kirigami.Units.largeSpacing * 3

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium

                    Layout.alignment: Qt.AlignTop

                    source: descriptionIcon == "" ? "application-default-icon" : descriptionIcon
                }
                ColumnLayout {
                    spacing: 0
                    Row {
                        spacing: 4
                        QQC2.Label {
                            text: i18n("ID:")
                            visible: root.sevenLike
                        }
                        QQC2.Label {
                            text: descriptionActionId
                        }
                    }
                    Row {
                        spacing: 4
                        QQC2.Label {
                            text: i18n("Vendor:")
                            visible: root.sevenLike
                        }
                        QQC2.Label {
                            text: descriptionVendorName
                            font.bold: true

                            Kirigami.UrlButton {
                                anchors {
                                    left: parent.right
                                    leftMargin: -Kirigami.Units.mediumSpacing
                                }
                                text: " "
                                url: descriptionVendorUrl
                                font.underline: false
                            }
                        }
                    }
                    Row {
                        spacing: 4
                        QQC2.Label {
                            text: i18n("Action:")
                            visible: root.sevenLike
                        }
                        QQC2.Label {
                            text: descriptionString
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }

            Rectangle {
                Layout.fillWidth: true
                Layout.rightMargin: -4
                Layout.leftMargin: -4

                implicitHeight: 1

                color: "#dfdfdf"
            }

            QQC2.Label { text: i18n("To continue, type an administrator password, and then click OK.") }

            Column {
                id: authenticationPrompt

                Layout.fillWidth: true

                spacing: Kirigami.Units.largeSpacing

                KSvg.FrameSvgItem {
                    id: user

                    anchors {
                        right: parent.right
                        left: parent.left
                    }

                    height: 76

                    imagePath: Qt.resolvedUrl("qrc:/qml/res/viewitem.svg")
                    prefix: ""//"selected" TODO: implement this properly in the future

                    Row {
                        anchors.fill: parent

                        Image {
                            source: "qrc:/qml/res/frame.png"

                            Image {
                                anchors.centerIn: parent

                                width: 48
                                height: 48

                                source: "file://" + identitiesModel.iconForIndex(identitiesCombo.currentIndex)

                                z: -1
                            }
                        }

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 2

                            spacing: 9

                            RowLayout {
                                Kirigami.Heading {
                                    level: 2
                                    text: identitiesCombo.currentText
                                }
                                Kirigami.LinkButton {
                                    Layout.alignment: Qt.AlignVCenter
                                    id: switchButton
                                    text: i18n("Switch…")
                                    visible: identitiesCombo.count > 1
                                    onClicked: {
                                        identitiesCombo.popup.parent = switchButton;
                                        identitiesCombo.popup.open();
                                    }
                                }
                            }

                            Kirigami.PasswordField {
                                id: passwordField
                                Layout.alignment: Qt.AlignLeft
                                onAccepted: root.accept()
                                placeholderText: i18n("Password…")
                            }
                        }
                    }
                }

                Row {
                    id: authenticationError
                    visible: false
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: "dialog-error"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("Authentication failure, please try again.")
                    }
                }
            }
        }
    }

    Rectangle {
        id: bottomControls

        anchors {
            bottom: parent.bottom
            right: parent.right
            left: parent.left
            margins: -1
        }

        height: 43

        border.width: 1
        border.color: "#dfdfdf"
        color: "#f0f0f0"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            anchors.rightMargin: 12

            spacing: 8

            Item { Layout.fillWidth: true }

            QQC2.Button {
                implicitWidth: 73
                implicitHeight: 23
                text: i18n("OK")
                icon.name: "dialog-ok"
                onClicked: root.accept()
            }
            QQC2.Button {
                implicitWidth: 73
                implicitHeight: 23
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onClicked: root.reject()
            }
        }
    }
    Component.onCompleted: executable.exec("kreadconfig6 --file ~/.config/kdeglobals --group Sounds --key Theme");
}
