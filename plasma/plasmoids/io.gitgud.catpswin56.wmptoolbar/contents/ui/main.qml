import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

PlasmoidItem {
    id: root

    readonly property bool multimediaOpen: mediaController.mediaPlayerOpen
    readonly property bool hideToolbar: !multimediaOpen && Plasmoid.configuration.hideToolbar
    readonly property bool useBasic: Plasmoid.configuration.useBasic

    property int lastUsedIndex: -1
    property string lastUsedName: ""

    Layout.minimumWidth: hideToolbar ? 0 : 170
    Layout.maximumHeight: 25

    Plasmoid.status: hideToolbar ? PlasmaCore.Types.HiddenStatus : PlasmaCore.Types.PassiveStatus

    MprisController { id: mediaController }

    Instantiator {
        model: mediaController.mpris2Model
        delegate: PlasmaExtras.MenuItem {
            required property int index
            required property var model

            text: model.identity + "      "
            icon: model.iconName == "emblem-favorite" ? "bookmark_add" : model.iconName
            checkable: true
            checked: mediaController.currentIndex == index
            onClicked: {
                root.lastUsedIndex = index;
                root.lastUsedName = model.identity;
                mediaController.currentIndex = index;
            }
        }
        onObjectAdded: (index, object) => {
            if(object.model.identity == root.lastUsedName) mediaController.currentIndex = root.lastUsedIndex;
            contextMenu.addMenuItem(object);
        }
        onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object)
    }

    PlasmaExtras.Menu {
        id: contextMenu

        visualParent: containerRect
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }

    Item {
        id: containerRect

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: 25

        opacity: root.hideToolbar ? 0 : 1

        ToolBar { id: toolbar; anchors.fill: parent }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: toolTipTimer.restart();
        }
    }

    Timer {
        id: toolTipTimer
        interval: hoverHandler.hovered ? 750 : 375
        onTriggered: toolTip.display = hoverHandler.hovered && !popup.visible;
    }

    PlasmaCore.Dialog {
        id: toolTip

        property bool display: false

        type: PlasmaCore.Dialog.Dock
        location: PlasmaCore.Types.Floating // to get rid of the slide animation
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.WindowStaysOnTopHint
        appletInterface: root
        visualParent: root

        visible: toolTipItem.opacity > 0

        mainItem: Image {
            id: toolTipItem

            width: implicitWidth
            height: implicitHeight

            source: "png/tooltip.png"

            opacity: toolTip.display
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

            Rectangle {
                anchors.fill: parent

                color: "black"
                topRightRadius: 1
                topLeftRadius: 1

                z: -1
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    leftMargin: 6
                    rightMargin: 6
                    topMargin: 4
                }

                spacing: 0

                Text {
                    Layout.fillWidth: true

                    text: mediaController.artist
                    color: "white"
                    font.pointSize: 8
                    elide: Text.ElideRight

                    visible: text != ""

                }

                Text {
                    Layout.fillWidth: true

                    text: mediaController.track != "" ? mediaController.track : i18n("No media playing")
                    color: "white"
                    font.pointSize: 8
                    elide: Text.ElideRight
                }
            }
        }
    }

    PlasmaCore.Dialog {
        id: popup

        type: PlasmaCore.Dialog.Dock
        location: PlasmaCore.Types.Floating // to get rid of the slide animation
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.WindowStaysOnTopHint
        appletInterface: root
        visualParent: root

        visible: false
        onVisibleChanged: {
            if(visible) {
                toolTip.display = false;
            } else if(!visible && hoverHandler.hovered) {
                toolTipTimer.restart();
            }
        }

        mainItem: Image {
            width: implicitWidth
            height: implicitHeight

            source: "png/frame.png"

            Rectangle {
                anchors.fill: parent

                color: "black"
                topRightRadius: 1
                topLeftRadius: 1

                z: -1
            }

            Item {
                id: design1

                anchors.fill: parent

                Item {
                    id: bg

                    anchors.fill: parent
                    anchors.margins: 6

                    Rectangle {
                        anchors.fill: parent

                        color: "black"
                    }

                    Image {
                        anchors.fill: parent

                        fillMode: Image.PreserveAspectCrop
                        source: mediaController.albumArt

                        opacity: 0.4
                    }
                }

                ColumnLayout {
                    anchors {
                        top: parent.top
                        right: parent.right
                        left: parent.left

                        margins: 6
                        topMargin: 4
                    }

                    spacing: 0

                    Text {
                        Layout.fillWidth: true

                        text: mediaController.artist
                        color: "lightgreen"
                        font.pointSize: 8
                        elide: Text.ElideRight

                        visible: text != ""

                    }

                    Text {
                        Layout.fillWidth: true

                        text: mediaController.track != "" ? mediaController.track : i18n("No media playing")
                        color: "lightgreen"
                        font.pointSize: 8
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
