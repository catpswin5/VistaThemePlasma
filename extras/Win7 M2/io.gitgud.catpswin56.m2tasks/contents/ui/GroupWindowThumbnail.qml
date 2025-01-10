import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

MouseArea {
    id: groupThumbnailRoot

    width: 189
    height: 142 + (mprisControls.visible ? (mprisControls.height - Kirigami.Units.smallSpacing*2) : 0)

    Behavior on width {
        NumberAnimation { duration: tooltip.mainItem != pinnedToolTip ? 185 : 0 }
    }

    hoverEnabled: true
    propagateComposedEvents: true

    property QtObject root
    property var modelIndex: tasksModel.makeModelIndex(root.taskIndex, index)

    // TODO: add attention state

    KSvg.FrameSvgItem {
        id: activeTexture

        anchors.fill: hoverTexture

        imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
        prefix: "active"

        visible: model.IsActive
    }

    KSvg.FrameSvgItem {
        id: hoverTexture

        anchors.fill: content
        anchors.margins: -Kirigami.Units.smallSpacing*2

        imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
        prefix: {
            if(contentMa.containsMouse || closeMa.containsMouse) return "hover";
            else if (contentMa.containsPress) return "pressed";
            return "";
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

        onContainsMouseChanged: {
            tasks.windowsHovered(model.WinIdList[0], containsMouse); // FIXME: this does not work for whatever reason
        }

        onClicked: {
            tasksModel.requestActivate(modelIndex);
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing*4
        anchors.bottomMargin: mprisControls.visible ? 24 + Kirigami.Units.smallSpacing*2 : Kirigami.Units.smallSpacing*4

        RowLayout {
            id: header

            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16

                source: model.decoration
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true

                verticalAlignment: Text.AlignVCenter
                text: model.display
                color: "white"
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                renderType: Text.NativeRendering
                horizontalAlignment: Plasmoid.configuration.centerThumbnailText ? Text.AlignHCenter : Text.AlignLeft
                font.hintingPreference: Font.PreferFullHinting
                font.kerning: false
            }

            KSvg.FrameSvgItem {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14

                imagePath: Qt.resolvedUrl("svgs/button-close.svg")
                prefix: closeMa.containsMouse ? (closeMa.containsPress ? "pressed" : "hover") : "normal"

                visible: contentMa.containsMouse || closeMa.containsMouse

                MouseArea {
                    id: closeMa

                    anchors.fill: parent

                    hoverEnabled: true
                    propagateComposedEvents: true

                    onClicked: {
                        tasksModel.requestClose(modelIndex);
                        root.visible = false;
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
                sourceComponent: model.IsMinimized ? appIcon : x11Thumbnail

                visible: true

                Component {
                    id: x11Thumbnail

                    PlasmaCore.WindowThumbnail {
                        winId: model.WinIdList[0]

                        Rectangle {
                            anchors.centerIn: parent

                            width: parent.paintedWidth+2
                            height: parent.paintedHeight+2

                            color: "transparent"
                            border.width: 1
                            border.color: "black"

                            opacity: 0.5
                        }
                    }
                }


                // used when there's no thumbnail available (e.g. a minimized application in X11)
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

                            source: model.decoration
                        }
                    }
                }
            }

            Loader {
                id: shadowLoader

                anchors.fill: thumbnailLoader

                active: true
                asynchronous: true

                sourceComponent: DropShadow {
                    id: realShadow
                    horizontalOffset: 1
                    verticalOffset: 2
                    radius: 1
                    samples: 1
                    color: "#70000000"
                    source: thumbnailLoader.item
                }
            }
        }
    }

    PlayerController {
        id: mprisControls

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left

        root: groupThumbnailRoot.root

        visible: root.playerData != null
    }
}
