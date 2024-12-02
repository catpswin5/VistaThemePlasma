/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>
    SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2 as Kirigami
import org.kde.kwindowsystem 1.0
import org.kde.ksvg as KSvg

ColumnLayout {
    property var submodelIndex
    property int flatIndex: isGroup && index != undefined ? index : 0
    readonly property int appPid: isGroup ? model.AppPid : pidParent
    property var winId: thumbnailSourceItem.winId

    // HACK: Avoid blank space in the tooltip after closing a window
    ListView.onPooled: width = height = 0
    ListView.onReused: width = height = undefined

    readonly property string title: {
        if (!isWin) {
            return genericName || "";
        }

        let text;
        if (isGroup) {
            if (model.display.length === 0) {
                return "";
            }
            text = model.display;
        } else {
            text = displayParent;
        }

        // Normally the window title will always have " — [app name]" at the end of
        // the window-provided title. But if it doesn't, this is intentional 100%
        // of the time because the developer or user has deliberately removed that
        // part, so just display it with no more fancy processing.
        if (!text.match(/\s+(—|-|–)/)) {
            return text;
        }

        // KWin appends increasing integers in between pointy brackets to otherwise equal window titles.
        // In this case save <#number> as counter and delete it at the end of text.
        text = `${(text.match(/.*(?=\s+(—|-|–))/) || [""])[0]}${(text.match(/<\d+>/) || [""]).pop()}`;

        // In case the window title had only redundant information (i.e. appName), text is now empty.
        // Add a hyphen to indicate that and avoid empty space.
        if (text === "") {
            text = "—";
        }
        return text;
    }

    spacing: Kirigami.Units.smallSpacing

    // thumbnail container
    MouseArea {
        id: mouseX11
        Layout.preferredWidth: 215
        Layout.preferredHeight: 137
        Layout.rightMargin: 6
        Layout.leftMargin: 6
        Layout.bottomMargin: 6
        Layout.topMargin: 6

        hoverEnabled: true

        KSvg.FrameSvgItem {
            z: -1
            imagePath: Qt.resolvedUrl("svgs/taskbarhover.svg")
            prefix: "active"
            anchors.fill: parent
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
            opacity: parent.containsMouse
        }

        onContainsMouseChanged: {
            tasks.windowsHovered([winId], parent.containsMouse);
        }

        ColumnLayout {
            id: containerX11
            anchors.fill: parent
            anchors.rightMargin: 6
            anchors.leftMargin: 6
            anchors.bottomMargin: 6
            anchors.topMargin: 6

            RowLayout {
                id: titleThing
                Layout.minimumWidth: 205
                Layout.maximumWidth: 205
                Layout.bottomMargin: 3
                Layout.leftMargin: 1

                Kirigami.Icon {
                    z: 1
                    id: appIcon
                    source: icon
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                }
                Text {
                    text: title
                    color: "white"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                MouseArea {
                    hoverEnabled: true
                    onEntered: {
                        closeBtnSvg.prefix = "hover"
                    }
                    onExited: {
                        closeBtnSvg.prefix = "normal"
                    }
                    onPressed: {
                        closeBtnSvg.prefix = "pressed"
                    }
                    onClicked: {
                        tasksModel.requestClose(submodelIndex);
                    }
                    Layout.preferredWidth: Kirigami.Units.smallSpacing*3+2;
                    Layout.preferredHeight: Kirigami.Units.smallSpacing*3+2;
                    Layout.rightMargin: 6

                    KSvg.FrameSvgItem {
                        id: closeBtnSvg
                        anchors.centerIn: parent
                        width: Kirigami.Units.smallSpacing*3+2; // first time i use Kirigami.Units on my code LMFAO
                        height: Kirigami.Units.smallSpacing*3+2;
                        imagePath: Qt.resolvedUrl("svgs/button-close.svg")
                        prefix: "normal"
                        opacity: mouseX11.containsMouse
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }
            }

            Item {
                id: thumbnailSourceItem

                Layout.fillWidth: true
                Layout.preferredHeight: 110
                Layout.topMargin: -6
                Layout.rightMargin: 8
                Layout.leftMargin: 6

                clip: true
                visible: true

                readonly property bool isMinimized: isGroup ? IsMinimized : isMinimizedParent
                readonly property var winId: toolTipDelegate.isWin ? toolTipDelegate.windows[flatIndex] : undefined

                Rectangle {
                    color: "black"
                    anchors.fill: thumbnailLoader
                    anchors.margins: -1
                }

                Loader {
                    z: 1
                    id: thumbnailLoader
                    active: !toolTipDelegate.isLauncher
                        && !albumArtImage.visible
                        && (Number.isInteger(thumbnailSourceItem.winId) || pipeWireLoader.item && !pipeWireLoader.item.hasThumbnail)
                        && flatIndex !== -1 // Avoid loading when the instance is going to be destroyed
                    asynchronous: true
                    visible: active
                    anchors.fill: parent
                    anchors.margins: 3
                    // Indent a little bit so that neither the thumbnail nor the drop
                    // shadow can cover up the highlight

                    sourceComponent: thumbnailSourceItem.isMinimized || pipeWireLoader.active ? iconItem : x11Thumbnail


                    Component {
                        id: x11Thumbnail

                        PlasmaCore.WindowThumbnail {
                            winId: thumbnailSourceItem.winId
                        }
                    }

                    // when minimized, we don't have a preview on X11, so show the icon
                    Component {
                        id: iconItem

                        Rectangle {

                            gradient: Gradient {
                                GradientStop { position: 0; color: "#ffffff" }
                                GradientStop { position: 1; color: "#cccccc" }
                            }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                id: realIconItem
                                source: icon
                                animated: false
                                visible: valid
                                opacity: pipeWireLoader.active ? 0 : 1

                                SequentialAnimation {
                                    running: true

                                    PauseAnimation {
                                        duration: Kirigami.Units.humanMoment
                                    }

                                    NumberAnimation {
                                        id: showAnimation
                                        duration: Kirigami.Units.longDuration
                                        easing.type: Easing.OutCubic
                                        property: "opacity"
                                        target: realIconItem
                                        to: 1
                                    }
                                }

                            }

                        }
                    }
                }

                Loader {
                    id: pipeWireLoader
                    anchors.fill: hoverHandler
                    // Indent a little bit so that neither the thumbnail nor the drop
                    // shadow can cover up the highlight
                    anchors.margins: thumbnailLoader.anchors.margins

                    active: !toolTipDelegate.isLauncher && !albumArtImage.visible && KWindowSystem.isPlatformWayland && flatIndex !== -1
                    asynchronous: true
                    //In a loader since we might not have PipeWire available yet (WITH_PIPEWIRE could be undefined in plasma-workspace/libtaskmanager/declarative/taskmanagerplugin.cpp)
                    source: "PipeWireThumbnail.qml"
                }

                Loader {
                    active: (pipeWireLoader.item && pipeWireLoader.item.hasThumbnail) || (thumbnailLoader.status === Loader.Ready && !thumbnailSourceItem.isMinimized)
                    asynchronous: true
                    visible: active
                    anchors.fill: pipeWireLoader.active ? pipeWireLoader : thumbnailLoader
                }

                Loader {
                    active: albumArtImage.visible && albumArtImage.status === Image.Ready && flatIndex !== -1 // Avoid loading when the instance is going to be destroyed
                    asynchronous: true
                    visible: active
                    anchors.centerIn: hoverHandler

                    sourceComponent: ShaderEffect {
                        id: albumArtBackground
                        readonly property Image source: albumArtImage

                        // Manual implementation of Image.PreserveAspectCrop
                        readonly property real scaleFactor: Math.max(hoverHandler.width / source.paintedWidth, hoverHandler.height / source.paintedHeight)
                        width: Math.round(source.paintedWidth * scaleFactor)
                        height: Math.round(source.paintedHeight * scaleFactor)
                        layer.enabled: true
                        opacity: 0.25
                        layer.effect: FastBlur {
                            source: albumArtBackground
                            anchors.fill: source
                            radius: 30
                        }
                    }
                }

                Image {
                    id: albumArtImage
                    // also Image.Loading to prevent loading thumbnails just because the album art takes a split second to load
                    // if this is a group tooltip, we check if window title and track match, to allow distinguishing the different windows
                    // if this app is a browser, we also check the title, so album art is not shown when the user is on some other tab
                    // in all other cases we can safely show the album art without checking the title
                    readonly property bool available: (status === Image.Ready || status === Image.Loading)
                        && (!(isGroup || backend.applicationCategories(launcherUrl).includes("WebBrowser")) || titleIncludesTrack)

                    anchors.fill: hoverHandler
                    // Indent by one pixel to make sure we never cover up the entire highlight
                    anchors.margins: 1
                    sourceSize: Qt.size(parent.width, parent.height)

                    asynchronous: true
                    source: toolTipDelegate.playerData?.artUrl ?? ""
                    fillMode: Image.PreserveAspectFit
                    visible: available
                }

                // hoverHandler has to be unloaded after the instance is pooled in order to avoid getting the old containsMouse status when the same instance is reused, so put it in a Loader.
                Loader {
                    id: hoverHandler
                    active: flatIndex !== -1
                    anchors.fill: parent
                    sourceComponent: ToolTipWindowMouseArea {
                        rootTask: parentTask
                        modelIndex: submodelIndex
                        winId: thumbnailSourceItem.winId
                    }
                }
            }
        }
    }

    function generateSubText() {
        if (activitiesParent === undefined) {
            return "";
        }

        let subTextEntries = [];

        const onAllDesktops = isGroup ? IsOnAllVirtualDesktops : isOnAllVirtualDesktopsParent;
        if (!Plasmoid.configuration.showOnlyCurrentDesktop && virtualDesktopInfo.numberOfDesktops > 1) {
            const virtualDesktops = isGroup ? VirtualDesktops : virtualDesktopParent;

            if (!onAllDesktops && virtualDesktops !== undefined && virtualDesktops.length > 0) {
                let virtualDesktopNameList = new Array();

                for (let i = 0; i < virtualDesktops.length; ++i) {
                    virtualDesktopNameList.push(virtualDesktopInfo.desktopNames[virtualDesktopInfo.desktopIds.indexOf(virtualDesktops[i])]);
                }

                subTextEntries.push(i18nc("Comma-separated list of desktops", "On %1",
                    virtualDesktopNameList.join(", ")));
            } else if (onAllDesktops) {
                subTextEntries.push(i18nc("Comma-separated list of desktops", "Pinned to all desktops"));
            }
        }

        const act = isGroup ? Activities : activitiesParent;
        if (act === undefined) {
            return subTextEntries.join("\n");
        }

        if (act.length === 0 && activityInfo.numberOfRunningActivities > 1) {
            subTextEntries.push(i18nc("Which virtual desktop a window is currently on",
                "Available on all activities"));
        } else if (act.length > 0) {
            let activityNames = [];

            for (let i = 0; i < act.length; i++) {
                const activity = act[i];
                const activityName = activityInfo.activityName(act[i]);
                if (activityName === "") {
                    continue;
                }
                if (Plasmoid.configuration.showOnlyCurrentActivity) {
                    if (activity !== activityInfo.currentActivity) {
                        activityNames.push(activityName);
                    }
                } else if (activity !== activityInfo.currentActivity) {
                    activityNames.push(activityName);
                }
            }

            if (Plasmoid.configuration.showOnlyCurrentActivity) {
                if (activityNames.length > 0) {
                    subTextEntries.push(i18nc("Activities a window is currently on (apart from the current one)",
                        "Also available on %1", activityNames.join(", ")));
                }
            } else if (activityNames.length > 0) {
                subTextEntries.push(i18nc("Which activities a window is currently on",
                    "Available on %1", activityNames.join(", ")));
            }
        }

        return subTextEntries.join("\n");
    }
}
