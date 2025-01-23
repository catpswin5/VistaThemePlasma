import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.12 as QQC2
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.sessions 2.0

Image {
    id: root

    height: screenGeometry.height
    width: screenGeometry.width

    source: "/usr/share/sddm/themes/sddm-theme-mod/bgtexture.jpg"

    signal logoutRequested()
    signal haltRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal cancelRequested()
    signal lockScreenRequested()

    SessionManagement {
        id: sessMan
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    QQC2.Action {
        onTriggered: root.cancelRequested()
        shortcut: "Escape"
    }

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: mainColumn
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Kirigami.Units.gridUnit*5 // use accurate values idk i just approximated this rq
            spacing: 5

            MouseArea {
                Layout.preferredWidth: 190
                Layout.preferredHeight: 30

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    lockArrow.source = "../images/command-hover.png"
                }
                onExited: {
                    lockArrow.source = "../images/command.png"
                }
                onClicked: {
                    root.lockScreenRequested()
                }

                KSvg.FrameSvgItem {
                    anchors {
                        right: lockcontent.right
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    imagePath: Qt.resolvedUrl("../svgs/command.svg");
                    prefix: parent.containsMouse ? (parent.containsPress ? "pressed" : "hover") : ""
                }
                RowLayout {
                    id: lockcontent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 5

                    Image {
                        id: lockArrow

                        source: "../images/command.png"
                    }
                    QQC2.Label {
                        text: "Lock this computer"
                        color: "white"
                        font.pointSize: 12
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                    }
                    Item {
                        Layout.preferredWidth: 10
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: 190
                Layout.preferredHeight: 30

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    switchArrow.source = "../images/command-hover.png"
                }
                onExited: {
                    switchArrow.source = "../images/command.png"
                }
                onClicked: {
                    sessMan.switchUser()
                    root.cancelRequested()
                }

                KSvg.FrameSvgItem {
                    anchors {
                        right: switchcontent.right
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    imagePath: Qt.resolvedUrl("../svgs/command.svg");
                    prefix: parent.containsMouse ? (parent.containsPress ? "pressed" : "hover") : ""
                }
                RowLayout {
                    id: switchcontent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 5

                    Image {
                        id: switchArrow

                        source: "../images/command.png"
                    }
                    QQC2.Label {
                        color: "white"
                        text: "Switch User"
                        font.pointSize: 12
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                    }
                    Item {
                        Layout.preferredWidth: 10
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: 190
                Layout.preferredHeight: 30

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    logArrow.source = "../images/command-hover.png"
                }
                onExited: {
                    logArrow.source = "../images/command.png"
                }
                onClicked: {
                    root.logoutRequested()
                }

                KSvg.FrameSvgItem {
                    anchors {
                        right: logcontent.right
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    imagePath: Qt.resolvedUrl("../svgs/command.svg");
                    prefix: parent.containsMouse ? (parent.containsPress ? "pressed" : "hover") : ""
                }
                RowLayout {
                    id: logcontent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 5

                    Image {
                        id: logArrow

                        source: "../images/command.png"
                    }
                    QQC2.Label {
                        color: "white"
                        text: "Log off"
                        font.pointSize: 12
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                    }
                    Item {
                        Layout.preferredWidth: 10
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: 190
                Layout.preferredHeight: 30

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    changeArrow.source = "../images/command-hover.png"
                }
                onExited: {
                    changeArrow.source = "../images/command.png"
                }
                onClicked: {
                    executable.exec("systemsettings kcm_users & disown")
                    root.cancelRequested()
                }

                KSvg.FrameSvgItem {
                    anchors {
                        right: changecontent.right
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    imagePath: Qt.resolvedUrl("../svgs/command.svg");
                    prefix: parent.containsMouse ? (parent.containsPress ? "pressed" : "hover") : ""
                }
                RowLayout {
                    id: changecontent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 5

                    Image {
                        id: changeArrow

                        source: "../images/command.png"
                    }
                    QQC2.Label {
                        color: "white"
                        text: "Change a password..."
                        font.pointSize: 12
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                    }
                    Item {
                        Layout.preferredWidth: 10
                    }
                }
            }
            MouseArea {
                Layout.preferredWidth: 190
                Layout.preferredHeight: 30

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    taskmgrArrow.source = "../images/command-hover.png"

                }
                onExited: {
                    taskmgrArrow.source = "../images/command.png"
                }
                onClicked: {
                    executable.exec("ksysguard & disown")
                    root.cancelRequested()
                }

                KSvg.FrameSvgItem {
                    anchors {
                        right: taskmgrcontent.right
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    imagePath: Qt.resolvedUrl("../svgs/command.svg");
                    prefix: parent.containsMouse ? (parent.containsPress ? "pressed" : "hover") : ""
                }
                RowLayout {
                    id: taskmgrcontent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 5

                    Image {
                        id: taskmgrArrow

                        source: "../images/command.png"
                    }
                    QQC2.Label {

                        color: "white"
                        text: "Start Task Manager"
                        font.pointSize: 12
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                    }
                    Item {
                        Layout.preferredWidth: 10
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: 115
                Layout.preferredHeight: 25
                Layout.topMargin: 35
                Layout.alignment: Qt.AlignHCenter

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    cancelBackground.source = "../images/cancel-hover.png"
                }
                onExited: {
                    cancelBackground.source = "../images/cancel.png"
                }
                onClicked: {
                    root.cancelRequested()
                }
                onPressed: {
                    cancelBackground.source = "../images/cancel-pressed.png"
                }
                Image {
                    id: cancelBackground

                    anchors.centerIn: parent
                    source: "../images/cancel.png"

                    QQC2.Label {
                        anchors.centerIn: parent

                        color: "white"
                        text: "Cancel"
                        font.pointSize: 12
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                    }
                }
            }
        }

        RowLayout {
            anchors.rightMargin: 35
            anchors.leftMargin: 35
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: Kirigami.Units.gridUnit*2 // Same goes for here I just used Kirigami Units

            MouseArea {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 25
                Layout.topMargin: 35
                Layout.alignment: Qt.AlignHCenter

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    accessButton.source = "../images/accessButton-hover.png"
                }
                onExited: {
                    accessButton.source = "../images/accessButton.png"
                }
                onClicked: {
                    root.cancelRequested()
                    executable.exec("systemsettings kcm_access")
                }
                onPressed: {
                    accessButton.source = "../images/accessButton-pressed.png"
                }
                Image {
                    id: accessButton

                    width: 38
                    source: "../images/accessButton.png"

                    Image {
                        anchors.centerIn: parent

                        source: "../images/access.png"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
            Item {
                Layout.preferredWidth: 40
            }

            Image {
                Layout.bottomMargin: -33
                Layout.alignment: Qt.AlignRight

                source: "../images/watermark.png"
            }

            Item {
                Layout.fillWidth: true
            }

            MouseArea {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 28
                Layout.bottomMargin: -35
                Layout.rightMargin: -3

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    power.source = "../images/halt-hover.png"
                }
                onExited: {
                    power.source = "../images/halt.png"
                }
                onClicked: {
                    root.haltRequested()
                }
                onPressed: {
                    power.source = "../images/halt-pressed.png"
                }
                Image {
                    id: power

                    Layout.rightMargin: -5

                    source: "../images/halt.png"

                    Image {
                        anchors.centerIn: parent

                        source: "../images/halt-glyph.png"
                    }
                }
            }
            MouseArea {
                Layout.preferredWidth: 33
                Layout.preferredHeight: 28
                Layout.bottomMargin: -35

                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    powerRIGHT.source = "../images/reboot-hover.png"
                }
                onExited: {
                    powerRIGHT.source = "../images/reboot.png"
                }
                onClicked: {
                    root.rebootRequested()
                }
                onPressed: {
                    powerRIGHT.source = "../images/reboot-pressed.png"
                }
                Image {
                    id: powerRIGHT

                    source: "../images/reboot.png"

                    Image {
                        anchors.centerIn: parent

                        source: "../images/reboot-glyph.png"
                    }
                }
            }
        }
    }
}
