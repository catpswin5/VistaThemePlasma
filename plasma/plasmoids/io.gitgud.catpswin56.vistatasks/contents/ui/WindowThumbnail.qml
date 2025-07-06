import QtQuick
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.pipewire as PipeWire
import org.kde.taskmanager as TaskManager
import org.kde.kwindowsystem

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mpris as Mpris

MouseArea {
    id: thumbnailRoot

    property QtObject root

    property bool isGroupDelegate: false
    readonly property var captionAlignment: {
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 0) return Text.AlignLeft
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 1) return Text.AlignHCenter
        if(Plasmoid.configuration.thmbnlCaptionAlignment == 2) return Text.AlignRight
    }

    readonly property var display: isGroupDelegate ? model.display : root.display
    readonly property var icon: isGroupDelegate ? model.decoration : root.icon
    readonly property var active: isGroupDelegate ? model.IsActive : root.active
    readonly property var modelIndex: isGroupDelegate ? (tasksModel.makeModelIndex(root.taskIndex, index)) : root.modelIndex
    readonly property var windows: isGroupDelegate ? model.WinIdList : root.windows
    readonly property var minimized: isGroupDelegate ? model.IsMinimized : root.minimized
    readonly property var demandsAttention: isGroupDelegate ? model.IsDemandingAttention : root.demandsAttention

    readonly property bool extendedFunctionality: Plasmoid.configuration.extPreviewFunc

    property real maxThumbnailWidth: 164
    property real maxThumbnailHeight: 94

    property real thumbnailWidth: maxThumbnailWidth
    property real thumbnailHeight: maxThumbnailHeight

    property real baselineAspectRatio: maxThumbnailWidth / maxThumbnailHeight

    readonly property int margins: Kirigami.Units.smallSpacing * 3.5

    implicitWidth: thumbnailWidth + margins
    implicitHeight: thumbnailHeight + margins + (header.visible ? header.height+4 : 0)

    onImplicitHeightChanged: if(isGroupDelegate) ListView.view.updateMaxSize()

    width: implicitWidth
    height: {
        if(isGroupDelegate && ListView.view.maxThumbnailItem !== thumbnailRoot) {
            console.log("hfisgisfigjiasfgjasofgdsojfoasdifjsioj" + ListView.view.maxThumbnailHeight + "_" + implicitHeight)
            return ListView.view.maxThumbnailHeight;
        }
        else
            return implicitHeight;
    }

    hoverEnabled: true
    propagateComposedEvents: true

    component Close: KSvg.FrameSvgItem {
        id: thumbnailClose

        width: 14
        height: width

        imagePath: Qt.resolvedUrl("svgs/button-close.svg")
        prefix: thumbnailCloseMa.containsMouse ? (thumbnailCloseMa.containsPress ? "pressed" : "hover") : "normal"

        visible: opacity && Plasmoid.configuration.showPreviewClose && extendedFunctionality
        opacity: (contentMa.containsMouse || thumbnailCloseMa.containsMouse)

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }

        MouseArea {
            id: thumbnailCloseMa

            anchors.fill: parent

            hoverEnabled: true
            propagateComposedEvents: true

            onClicked: {
                thumbnailRoot.closeTask();
            }
        }
    }

    Item {
        id: frames

        anchors.fill: content
        anchors.margins: -Kirigami.Units.smallSpacing

        visible: isGroupDelegate

        KSvg.FrameSvgItem {
            id: attentionTexture

            anchors.fill: parent

            imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
            prefix: "attention"

            visible: demandsAttention
            opacity: root.parentTask?.attentionAnimOpacity
        }

        KSvg.FrameSvgItem {
            id: activeTexture

            anchors.fill: parent

            imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
            prefix: "active"

            visible: active
        }

        KSvg.FrameSvgItem {
            id: hoverTexture

            anchors.fill: parent

            imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
            prefix: {
                if(contentMa.containsPress) return "pressed";
                else return "hover";
            }

            opacity: contentMa.containsMouse

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }
    }

    function closeTask() {
        tasksModel.requestClose(modelIndex);
        if(!isGroupDelegate) root.parentTask?.hideImmediately();
    }
    DropArea {
        signal urlsDropped(var urls)

        anchors.fill: parent

        onPositionChanged: activationTimer.restart();
        onEntered: root.containsDrag = true;
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

            onTriggered: tasksModel.requestActivate(modelIndex);
        }

        visible: isGroupDelegate
    }

    MouseArea {
        id: contentMa

        anchors.fill: content
        anchors.margins: -Kirigami.Units.smallSpacing

        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onContainsMouseChanged: {
            if(Plasmoid.configuration.windowPeek) {
                if(containsMouse) windowPeek.start();
                else {
                    windowPeek.stop();
                    root.isPeeking = false;
                    tasks.windowsHovered(thumbnailRoot.windows, false)
                }
            }
        }
        onClicked: (mouse) => {
            if(mouse.button == Qt.LeftButton) {
                tasksModel.requestActivate(modelIndex);
                tasks.windowsHovered(thumbnailRoot.windows, false)
                root.parentTask?.hideImmediately();
            }
            if(mouse.button == Qt.MiddleButton) {
                thumbnailRoot.closeTask();
            }
        }
    }

    Timer {
        id: windowPeek

        interval: root.isPeeking ? 1 : 800
        repeat: false
        onTriggered: {
            if(!minimized) {
                tasks.windowsHovered(thumbnailRoot.windows, true);
                root.isPeeking = true;
            }
        }
    }

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        anchors.verticalCenterOffset: mprisControls.active ? -(mprisControls.height / 4) - 2 : 0

        width: parent.width - margins
        height: parent.height - margins - (mprisControls.active ? (mprisControls.height - (Kirigami.Units.smallSpacing*2)) : 0)

        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            id: header

            Layout.fillWidth: true
            Layout.minimumHeight: 16
            Layout.maximumHeight: 16

            spacing: Kirigami.Units.smallSpacing

            visible: isGroupDelegate && extendedFunctionality

            Kirigami.Icon {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16

                source: icon
            }

            Text {
                id: txt
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
            }
        }

        Item {
            id: thumbnail

            Layout.minimumWidth: thumbnailWidth
            Layout.minimumHeight: thumbnailHeight
            Layout.fillHeight: true

            Loader {
                id: thumbnailLoader

                anchors.centerIn: parent

                width: 164
                height: 94

                active: true
                asynchronous: true
                sourceComponent: minimized ? appIcon : (KWindowSystem.isPlatformWayland ? (tasks.toolTipOpen ? waylandThumbnail : undefined) : x11Thumbnail)

                onLoaded: {
                    if(sourceComponent == appIcon) thumbnailRoot.thumbnailWidth = thumbnailLoader.width;
                    if(sourceComponent == appIcon) thumbnailRoot.thumbnailHeight = thumbnailLoader.height;
                    if(isGroupDelegate && ListView.view !== null) ListView.view.updateMaxSize()
                }

                Component {
                    id: x11Thumbnail

                    PlasmaCore.WindowThumbnail {
                        winId: windows !== undefined ? windows[0] : undefined

                        onPaintedSizeChanged: {
                            thumbnailRoot.thumbnailWidth = paintedWidth;
                            thumbnailRoot.thumbnailHeight = paintedHeight;
                        }

                        Close {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: parent.paintedWidth/2 - 8
                            anchors.verticalCenterOffset: -parent.paintedHeight/2 + 8
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
                        id: wl_pw_src
                        nodeId: waylandItem.nodeId

                        TaskManager.ScreencastingRequest {
                            id: waylandItem
                            uuid: windows[0]
                        }

                        // Calculates aspect ratio of the PipeWire stream size, which is effectively the window's dimensions
                        property real aspectRatio: (wl_pw_src.streamSize.height == 0) ? 0.0 : wl_pw_src.streamSize.width / wl_pw_src.streamSize.height
                        // If the stream's width is larger than the height, and also the aspectRatio is greater or equal to the
                        // aspect ratio of the maximum thumbnail's dimensions, then it follows that the thumbnail preview's width
                        // will be at the maximum, therefore it's a fixed known value.
                        // In this case, the height is calculated through simple proportions
                        // Otherwise the calculations can be derived in a similar manner
                        property bool widthTakesPrecedence: (wl_pw_src.streamSize.width > wl_pw_src.streamSize.height) &&
                        (aspectRatio >= thumbnailRoot.baselineAspectRatio)

                        onStreamSizeChanged: thumbnailRect.updateSize();
                        onReadyChanged: if(ready) thumbnailRect.updateSize();

                        Item {
                            id: thumbnailRect

                            anchors.centerIn: parent

                            onWidthChanged: thumbnailRoot.thumbnailWidth = ((thumbnailRect.width-2) > 0) ? thumbnailRect.width-2 : thumbnailRoot.maxThumbnailWidth
                            onHeightChanged: thumbnailRoot.thumbnailHeight = ((thumbnailRect.height-2) > 0) ? thumbnailRect.height-2 : thumbnailRoot.maxThumbnailHeight

                            function updateSize() {
                                if(wl_pw_src.aspectRatio === 0.0 || !wl_pw_src.ready) {
                                    width = 0;
                                    height = 0;
                                } else if(wl_pw_src.widthTakesPrecedence) {
                                    width = Math.floor(thumbnailRoot.maxThumbnailWidth + 2);
                                    height = Math.floor((thumbnailRoot.maxThumbnailWidth / wl_pw_src.aspectRatio) + 2);
                                } else {
                                    width = Math.floor((wl_pw_src.aspectRatio * thumbnailRoot.maxThumbnailHeight) + 2);
                                    height = Math.floor(thumbnailRoot.maxThumbnailHeight + 2);
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent

                                width: parent.width
                                height: parent.height

                                color: "transparent"

                                border.width: 1
                                border.color: "black"

                                opacity: 0.5
                                z: -1
                            }

                            Rectangle {
                                anchors.centerIn: parent

                                width: parent.width+2
                                height: parent.height+2

                                color: "transparent"

                                border.width: 1
                                border.color: "white"
                                radius: 2

                                opacity: 0.5
                                z: -1
                            }

                            Close {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: parent.width/2 - 10
                                anchors.verticalCenterOffset: -parent.height/2 + 10
                            }
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

                Loader {
                    id: mprisControls

                    readonly property QtObject root: thumbnailRoot.root

                    // center it instead due to the parent item rect being a little weird in height
                    anchors {
                        centerIn: parent
                        verticalCenterOffset: (thumbnailHeight / 2) - (height / 2)
                    }

                    width: thumbnailWidth

                    active: (Plasmoid.configuration.showPreviewMute && root.parentTask?.hasAudioStream)
                        || (Plasmoid.configuration.showPreviewMpris && root.playerData !== null)
                    asynchronous: true
                    source: "PlayerController.qml"

                    visible: mprisControls.item?.paintedWidth <= thumbnailWidth

                    Rectangle {
                        anchors.fill: parent

                        color: "black"

                        opacity: 0.5
                        z: -1
                    }

                    z: 1
                }

                // Reload the component when thumbnailRoot's windows property changes. This fixes a bug in which the thumbnail shows the wrong window.
                Connections {
                    target: thumbnailRoot
                    function onWindowsChanged() {
                        thumbnailLoader.active = false;
                        thumbnailLoader.active = true;
                    }
                }
            }
        }
    }

    Component.onDestruction: if(isGroupDelegate) ListView.view.updateMaxSize()
}
