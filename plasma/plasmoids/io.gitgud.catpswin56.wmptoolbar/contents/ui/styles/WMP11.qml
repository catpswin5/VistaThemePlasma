import QtQuick
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: wmp11

    property alias rightTopMa: rightTopMa

    Image {
        id: bg

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 1
        }

        height: 25

        source: "png/wmp11/background.png"

        Rectangle {
            z: -1

            anchors.fill: parent

            color: "black"

            visible: root.wmp11Basic
        }
    }

    Column {
        anchors.right: bg.right
        anchors.rightMargin: -Kirigami.Units.smallSpacing/2
        anchors.top: bg.top

        width: 15
        height: 25

        Image {
            visible: true

            width: 13
            height: 12

            source: rightTopMa.containsMouse ? (rightTopMa.containsPress ? "png/wmp11/bgRight-pressed.png" : "png/wmp11/bgRight-hover.png") : (popup.visible && !popup.isToolTip? "png/wmp11/bgRight-pressed.png" : "png/wmp11/bgRight.png")
            sourceClipRect: Qt.rect(2, 0, 13, 12)

            MouseArea {
                id: rightTopMa

                anchors.fill: parent

                preventStealing: true
                propagateComposedEvents: true
                hoverEnabled: true

                onClicked: {
                    hoverHandler.enabled = false;
                    tooltipTimer.stop();
                    if(popup.isToolTip) {
                        popup.isToolTip = false;
                        popup.opacity = 1;
                    }
                    else {
                        if(!popup.opacity) popup.opacity = 1;
                        else if(!popup.isToolTip) {
                            hoverHandler.enabled = root.toolbarStyle == "wmp11";
                            popup.opacity = 0;
                        }
                    }
                }
            }
        }
        Image {
            visible: true

            width: 13
            height: 13

            source: rightBottomMa.containsMouse ? (rightBottomMa.containsPress ? "png/wmp11/bgRight-pressed.png" : "png/wmp11/bgRight-hover.png") : "png/wmp11/bgRight.png"
            sourceClipRect: Qt.rect(2, 13, 13, 13)

            MouseArea {
                id: rightBottomMa

                anchors.fill: parent

                preventStealing: true
                propagateComposedEvents: true
                hoverEnabled: true
                onReleased: mediaController.raise()
            }
        }
    }

    Item {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        width: 11
        height: 11

        Image {
            anchors.fill: parent

            source: "png/wmp11/icon.png"

            visible: Plasmoid.configuration.toolbarIcon == 0 || (!root.multimediaOpen && Plasmoid.configuration.toolbarIcon < 3)
        }

        Image {
            anchors.fill: parent

            source: Plasmoid.configuration.toolbarIcon == 3 ? Plasmoid.configuration.customIcon : mediaController.albumArt

            visible: Plasmoid.configuration.toolbarIcon > 1 && source != ""
        }

        Kirigami.Icon {
            anchors.fill: parent

            source: mediaController.appIcon

            visible: Plasmoid.configuration.toolbarIcon == 1 && source != ""
        }

        MouseArea {
            anchors.fill: parent

            onClicked: contextMenu.openRelative();
        }
    }

    RowLayout {
        anchors {
            verticalCenter: bg.verticalCenter
            left: parent.left
            leftMargin: 31
        }

        spacing: 0

        Image {
            property string buttonState: !mediaController.canStop ? "-disabled.png": (stopMa.containsMouse ?
            (stopMa.containsPress ?
            "-pressed.png" : "-hover.png")
            : ".png")

            Layout.preferredWidth: 17
            Layout.preferredHeight: 17

            source: "png/wmp11/controls" + buttonState
            sourceClipRect: Qt.rect(31, 5, 17, 17)

            MouseArea {
                id: stopMa

                anchors.fill: parent

                preventStealing: true
                propagateComposedEvents: true
                hoverEnabled: true
                onClicked: mediaController.stop()
            }
        }

        RowLayout {
            Layout.topMargin: -Kirigami.Units.smallSpacing/4
            Layout.rightMargin: Kirigami.Units.smallSpacing - Kirigami.Units.smallSpacing/4

            spacing: -Kirigami.Units.smallSpacing/2

            Image {
                property string buttonState: !mediaController.canGoPrevious ? "-disabled.png": (prevMa.containsMouse ?
                (prevMa.containsPress ?
                "-pressed.png" : "-hover.png")
                : ".png")

                Layout.preferredWidth: 27
                Layout.preferredHeight: 17

                source: "png/wmp11/controls" + buttonState
                sourceClipRect: Qt.rect(48, 4, 27, 17)

                MouseArea {
                    id: prevMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                    onClicked: mediaController.previous()
                }
            }
            Image {
                property string buttonState: !mediaController.canPlay && !mediaController.canPause ? "-disabled.png": (playMa.containsMouse ?
                (playMa.containsPress ?
                "-pressed.png" : "-hover.png")
                : ".png")

                Layout.preferredWidth: 24
                Layout.preferredHeight: 25

                source: "png/wmp11/controls" + buttonState
                sourceClipRect: Qt.rect(73, 0, 24, 25)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: 24
                        height: 25

                        radius: 16
                    }
                }

                Image {
                    id: wmp11Pause

                    anchors.centerIn: parent

                    source: "png/wmp11/pause" + parent.buttonState

                    z: 1
                    visible: mediaController.isPlaying && mediaController.canPause
                }

                MouseArea {
                    id: playMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                    onClicked: mediaController.togglePlaying()
                }
            }
            Image {
                Layout.preferredWidth: 27
                Layout.preferredHeight: 17

                property string buttonState: !mediaController.canGoNext ? "-disabled.png": (nextMa.containsMouse ?
                (nextMa.containsPress ?
                "-pressed.png" : "-hover.png")
                : ".png")

                source: "png/wmp11/controls" + buttonState
                sourceClipRect: Qt.rect(95, 4, 27, 17)

                MouseArea {
                    id: nextMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                    onClicked: mediaController.next()
                }
            }
        }

        RowLayout { // TODO: add functionality for changing volume
            Layout.topMargin: -2
            Layout.leftMargin: -3

            spacing: 1

            Image {
                // property string buttonState: !mediaController.canControl ? "-disabled.png": (wmp11VolMa.containsMouse ?
                //                                                 (wmp11VolMa.containsPress ?
                //                                                 "-pressed.png" : "-hover.png")
                //                                                 : ".png")
                //
                // source: "png/wmp11/controls" + buttonState

                Layout.preferredWidth: 15
                Layout.preferredHeight: 17

                source: "png/wmp11/controls-disabled.png"
                sourceClipRect: Qt.rect(122, 4, 15, 17)

                MouseArea {
                    id: volMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                }
            }
            Image {
                // property string buttonState: !mediaController.canControl ? "-disabled.png": (wmp11VolCustomMa.containsMouse ?
                //                                                 (wmp11VolCustomMa.containsPress ?
                //                                                 "-pressed.png" : "-hover.png")
                //                                                 : ".png")
                //
                // source: "png/wmp11/controls" + buttonState

                Layout.preferredWidth: 11
                Layout.preferredHeight: 17

                source: "png/wmp11/controls-disabled.png"
                sourceClipRect: Qt.rect(137, 4, 11, 17)

                MouseArea {
                    id: volPopupMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                }
            }
        }
    }
}
