import QtQuick
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mediacontroller 1.0
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    Layout.preferredWidth: hideToolbar ? 0 : 170
    Layout.maximumHeight: 25

    opacity: hideToolbar ? 0 : 1

    readonly property string track: mpris2Model.currentPlayer?.track ?? ""
    readonly property string artist: mpris2Model.currentPlayer?.artist ?? ""
    readonly property string album: mpris2Model.currentPlayer?.album ?? ""
    readonly property string albumArt: mpris2Model.currentPlayer?.artUrl ?? ""
    readonly property string identity: mpris2Model.currentPlayer?.identity ?? ""
    readonly property string appIcon: mpris2Model.currentPlayer?.iconName ?? ""
    readonly property bool canControl: mpris2Model.currentPlayer?.canControl ?? false
    readonly property bool canGoPrevious: mpris2Model.currentPlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: mpris2Model.currentPlayer?.canGoNext ?? false
    readonly property bool canPlay: mpris2Model.currentPlayer?.canPlay ?? false
    readonly property bool canPause: mpris2Model.currentPlayer?.canPause ?? false
    readonly property bool canStop: mpris2Model.currentPlayer?.canStop ?? false
    readonly property int playbackStatus: mpris2Model.currentPlayer?.playbackStatus ?? 0
    readonly property bool isPlaying: root.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool canRaise: mpris2Model.currentPlayer?.canRaise ?? false
    readonly property bool canQuit: mpris2Model.currentPlayer?.canQuit ?? false
    readonly property int shuffle: mpris2Model.currentPlayer?.shuffle ?? 0
    readonly property int loopStatus: mpris2Model.currentPlayer?.loopStatus ?? 0

    readonly property bool multimediaOpen: identity != ""
    readonly property bool hideToolbar: !multimediaOpen && Plasmoid.configuration.hideToolbar
    readonly property string toolbarStyle: {
        if(Plasmoid.configuration.toolbarStyle == 0) return "wmp10"
            if(Plasmoid.configuration.toolbarStyle == 1) return "wmp11"
    }
    readonly property bool wmp11Basic: Plasmoid.configuration.wmp11Basic

    function previous() {
        mpris2Model.currentPlayer.Previous();
    }
    function next() {
        mpris2Model.currentPlayer.Next();
    }
    function play() {
        mpris2Model.currentPlayer.Play();
    }
    function pause() {
        mpris2Model.currentPlayer.Pause();
    }
    function togglePlaying() {
        if (root.isPlaying) {
            mpris2Model.currentPlayer.Pause();
        } else {
            mpris2Model.currentPlayer.Play();
        }
    }
    function stop() {
        mpris2Model.currentPlayer.Stop();
    }
    function quit() {
        mpris2Model.currentPlayer.Quit();
    }
    function raise() {
        mpris2Model.currentPlayer.Raise();
    }

    Mpris.Mpris2Model {
        id: mpris2Model
    }

    Item {
        id: wmp10

        anchors.fill: parent

        visible: parent.toolbarStyle == "wmp10"

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

            source: bgRightMa.containsMouse ? (bgRightMa.containsPress ? "png/wmp10/rightPressed.png" : "png/wmp10/rightToggled.png") : (popup.showPopup ? "png/wmp10/rightPressed.png" : "png/wmp10/rightNormal.png")

            MouseArea { // does not send clicked signals for some reason only qt knows why
                id: bgRightMa

                anchors.fill: parent

                preventStealing: true
                propagateComposedEvents: true
                hoverEnabled: true

                onReleased: {
                    parent.showPopup == true
                }
            }
        }

        Image {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter

            width: 16
            height: 16

            visible: Plasmoid.configuration.toolbarIcon > 1

            source: Plasmoid.configuration.toolbarIcon == 3 ? Plasmoid.configuration.customIcon : root.albumArt
        }
        Kirigami.Icon {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter

            width: 16
            height: 16

            visible: Plasmoid.configuration.toolbarIcon == 1

            source: root.appIcon
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
                    anchors.leftMargin: root.isPlaying ? 1 : 0 // too lazy to fix the png

                    source: {
                        var buttonState = playMa.containsMouse ? (playMa.containsPress ? "-pressed" : "-hover") : ""; // it rejects if() statements for some reason
                        var playingState = root.isPlaying ? "pause" : "play"

                        return "png/wmp10/"+playingState+buttonState+".png"
                    }

                    MouseArea {
                        id: playMa

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: root.togglePlaying()
                    }
                }

                Image {
                    id: stopButton

                    property bool pressed: false

                    anchors.left: playButton.right
                    anchors.leftMargin: root.isPlaying ? 0 : 1

                    source: stopMa.containsMouse ? (stopMa.containsPress ? "png/wmp10/stop-pressed.png" : "png/wmp10/stop-hover.png") : "png/wmp10/stop.png"

                    MouseArea {
                        id: stopMa

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: root.stop()
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

                        onClicked: root.previous()
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

                        onClicked: root.next()
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
    Item {
        id: wmp11

        anchors.fill: parent

        visible: parent.toolbarStyle == "wmp11"

        Image {
            id: wmp11bg
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
            id: wmp11Right
            anchors.right: wmp11bg.right
            anchors.rightMargin: -Kirigami.Units.smallSpacing/2
            anchors.top: wmp11bg.top

            width: 15
            height: 25

            Image {
                id: wmp11RightTop

                visible: true

                width: 13
                height: 12

                source: wmp11RightTopMa.containsMouse ? (wmp11RightTopMa.containsPress ? "png/wmp11/bgRight-pressed.png" : "png/wmp11/bgRight-hover.png") : (popup.showPopup ? "png/wmp11/bgRight-pressed.png" : "png/wmp11/bgRight.png")

                sourceClipRect: Qt.rect(2, 0, 13, 12)

                MouseArea { // does not send clicked signals for some reason only qt knows why
                    id: wmp11RightTopMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true
                }
            }
            Image {
                id: wmp11RightBottom

                visible: true

                width: 13
                height: 13

                source: wmp11RightBottomMa.containsMouse ? (wmp11RightBottomMa.containsPress ? "png/wmp11/bgRight-pressed.png" : "png/wmp11/bgRight-hover.png") : "png/wmp11/bgRight.png"

                sourceClipRect: Qt.rect(2, 13, 13, 13)

                MouseArea { // does not send clicked signals for some reason only qt knows why
                    id: wmp11RightBottomMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true

                    onReleased: root.raise()
                }
            }
        }

        Image {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            width: 12
            height: 12

            visible: Plasmoid.configuration.toolbarIcon > 1

            source: Plasmoid.configuration.toolbarIcon == 3 ? Plasmoid.configuration.customIcon : root.albumArt
        }
        Kirigami.Icon {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            width: 12
            height: 12

            visible: Plasmoid.configuration.toolbarIcon == 1

            source: root.appIcon
        }
        RowLayout {
            id: wmp11Controls

            anchors {
                verticalCenter: wmp11bg.verticalCenter
                left: parent.left
                leftMargin: 31
            }

            spacing: 0

            Image {
                id: wmp11Stop

                Layout.preferredWidth: 17
                Layout.preferredHeight: 17

                property string buttonState: !root.canStop ? "-disabled.png": (wmp11StopMa.containsMouse ?
                                                                (wmp11StopMa.containsPress ?
                                                                "-pressed.png" : "-hover.png")
                                                                : ".png")

                source: "png/wmp11/controls" + buttonState
                sourceClipRect: Qt.rect(31, 5, 17, 17)

                MouseArea {
                    id: wmp11StopMa

                    anchors.fill: parent

                    preventStealing: true
                    propagateComposedEvents: true
                    hoverEnabled: true

                    onClicked: root.stop()
                }
            }

            RowLayout {
                Layout.topMargin: -Kirigami.Units.smallSpacing/4
                Layout.rightMargin: Kirigami.Units.smallSpacing - Kirigami.Units.smallSpacing/4

                spacing: -Kirigami.Units.smallSpacing/2

                Image {
                    id: wmp11Prev

                    Layout.preferredWidth: 27
                    Layout.preferredHeight: 17

                    property string buttonState: !root.canGoPrevious ? "-disabled.png": (wmp11PrevMa.containsMouse ?
                                                                    (wmp11PrevMa.containsPress ?
                                                                    "-pressed.png" : "-hover.png")
                                                                    : ".png")

                    source: "png/wmp11/controls" + buttonState
                    sourceClipRect: Qt.rect(48, 4, 27, 17)

                    MouseArea {
                        id: wmp11PrevMa

                        anchors.fill: parent

                        preventStealing: true
                        propagateComposedEvents: true
                        hoverEnabled: true

                        onClicked: root.previous()
                    }
                }
                Image {
                    id: wmp11Play

                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 25

                    property string buttonState: !root.canPlay && !root.canPause ? "-disabled.png": (wmp11PlayMa.containsMouse ?
                                                                                    (wmp11PlayMa.containsPress ?
                                                                                    "-pressed.png" : "-hover.png")
                                                                                    : ".png")

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

                        z: 1

                        anchors.centerIn: parent

                        source: "png/wmp11/pause" + parent.buttonState

                        visible: root.isPlaying && root.canPause
                    }

                    MouseArea {
                        id: wmp11PlayMa

                        anchors.fill: parent

                        preventStealing: true
                        propagateComposedEvents: true
                        hoverEnabled: true

                        onClicked: root.togglePlaying()
                    }
                }
                Image {
                    id: wmp11Next

                    Layout.preferredWidth: 27
                    Layout.preferredHeight: 17

                    property string buttonState: !root.canGoNext ? "-disabled.png": (wmp11NextMa.containsMouse ?
                                                                    (wmp11NextMa.containsPress ?
                                                                    "-pressed.png" : "-hover.png")
                                                                    : ".png")

                    source: "png/wmp11/controls" + buttonState
                    sourceClipRect: Qt.rect(95, 4, 27, 17)

                    MouseArea {
                        id: wmp11NextMa

                        anchors.fill: parent

                        preventStealing: true
                        propagateComposedEvents: true
                        hoverEnabled: true

                        onClicked: root.next()
                    }
                }
            }

            RowLayout { // disabled due to the mpris2model that I'm using does not support muting nor changing the volume
                Layout.topMargin: -2
                Layout.leftMargin: -3

                spacing: 1

                Image {
                    id: wmp11Vol

                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 17

                    // property string buttonState: !root.canControl ? "-disabled.png": (wmp11VolMa.containsMouse ?
                    //                                                 (wmp11VolMa.containsPress ?
                    //                                                 "-pressed.png" : "-hover.png")
                    //                                                 : ".png")
                    //
                    // source: "png/wmp11/controls" + buttonState
                    source: "png/wmp11/controls-disabled.png"
                    sourceClipRect: Qt.rect(122, 4, 15, 17)

                    MouseArea {
                        id: wmp11VolMa

                        anchors.fill: parent

                        preventStealing: true
                        propagateComposedEvents: true
                        hoverEnabled: true
                    }
                }
                Image {
                    id: wmp11VolCustom

                    Layout.preferredWidth: 11
                    Layout.preferredHeight: 17

                    // property string buttonState: !root.canControl ? "-disabled.png": (wmp11VolCustomMa.containsMouse ?
                    //                                                 (wmp11VolCustomMa.containsPress ?
                    //                                                 "-pressed.png" : "-hover.png")
                    //                                                 : ".png")
                    //
                    // source: "png/wmp11/controls" + buttonState
                    source: "png/wmp11/controls-disabled.png"
                    sourceClipRect: Qt.rect(137, 4, 11, 17)

                    MouseArea {
                        id: wmp11VolCustomMa

                        anchors.fill: parent

                        preventStealing: true
                        propagateComposedEvents: true
                        hoverEnabled: true
                    }
                }
            }
        }
    }

    PlasmaCore.Dialog {
        id: popup

        /* Using an if statement that checks if the popup button contains a press.
        *  Now, why am I checking for a press instead of making the MouseArea handle this?
        *  Because for whatever reason the clicked() signal never happens.
        */
        property bool showPopup: {
            if(root.toolbarStyle == "wmp10") {
                if(bgRightMa.containsPress && showPopup == false) return true
                    else if(bgRightMa.containsPress && showPopup == true) return false
            }
            else if(root.toolbarStyle == "wmp11") {
                if(wmp11RightTopMa.containsPress && showPopup == false) return true
                    else if(wmp11RightTopMa.containsPress && showPopup == true) return false
            }
        }

        type: PlasmaCore.Dialog.Dock
        location: "Floating" // to get rid of the slide animation
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.WindowStaysOnTopHint
        visualParent: parent
        visible: showPopup

        mainItem: Image {
            source: "png/" + root.toolbarStyle + "/" + "frame.png"

            Item {
                id: design1

                anchors.fill: parent

                visible: true

                Rectangle {
                    color: "black"
                    anchors.fill: parent
                    anchors.margins: 5
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 5

                    fillMode: Image.PreserveAspectCrop
                    source: root.albumArt
                    opacity: 0.4
                }

                ColumnLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    anchors.top: parent.top
                    anchors.topMargin: 3

                    spacing: 0

                    Text {
                        text: root.artist != "" ? root.artist : (root.track != "" ? "No album name" : "No media playing")
                        color: "lightgreen"
                        font.pointSize: 8
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.track
                        color: "lightgreen"
                        font.pointSize: 8
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
