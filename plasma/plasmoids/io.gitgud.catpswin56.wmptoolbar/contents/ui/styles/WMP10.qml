import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid

Item {
    id: wmp10

    property alias bgRightMa: bgRightMa

    Image {
        id: bg
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 1
        }

        height: 25

        source: "png/wmp10/background.png"
    }

    Image {
        id: bgRight

        anchors.right: bg.right
        anchors.top: bg.top

        width: 15
        height: 25

        visible: true

        source: bgRightMa.containsMouse ? (bgRightMa.containsPress ? "png/wmp10/rightPressed.png" : "png/wmp10/rightToggled.png") : (popup.visible ? "png/wmp10/rightPressed.png" : "png/wmp10/rightNormal.png")

        MouseArea {
            id: bgRightMa

            anchors.fill: parent

            preventStealing: true
            propagateComposedEvents: true
            hoverEnabled: true

            onClicked: {
                popup.isToolTip = false; // Just in case.
                popup.opacity = !popup.opacity;
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter

        width: 16
        height: 16

        Image {
            anchors.fill: parent

            source: Plasmoid.configuration.toolbarIcon == 3 ? Plasmoid.configuration.customIcon : mediaController.albumArt

            visible: Plasmoid.configuration.toolbarIcon > 1
        }

        Kirigami.Icon {
            anchors.fill: parent

            source: mediaController.appIcon

            visible: Plasmoid.configuration.toolbarIcon == 1
        }

        MouseArea {
            anchors.fill: parent

            onClicked: contextMenu.openRelative();
        }
    }

    RowLayout {
        anchors.fill: bg
        anchors.leftMargin: 5
        anchors.verticalCenter: bg.verticalCenter

        spacing: 0

        Item {
            id: mediaControls
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20

            Image {
                id: idkButton

                property bool pressed: false

                source: idkMa.containsMouse ? (pressed ? "png/wmp10/idk-pressed.png" : "png/wmp10/idk-hover.png") : "png/wmp10/idk.png"

                MouseArea {
                    id: idkMa

                    anchors.fill: parent

                    hoverEnabled: true

                    onPressed: {
                        parent.pressed = true
                    }

                    onReleased: {
                        parent.pressed = false
                    }
                }
            }

            Image {
                id: playButton

                anchors.left: idkButton.right
                anchors.leftMargin: mediaController.isPlaying ? 1 : 0 // too lazy to fix the png

                source: {
                    var buttonState = playMa.containsMouse ? (playMa.containsPress ? "-pressed" : "-hover") : ""; // it rejects if() statements for some reason
                    var playingState = mediaController.isPlaying ? "pause" : "play"

                    return "png/wmp10/"+playingState+buttonState+".png"
                }

                MouseArea {
                    id: playMa

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: mediaController.togglePlaying()
                }
            }

            Image {
                id: stopButton

                property bool pressed: false

                anchors.left: playButton.right
                anchors.leftMargin: mediaController.isPlaying ? 0 : 1

                source: stopMa.containsMouse ? (stopMa.containsPress ? "png/wmp10/stop-pressed.png" : "png/wmp10/stop-hover.png") : "png/wmp10/stop.png"

                MouseArea {
                    id: stopMa

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: mediaController.stop()
                }
            }

            Image {
                id: backwardButton

                property bool pressed: false

                anchors.left: stopButton.right

                source: backwardMa.containsMouse ? (backwardMa.containsPress ? "png/wmp10/backward-pressed.png" : "png/wmp10/backward-hover.png") : "png/wmp10/backward.png"

                MouseArea {
                    id: backwardMa

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: mediaController.previous()
                }
            }
            Image {
                id: forwardButton

                property bool pressed: false

                anchors.left: backwardButton.right

                source: forwardMa.containsMouse ? (forwardMa.containsPress ? "png/wmp10/forward-pressed.png" : "png/wmp10/forward-hover.png") : "png/wmp10/forward.png"

                MouseArea {
                    id: forwardMa

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: mediaController.next()
                }
            }

            Image {
                id: volumeButton

                property bool pressed: false

                anchors.left: forwardButton.right
                anchors.leftMargin: 3

                source: volumeMa.containsMouse ? (volumeMa.containsPress ? "png/wmp10/volume-pressed.png" : "png/wmp10/volume-hover.png") : "png/wmp10/volume.png"

                MouseArea {
                    id: volumeMa

                    anchors.fill: parent

                    hoverEnabled: true
                }
            }

            Image {
                id: volumeSliderButton

                property bool pressed: false

                anchors.left: volumeButton.right

                source: volumeSMa.containsMouse ? (volumeSMa.containsPress ? "png/wmp10/volumeslider-pressed.png" : "png/wmp10/volumeslider-hover.png") : "png/wmp10/volumeslider.png"

                MouseArea {
                    id: volumeSMa

                    anchors.fill: parent

                    hoverEnabled: true
                }
            }
        }
    }
}
