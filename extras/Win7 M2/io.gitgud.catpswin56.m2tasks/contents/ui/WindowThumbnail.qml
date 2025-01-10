import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

MouseArea {
    id: thumbnailRoot

    property QtObject root

    Connections { // Update the window thumbnail whenever the bindings are updated
        target: thumbnailRoot.root
        function onBindingsUpdated() {
            console.log("hi bindings u pdated");
            thumbnailLoader.item.winId = windows[0];
        }
    }

    property bool isGroupDelegate: false
    property var captionAlignment: {
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 0) return Text.AlignLeft
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 1) return Text.AlignHCenter
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 2) return Text.AlignRight
    }

    property var display: isGroupDelegate ? model.display : root.display
    property var icon: isGroupDelegate ? model.decoration : root.icon
    property var active: isGroupDelegate ? model.IsActive : root.active
    property var modelIndex: isGroupDelegate ? (tasksModel.makeModelIndex(root.taskIndex, index)) : root.modelIndex
    property var windows: isGroupDelegate ? model.WinIdList : root.windows
    property var minimized: isGroupDelegate ? model.IsMinimized : root.minimized

    width: 189
    height: 142 + (mprisControls.visible ? (mprisControls.height - Kirigami.Units.smallSpacing*2) : 0) // 46 for no preview at all

    Behavior on width {
        NumberAnimation { duration: root.mainItem != pinnedToolTip ? 185 : 0 }
    }

    hoverEnabled: true
    propagateComposedEvents: true

    visible: (root && root.mainItem == thumbnailRoot) || isGroupDelegate // only visible if tooltip exists and mainItem is set to the correct one

    // TODO: add attention state

    KSvg.FrameSvgItem {
        id: activeTexture

        anchors.fill: hoverTexture

        imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
        prefix: "active"

        visible: active
    }

    KSvg.FrameSvgItem {
        id: hoverTexture

        anchors.fill: content
        anchors.margins: -Kirigami.Units.smallSpacing*2

        imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
        prefix: {
            if (contentMa.containsPress) return "pressed";
            else return "hover";
        }

        opacity: contentMa.containsMouse || closeMa.containsMouse

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }

    MouseArea {
        id: contentMa

        anchors.fill: content
        anchors.margins: -Kirigami.Units.smallSpacing*2

        hoverEnabled: true
        propagateComposedEvents: true
        enabled: root.opacity == 1

        onContainsMouseChanged: {
            if(!thumbnailRoot.minimized) tasks.windowsHovered(thumbnailRoot.windows, containsMouse)
        }

        onClicked: {
            tasksModel.requestActivate(modelIndex);
            root.visible = false;
        }
    }

    Timer {
        id: primaryCloseTimer
        interval: 175
        running: ((!parent.containsMouse && !root.taskHovered) && root.mainItem == thumbnailRoot) && !isGroupDelegate
        onTriggered: {
            root.destroy();
        }
    }

    Timer {
        id: secondaryCloseTimer
        interval: 0
        running: root.parentTask.contextMenu || root.parentTask.jumpList
        onTriggered: {
            root.destroy();
        }
    }

    Timer {
        id: animationTimer
        interval: 205
        running: root.visible
        onTriggered: {
            root.opacity = 1;
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing*4
        anchors.bottomMargin: mprisControls.visible ? mprisControls.height + Kirigami.Units.smallSpacing*2 : Kirigami.Units.smallSpacing*4

        spacing: Kirigami.Units.smallSpacing/2

        RowLayout {
            id: header

            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16

                source: icon
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true

                verticalAlignment: Text.AlignVCenter
                text: display
                color: "white"
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                style: Text.Outline
                styleColor: "#02ffffff"
                horizontalAlignment: captionAlignment
                rightPadding: captionAlignment == Text.AlignHCenter ? (close.visible ? 0 : close.width + header.spacing) : 0
            }

            KSvg.FrameSvgItem {
                id: close

                Layout.preferredWidth: 14
                Layout.preferredHeight: 14

                imagePath: Qt.resolvedUrl("svgs/button-close.svg")
                prefix: closeMa.containsMouse ? (closeMa.containsPress ? "pressed" : "hover") : "normal"

                visible: opacity

                opacity: contentMa.containsMouse || closeMa.containsMouse

                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }

                MouseArea {
                    id: closeMa

                    anchors.fill: parent

                    hoverEnabled: true
                    propagateComposedEvents: true

                    onClicked: {
                        tasksModel.requestClose(modelIndex);
                    }
                }
            }
        }

        Item {
            id: thumbnail

            Layout.minimumWidth: 96
            Layout.fillWidth: true
            Layout.minimumHeight: 96
            Layout.preferredHeight: 96
            Layout.maximumHeight: 96

            Loader {
                id: thumbnailLoader

                anchors.fill: parent

                active: true
                asynchronous: true
                sourceComponent: minimized ? appIcon : x11Thumbnail

                visible: true

                Component {
                    id: x11Thumbnail

                    PlasmaCore.WindowThumbnail {
                        winId: windows[0]

                        Rectangle {
                            anchors.centerIn: parent

                            width: parent.paintedWidth+2
                            height: parent.paintedHeight+2

                            color: "transparent"
                            border.width: 1
                            border.color: "black"
                            radius: 1

                            opacity: 0.5
                        }
                        Rectangle {
                            anchors.centerIn: parent

                            width: parent.paintedWidth+4
                            height: parent.paintedHeight+4

                            color: "transparent"
                            border.width: 1
                            border.color: "white"
                            radius: 2

                            opacity: 0.5
                        }
                    }
                }

                // Used when there's no thumbnail available.
                Component {
                    id: appIcon

                    Item {
                        Rectangle {
                            anchors.fill: parent

                            gradient: Gradient {
                                GradientStop { position: 0; color: "#ffffff" }
                                GradientStop { position: 1; color: "#cccccc" }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -1

                                color: "transparent"

                                border.width: 1
                                border.color: "black"
                                radius: 1
                            }
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent

                            width: Kirigami.Units.iconSizes.small
                            height: Kirigami.Units.iconSizes.small

                            source: icon
                        }
                    }
                }

                Connections { // Reload the component when thumbnailRoot's windows property changes. This fixes a bug in which the thumbnail shows the wrong window.
                    target: thumbnailRoot
                    function onWindowsChanged() {
                        thumbnailLoader.active = false;
                        thumbnailLoader.active = true;
                    }
                }
            }
        }
    }

    DropArea {
        anchors {
            fill: parent
            margins: 2
        }
    }

    PlayerController {
        id: mprisControls

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left

        root: thumbnailRoot.root

        visible: root.playerData != null && thumbnail.visible
    }
}
