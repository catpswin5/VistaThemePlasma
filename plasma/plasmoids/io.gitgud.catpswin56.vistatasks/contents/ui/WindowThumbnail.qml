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

    property var display: root.display
    property var icon: root.icon
    property var active: root.active
    property var modelIndex: root.modelIndex
    property var windows: root.windows
    property var minimized: root.minimized

    property real x11ThumbnailWidth: 0
    property real x11ThumbnailHeight: 0

    width: thumbnailLoader.sourceComponent == appIcon || KWindowSystem.isPlatformWayland ? 174 + (Kirigami.Units.smallSpacing * 3) : x11ThumbnailWidth + (Kirigami.Units.smallSpacing * 3)
    height: thumbnailLoader.sourceComponent == appIcon || KWindowSystem.isPlatformWayland ? 92 + (Kirigami.Units.smallSpacing * 3) : x11ThumbnailHeight + (Kirigami.Units.smallSpacing * 3)

    hoverEnabled: true
    propagateComposedEvents: true

    Timer {
        id: primaryCloseTimer
        interval: 0
        running: !root.taskHovered && root.mainItem == thumbnailRoot
        onTriggered: root.destroy();
    }

    Timer {
        id: secondaryCloseTimer
        interval: 0
        running: root.parentTask.contextMenu || root.parentTask.jumpList
        onTriggered: root.destroy();
    }

    Item {
        id: thumbnail

        anchors.centerIn: parent

        width: 172 - (Kirigami.Units.smallSpacing / 2)
        height: 172 - (Kirigami.Units.smallSpacing * 2)

        Loader {
            id: thumbnailLoader

            anchors.centerIn: parent

            height: sourceComponent != appIcon && !KWindowSystem.isPlatformWayland ? 172 : 92
            width: sourceComponent != appIcon && !KWindowSystem.isPlatformWayland ? 172 : 174

            active: true
            asynchronous: true
            sourceComponent: minimized ? appIcon : (KWindowSystem.isPlatformWayland ? waylandThumbnail : x11Thumbnail)

            visible: true

            Component {
                id: x11Thumbnail

                PlasmaCore.WindowThumbnail {
                    id: windowThumbnailX11

                    winId: windows[0]

                    onPaintedSizeChanged: {
                        thumbnailRoot.x11ThumbnailWidth = paintedWidth;
                        thumbnailRoot.x11ThumbnailHeight = paintedHeight;
                    }

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
                        anchors.centerIn: parent
                        width: 174
                        height: 92

                        color: "black"

                        border.width: 1
                        border.color: "black"

                        opacity: 0.5
                        z: -1
                    }
                    Rectangle {
                        anchors.centerIn: parent

                        width: 176
                        height: 94

                        color: "transparent"

                        border.width: 1
                        border.color: "white"

                        opacity: 0.5
                        z: -1
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
                            anchors.topMargin: -1
                            anchors.leftMargin: -1

                            color: "transparent"

                            border.width: 1
                            border.color: "black"

                            opacity: 0.5
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: -2
                            anchors.bottomMargin: -1
                            anchors.rightMargin: -1
                            anchors.leftMargin: -2

                            color: "transparent"

                            border.width: 1
                            border.color: "white"
                            radius: 2

                            opacity: 0.5
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

    visible: root && root.mainItem == thumbnailRoot // only visible if tooltip exists and mainItem is set to the correct one
}
