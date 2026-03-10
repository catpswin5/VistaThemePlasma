import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    property alias volumePopup: volumePopup

    Image {
        id: bg

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 1
        }

        height: 25

        source: "png/background.png"

        Rectangle {
            anchors.fill: parent

            color: "black"

            visible: root.useBasic
            z: -1
        }
    }

    Column {
        anchors {
            right: bg.right
            rightMargin: -Kirigami.Units.smallSpacing/2
            top: bg.top
        }

        width: 15
        height: 25

        Image {
            readonly property string state: {
                if(rightTopMa.containsPress || popup.visible) return "-pressed";
                if(rightTopMa.containsMouse) return "-hover";
                return "";
            }

            width: 13
            height: 12

            source: "png/bgRight" + state + ".png"
            sourceClipRect: Qt.rect(2, 0, 13, 12)

            visible: true

            MouseArea {
                id: rightTopMa

                anchors.fill: parent

                preventStealing: true
                propagateComposedEvents: true
                hoverEnabled: true

                onClicked: popup.visible = !popup.visible;
            }
        }
        Image {
            readonly property string state: {
                if(rightBottomMa.containsPress) return "-pressed";
                if(rightBottomMa.containsMouse) return "-hover";
                return "";
            }

            width: 13
            height: 13

            source: "png/bgRight" + state + ".png"
            sourceClipRect: Qt.rect(2, 13, 13, 13)

            visible: true

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
        anchors {
            left: parent.left
            leftMargin: 6

            verticalCenter: parent.verticalCenter
            verticalCenterOffset: 1
        }

        width: 11
        height: 11

        Image {
            anchors.fill: parent
            source: "png/icon.png"
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
            left: parent.left
            leftMargin: 31

            verticalCenter: bg.verticalCenter
        }

        spacing: 0

        Image {
            property string buttonState: {
                if(!mediaController.canStop) return "-disabled";
                if(stopMa.containsPress) return "-pressed";
                if(stopMa.containsMouse) return "-hover";
                return "";
            }

            Layout.preferredWidth: 17
            Layout.preferredHeight: 17

            source: "png/controls" + buttonState + ".png"
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
            Layout.topMargin: -(Kirigami.Units.smallSpacing / 4)
            Layout.rightMargin: Kirigami.Units.smallSpacing - Kirigami.Units.smallSpacing / 4

            spacing: -Kirigami.Units.smallSpacing/2

            Image {
                property string buttonState: {
                    if(!mediaController.canGoPrevious) return "-disabled";
                    if(prevMa.containsPress) return "-pressed";
                    if(prevMa.containsMouse) return "-hover";
                    return "";
                }

                Layout.preferredWidth: 27
                Layout.preferredHeight: 17

                source: "png/controls" + buttonState + ".png"
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


                property string buttonState: {
                    if(!mediaController.canPlay && !mediaController.canPause) return "-disabled";
                    if(playMa.containsPress) return "-pressed";
                    if(playMa.containsMouse) return "-hover";
                    return "";
                }

                Layout.preferredWidth: 24
                Layout.preferredHeight: 25

                source: "png/controls" + buttonState + ".png"
                sourceClipRect: Qt.rect(73, 0, 24, 25)

                Image {
                    property string buttonState: {
                        if(playMa.containsPress) return "-pressed";
                        if(playMa.containsMouse) return "-hover";
                        return "";
                    }

                    anchors.centerIn: parent

                    source: "png/pause" + buttonState + ".png"

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
                property string buttonState: {
                    if(!mediaController.canGoNext) return "-disabled";
                    if(nextMa.containsPress) return "-pressed";
                    if(nextMa.containsMouse) return "-hover";
                    return "";
                }

                Layout.preferredWidth: 27
                Layout.preferredHeight: 17

                source: "png/controls" + buttonState + ".png"
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
                id: volBtn

                readonly property bool muted: mediaController.mpris2Model.currentPlayer.volume == 0.0

                property double prevVolume: 0.3
                property string buttonState: {
                    if(volMa.containsPress || muted) return "-pressed";
                    else if(volMa.containsMouse) return "-hover";
                    else return "";
                }

                Layout.preferredWidth: 15
                Layout.preferredHeight: 17

                source: "png/controls" + buttonState + ".png"
                sourceClipRect: Qt.rect(122, 4, 15, 17)

                MouseArea {
                    id: volMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                    onClicked: {
                        if(!volBtn.muted) {
                            volBtn.prevVolume = mediaController.mpris2Model.currentPlayer.volume;
                            mediaController.mpris2Model.currentPlayer.volume = 0.0;
                        } else {
                            mediaController.mpris2Model.currentPlayer.volume = volBtn.prevVolume;
                        }
                    }
                }
            }
            Image {
                id: volumePopupBtn

                property string buttonState: {
                    if(volPopupMa.containsPress) return "-pressed";
                    if(volPopupMa.containsMouse) return "-hover";
                    return "";
                }

                Layout.preferredWidth: 11
                Layout.preferredHeight: 17

                source: "png/controls" + buttonState + ".png"
                sourceClipRect: Qt.rect(137, 4, 11, 17)

                MouseArea {
                    id: volPopupMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                    onClicked: volumePopup.visible = !volumePopup.visible;
                }

                Image {
                    id: volumePopup

                    anchors.verticalCenter: parent.verticalCenter

                    x: -width

                    source: "png/volslider-empty.png"

                    visible: false
                    onVisibleChanged: {
                        if(visible) {
                            toolTip.display = false;
                        } else if(!visible && hoverHandler.hovered) {
                            toolTipTimer.restart();
                        }
                    }

                    QQC2.Slider {
                        id: volumeSlider

                        anchors.fill: parent
                        anchors.rightMargin: 8
                        anchors.leftMargin: 8

                        orientation: Qt.Horizontal
                        value: mediaController.mpris2Model.currentPlayer.volume
                        to: 1.0

                        background: Image {
                            width: volumeSlider.value * implicitWidth
                            height: implicitHeight

                            source: "png/volslider-bar.png"
                        }

                        handle: Image {
                            property string state: {
                                if(hoverHand.hovered) return "-hover";
                                else return "-normal";
                            }

                            x: volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2

                            source: "png/volslider-handle" + state + ".png"

                            // can't use mousearea nor taphandler or we lose the sliding ability
                            HoverHandler { id: hoverHand }
                        }

                        onValueChanged: {
                            // only change when it actually changes
                            if(value > mediaController.mpris2Model.currentPlayer.volume)
                                mediaController.mpris2Model.currentPlayer.volume = value;
                            if(value < mediaController.mpris2Model.currentPlayer.volume)
                                mediaController.mpris2Model.currentPlayer.volume = value;
                        }
                    }
                }
            }
        }
    }
}
