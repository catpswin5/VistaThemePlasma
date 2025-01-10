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
    property var captionAlignment: {
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 0) return Text.AlignLeft
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 1) return Text.AlignHCenter
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 2) return Text.AlignRight
    }
    property bool compositionEnabled

    property var display: model.display
    property var icon: model.decoration
    property var active: model.IsActive
    property var modelIndex: tasksModel.makeModelIndex(root.taskIndex, index)
    property var windows: model.WinIdList
    property var minimized: model.IsMinimized

    anchors.right: parent.right
    anchors.left: parent.left

    height: 33 + Kirigami.Units.smallSpacing*4

    Behavior on width {
        NumberAnimation { duration: root.mainItem != pinnedToolTip ? 185 : 0 }
    }

    hoverEnabled: true
    propagateComposedEvents: true

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
            NumberAnimation { duration: compositionEnabled ? 250 : 0 }
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
            tasks.windowsHovered([windows], containsMouse); // FIXME: this does not work for whatever reason
        }

        onClicked: {
            tasksModel.requestActivate(modelIndex);
            root.visible = false;
        }
    }

    ColumnLayout {
        id: content

        property int realWidth: captionIcon.width + captionTitle.implicitWidth + 14 + Kirigami.Units.largeSpacing*8 // im dying

        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing*4

        spacing: Kirigami.Units.smallSpacing/2

        RowLayout {
            id: header

            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: captionIcon

                Layout.preferredHeight: 16
                Layout.preferredWidth: 16

                source: icon
            }

            Text {
                id: captionTitle

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
                id: captionClose

                Layout.preferredWidth: 14
                Layout.preferredHeight: 14

                imagePath: Qt.resolvedUrl("svgs/button-close.svg")
                prefix: closeMa.containsMouse ? (closeMa.containsPress ? "pressed" : "hover") : "normal"

                visible: opacity

                opacity: contentMa.containsMouse || closeMa.containsMouse

                Behavior on opacity {
                    NumberAnimation { duration: compositionEnabled ? 250 : 0 }
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
    }
}
