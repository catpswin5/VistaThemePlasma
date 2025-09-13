import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

import "styles" as WMPStyles

PlasmoidItem {
    id: root

    readonly property bool multimediaOpen: mediaController.mediaPlayerOpen
    readonly property bool hideToolbar: !multimediaOpen && Plasmoid.configuration.hideToolbar
    readonly property string toolbarStyle: {
        if(Plasmoid.configuration.toolbarStyle == 0) return "wmp10"
        else return "wmp11"
    }
    readonly property bool wmp11Basic: Plasmoid.configuration.wmp11Basic

    property int lastUsedIndex: -1
    property string lastUsedName: ""

    Layout.minimumWidth: hideToolbar ? 0 : 170
    Layout.maximumHeight: 25

    MprisController { id: mediaController }

    Item {
        id: containerRect

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: 25

        opacity: root.hideToolbar ? 0 : 1

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

        WMPStyles.WMP10 { id: wmp10; anchors.fill: parent; visible: root.toolbarStyle == "wmp10" }
        WMPStyles.WMP11 { id: wmp11; anchors.fill: parent; visible: root.toolbarStyle == "wmp11" }

        HoverHandler {
            id: hoverHandler
            enabled: root.toolbarStyle == "wmp11"
            onHoveredChanged: tooltipTimer.restart();
        }
    }

    Timer {
        id: tooltipTimer
        interval: hoverHandler.hovered ? 750 : 375
        repeat: false
        running: false
        onTriggered: {
            popup.isToolTip = true;
            popup.opacity = hoverHandler.hovered ? 1 : 0;
        }
    }

    PlasmaCore.Dialog {
        id: popup

        property bool isToolTip: false

        type: PlasmaCore.Dialog.Dock
        location: PlasmaCore.Types.Floating // to get rid of the slide animation
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.WindowStaysOnTopHint
        visualParent: root

        visible: opacity > 0
        opacity: 0

        Behavior on opacity {
            enabled: popup.isToolTip
            animation: NumberAnimation { duration: 300 }
        }

        mainItem: Image {
            width: implicitWidth
            height: implicitHeight

            source: popup.isToolTip ? "styles/png/wmp11/tooltip.png" : "styles/png/" + root.toolbarStyle + "/" + "frame.png"

            Rectangle {
                anchors.fill: parent

                color: "black"
                topRightRadius: 1
                topLeftRadius: 1

                z: -1
                visible: root.toolbarStyle == "wmp11"
            }

            Item {
                id: design1

                anchors.fill: parent

                Item {
                    id: bg

                    anchors.fill: parent
                    anchors.margins: 6

                    visible: !popup.isToolTip

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
                        color: popup.isToolTip ? "white" : "lightgreen"
                        font.pointSize: 8
                        elide: Text.ElideRight

                        visible: text != ""

                    }

                    Text {
                        Layout.fillWidth: true

                        text: mediaController.track != "" ? mediaController.track : i18n("No media playing")
                        color: popup.isToolTip ? "white" : "lightgreen"
                        font.pointSize: 8
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
