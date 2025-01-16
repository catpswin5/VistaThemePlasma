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

    width: 158
    height: 30

    hoverEnabled: true
    propagateComposedEvents: true

    KSvg.FrameSvgItem {
        id: hoverTexture

        anchors.fill: parent

        imagePath: Qt.resolvedUrl("svgs/tasks.svg")
        property string type: {
            if(contentMa.containsPress) return "active"
            else return "normal"
        }
        property string state: {
            if(contentMa.containsMouse) return "-hover"
            else return ""
        }
        prefix: type + state
        enabledBorders: KSvg.FrameSvg.TopBorder | KSvg.FrameSvg.BottomBorder
    }

    DropArea {
        signal urlsDropped(var urls)

        anchors.fill: parent

        onPositionChanged: {
            activationTimer.restart();
        }

        onEntered: {
            groupThumbnails.containsDrag = true;
        }

        onExited: {
            activationTimer.stop();
            groupThumbnails.containsDrag = false;
        }

        onDropped: event => {
            if (event.hasUrls) {
                urlsDropped(event.urls);
                return;
            }
        }

        onUrlsDropped: (urls) => {
            tasksModel.requestOpenUrls(modelIndex, urls);
            groupThumbnails.containsDrag = false;
        }

        Timer {
            id: activationTimer

            interval: 250
            repeat: false

            onTriggered: {
                tasksModel.requestActivate(modelIndex);
            }
        }

        visible: isGroupDelegate
    }

    MouseArea {
        id: contentMa

        anchors.fill: parent

        hoverEnabled: true
        propagateComposedEvents: true
        enabled: root.opacity == 1

        onClicked: {
            tasksModel.requestActivate(modelIndex);
            root.visible = false;
        }
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.leftMargin: Kirigami.Units.smallSpacing

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
        }
    }
}
