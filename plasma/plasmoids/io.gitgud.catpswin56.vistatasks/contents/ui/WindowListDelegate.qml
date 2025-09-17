import QtQuick
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

import "code/tools.js" as TaskTools

MouseArea {
    id: thumbnailRoot

    required property var model

    property QtObject root

    property var modelIndex: tasksModel.makeModelIndex(root.taskIndex, model.index)

    implicitWidth: iconBox.implicitWidth + label.implicitWidth + Kirigami.Units.smallSpacing + contentBox.leftMargin + contentBox.rightMargin
    onImplicitWidthChanged: ListView.view.updateMaxSize()

    implicitHeight: 27

    width: {
        if(ListView.view.maxThumbnailItem !== thumbnailRoot)
            return ListView.view.maxThumbnailWidth;
        else
            return implicitWidth;
    }

    function closeTask() {
        tasksModel.requestClose(modelIndex);
        if(!isGroupDelegate) root.parentTask?.hideImmediately();
    }
    hoverEnabled: true
    propagateComposedEvents: true

    DropArea {
        signal urlsDropped(var urls)

        anchors.fill: parent

        onPositionChanged: {
            activationTimer.restart();
        }

        onEntered: {
            root.containsDrag = true;
        }

        onExited: {
            activationTimer.stop();
            root.containsDrag = false;
        }

        onDropped: event => {
            if (event.hasUrls) {
                urlsDropped(event.urls);
                return;
            }
        }

        onUrlsDropped: (urls) => {
            tasksModel.requestOpenUrls(modelIndex, urls);
            root.containsDrag = false;
        }

        Timer {
            id: activationTimer

            interval: 250
            repeat: false

            onTriggered: {
                tasksModel.requestActivate(modelIndex);
            }
        }
    }

    MouseArea {
        id: contentMa

        anchors.fill: frame

        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if(mouse.button == Qt.LeftButton) {
                tasksModel.requestActivate(modelIndex);
                root.parentTask?.hideImmediately();
            }
            if(mouse.button == Qt.MiddleButton) {
                thumbnailRoot.closeTask();
            }
        }
    }

    KSvg.FrameSvgItem {
        id: frame

        property bool isHovered: contentMa.containsMouse
        property bool isActive: model.IsActive || contentMa.containsPress
        property bool doHoverFade: Plasmoid.configuration.hoverFadeAnim && Plasmoid.configuration.disableHottracking
        property string basePrefix: {
            if(isActive) return "active";
            else if(isHovered) return "normal";
            else return "";
        }

        anchors {
            fill: parent

            leftMargin: 2
            rightMargin: 2
        }

        imagePath: Qt.resolvedUrl("svgs/tasks.svg")
        prefix: basePrefix + (isHovered && !Plasmoid.configuration.hoverFadeAnim ? "-hover" : "")


        enabledBorders: KSvg.FrameSvg.TopBorder | KSvg.FrameSvg.BottomBorder

        KSvg.FrameSvgItem {
            anchors.fill: parent

            imagePath: Qt.resolvedUrl("svgs/tasks.svg")
            prefix: "hoverglow"

            visible: opacity > 0
            opacity: frame.isHovered && frame.doHoverFade
            Behavior on opacity {
                NumberAnimation { duration: 175 }
            }

            z: frame.isActive ? 0 : -1
        }
    }

    RowLayout {
        id: contentBox

        spacing: Kirigami.Units.smallSpacing

        property int rightMargin: Kirigami.Units.smallSpacing + Kirigami.Units.smallSpacing/2;
        property int leftMargin: {
            if(model.IsActive) return Kirigami.Units.smallSpacing*2 - Kirigami.Units.smallSpacing/4;
            else return Kirigami.Units.smallSpacing + Kirigami.Units.smallSpacing/2;
        }

        anchors {
            fill: frame

            bottomMargin: Kirigami.Units.smallSpacing
            rightMargin: rightMargin
            leftMargin: leftMargin
            topMargin: model.IsActive ? Kirigami.Units.smallSpacing + Kirigami.Units.smallSpacing/2 : Kirigami.Units.smallSpacing
        }


        Kirigami.Icon {
            id: iconBox
            property int iconSize: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Layout.minimumWidth: iconSize
            Layout.maximumWidth: iconSize
            Layout.minimumHeight: iconSize
            Layout.maximumHeight: iconSize

            Layout.leftMargin: (label.visible ? Kirigami.Units.smallSpacing : 0)

            source: model.decoration
            antialiasing: false
        }

        PlasmaComponents3.Label {
            id: label

            Layout.fillWidth: true
            Layout.fillHeight: true

            wrapMode: (maximumLineCount == 1) ? Text.NoWrap : Text.Wrap
            elide: Text.ElideRight
            textFormat: Text.PlainText
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 1//Plasmoid.configuration.maxTextLines || undefined
            style: Text.Outline
            styleColor: "#02ffffff"
            color: "white"

            Accessible.ignored: true

            // use State to avoid unnecessary re-evaluation when the label is invisible
            states: State {
                name: "labelVisible"
                when: label.visible

                PropertyChanges {
                    target: label
                    text: model.display
                }
            }
        }

    }

    Component.onCompleted: ListView.view.updateMaxSize()
    Component.onDestruction: ListView.view.updateMaxSize()
}
