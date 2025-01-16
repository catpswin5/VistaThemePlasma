import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager

import org.kde.kwindowsystem

MouseArea {
    id: thumbnailRoot

    property QtObject root

    Connections { // Update the window thumbnail whenever the bindings are updated
        target: thumbnailRoot.root
        function onBindingsUpdated() {
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

    width: windowThumbnailX1.paintedWidth + Kirigami.Units.smallSpacing*2
    height: windowThumbnailX1.paintedHeight + Kirigami.Units.smallSpacing*2

    hoverEnabled: true
    propagateComposedEvents: true

    MouseArea {
        id: contentMa

        anchors.fill: content

        hoverEnabled: true
        propagateComposedEvents: true
        enabled: root.opacity == 1

        onContainsMouseChanged: {
            if(!minimized) tasks.windowsHovered(thumbnailRoot.windows, containsMouse)
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

    Item {
        id: thumbnail

        anchors.centerIn: parent

        width: 172 - Kirigami.Units.smallSpacing
        height: 172 - (Kirigami.Units.smallSpacing * 2)

        PlasmaCore.WindowThumbnail {
            id: windowThumbnailX1

            height: 172
            width: 172

            opacity: 0

            winId: windows[0]
        }

        Loader {
            id: thumbnailLoader

            anchors.fill: parent

            active: true
            asynchronous: true
            sourceComponent: minimized ? appIcon : (KWindowSystem.isPlatformWayland ? waylandThumbnail : x11Thumbnail)

            visible: true

            Component {
                id: x11Thumbnail

                PlasmaCore.WindowThumbnail {
                    id: windowThumbnailX11


                    winId: windows[0]

                    Rectangle {
                        anchors.centerIn: parent

                        width: parent.paintedWidth+2
                        height: parent.paintedHeight+2

                        color: "transparent"

                        border.width: 1
                        border.color: "black"

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

            Component {
                id: waylandThumbnail

                PipeWire.PipeWireSourceItem {
                    id: pipeWireSourceItem

                    nodeId: waylandItem.nodeId

                    TaskManager.ScreencastingRequest {
                        id: waylandItem
                        uuid: windows[0]
                    }

                    Rectangle {
                        anchors.fill: parent

                        color: "transparent"

                        border.width: 1
                        border.color: "black"

                        opacity: 0.5
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1

                        color: "transparent"

                        border.width: 1
                        border.color: "white"

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
                    windowThumbnailX1.visible = false;
                    windowThumbnailX1.visible = true;
                }
            }
        }
    }

    visible: (root && root.mainItem == thumbnailRoot) || isGroupDelegate // only visible if tooltip exists and mainItem is set to the correct one
}
