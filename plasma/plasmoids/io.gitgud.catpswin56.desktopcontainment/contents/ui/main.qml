/*
    SPDX-FileCopyrightText: 2011-2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2011-2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.ksvg as KSvg
import org.kde.kquickcontrolsaddons as KQuickControlsAddons
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

import org.kde.plasma.private.containmentlayoutmanager as ContainmentLayoutManager

import io.gitgud.catpswin56.desktopcontainment.folder as Folder

import vistathemeplasma.positionmanager

import "code/FolderTools.js" as FolderTools

ContainmentItem {
    id: root

    switchWidth: { switchSize(); }
    switchHeight: { switchSize(); }

    // Only exists because the default CompactRepresentation doesn't:
    // - open on drag
    // - allow defining a custom drop handler
    // TODO remove once it gains that feature (perhaps optionally?)
    compactRepresentation: Item {  }

    objectName: isFolder ? "folder" : "desktop"

    width: isPopup ? undefined : preferredWidth(false) // Initial size when adding to e.g. desktop.
    height: isPopup ? undefined : preferredHeight(false) // Initial size when adding to e.g. desktop.

    function switchSize() {
        // Support expanding into the full representation on very thick vertical panels.
        if (isPopup && Plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return Kirigami.Units.iconSizes.small * 8;
        }

        return 0;
    }

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property bool isFolder: true //(Plasmoid.pluginName === "org.kde.plasma.folder")
    property bool isContainment: Plasmoid.isContainment
    property bool isPopup: (Plasmoid.location !== PlasmaCore.Types.Floating)
    property bool useListViewMode: isPopup && Plasmoid.configuration.viewMode === 0

    property Component appletAppearanceComponent
    property Item toolBox

    property int handleDelay: 800
    property real haloOpacity: 0.5

    readonly property int hoverActivateDelay: 750 // Magic number that matches Dolphin's auto-expand folders delay.

    readonly property Loader folderViewLayer: fullRepresentationItem.folderViewLayer
    readonly property Item appletsLayout: fullRepresentationItem.appletsLayout

    // Plasmoid.title is set by a Binding {} in FolderViewLayer
    toolTipSubText: ""
    Plasmoid.icon: (!Plasmoid.configuration.useCustomIcon && folderViewLayer.ready) ? symbolicizeIconName(folderViewLayer.view.model.iconName) : Plasmoid.configuration.icon

    // We want to do this here rather than in the model because we don't always want
    // symbolic icons everywhere, but we do know that we always want them in this
    // specific representation right here
    function symbolicizeIconName(iconName) {
        const symbolicSuffix = "-symbolic";
        if (iconName.endsWith(symbolicSuffix)) {
            return iconName;
        }

        return iconName + symbolicSuffix;
    }

    function addLauncher(desktopUrl) {
        if (!isFolder) {
            return;
        }

        folderViewLayer.view.linkHere(desktopUrl);
    }

    function preferredWidth(forMinimumSize: bool): real {
        if (isContainment || !folderViewLayer.ready) {
            return -1;
        } else if (useListViewMode) {
            return (forMinimumSize ? folderViewLayer.view.cellHeight * 4 : Kirigami.Units.iconSizes.small * 16);
        }

        return (folderViewLayer.view.cellWidth * (forMinimumSize ? 1 : 3)) + (Kirigami.Units.iconSizes.small * 2);
    }

    function preferredHeight(forMinimumSize: bool): real {
        let height;
        if (isContainment || !folderViewLayer.ready) {
            return -1;
        } else if (useListViewMode) {
            height = (folderViewLayer.view.cellHeight * (forMinimumSize ? 1 : 15)) + Kirigami.Units.smallSpacing;
        } else {
            height = (folderViewLayer.view.cellHeight * (forMinimumSize ? 1 : 2)) + Kirigami.Units.iconSizes.small;
        }

        if (Plasmoid.configuration.labelMode !== 0) {
            height += folderViewLayer.item.labelHeight;
        }

        return height;
    }

    function isDrag(fromX, fromY, toX, toY) {
        const length = Math.abs(fromX - toX) + Math.abs(fromY - toY);
        return length >= Qt.styleHints.startDragDistance;
    }

    onFocusChanged: {
        if (focus && isFolder) {
            folderViewLayer.item.forceActiveFocus();
        }
    }

    onExternalData: (mimetype, data) => {
        Plasmoid.configuration.url = data
    }

    component ShortDropBehavior : Behavior {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    component LongDropBehavior : Behavior {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    KSvg.FrameSvgItem {
        id: highlightItemSvg

        visible: false

        imagePath: isPopup ? "widgets/viewitem" : ""
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id: listItemSvg

        visible: false

        imagePath: isPopup ? "widgets/viewitem" : ""
        prefix: "normal"
    }

    KSvg.Svg {
        id: toolBoxSvg
        imagePath: "widgets/toolbox"
        property int rightBorder: elementSize("right").width
        property int topBorder: elementSize("top").height
        property int bottomBorder: elementSize("bottom").height
        property int leftBorder: elementSize("left").width
    }

    // FIXME: the use and existence of this property is a workaround
    preloadFullRepresentation: true
    fullRepresentation: FolderViewDropArea {
        id: dropArea

        anchors {
            fill: parent

            leftMargin: root.availableScreenRect ? root.availableScreenRect.x : 0
            topMargin: root.availableScreenRect ? root.availableScreenRect.y : 0

            rightMargin: root.availableScreenRect ? (parent?.width ?? 0) - (root.availableScreenRect.x + root.availableScreenRect.width) : 0
            bottomMargin: root.availableScreenRect ? (parent?.height ?? 0) - (root.availableScreenRect.y + root.availableScreenRect.height) : 0
        }

        LongDropBehavior on anchors.topMargin { }
        LongDropBehavior on anchors.leftMargin { }
        LongDropBehavior on anchors.rightMargin { }
        LongDropBehavior on anchors.bottomMargin { }

        property alias folderViewLayer: folderViewLayer
        property alias appletsLayout: appletsLayout

        Layout.minimumWidth: preferredWidth(!isPopup)
        Layout.minimumHeight: preferredHeight(!isPopup)

        Layout.preferredWidth: preferredWidth(false)
        Layout.preferredHeight: preferredHeight(false)
        // Maximum size is intentionally unbounded

        preventStealing: true
        enabled: !appletsLayout.isDragging

        onDragEnter: event => {
            if (isContainment && Plasmoid.immutable && !(isFolder && FolderTools.isFileDrag(event))) {
                event.ignore();
            }

            // Don't allow any drops while listing.
            if (isFolder && folderViewLayer.view.status === Folder.FolderModel.Listing) {
                event.ignore();
            }

            // Firefox tabs are regular drags. Since all of our drop handling is asynchronous
            // we would accept this drop and have Firefox not spawn a new window. (Bug 337711)
            if (event.mimeData.formats.indexOf("application/x-moz-tabbrowser-tab") !== -1) {
                event.ignore();
            }
        }

        onDragMove: event => {
            // TODO: We should reject drag moves onto file items that don't accept drops
            // (cf. QAbstractItemModel::flags() here, but DeclarativeDropArea currently
            // is currently incapable of rejecting drag events.

            // Trigger autoscroll.
            if (isFolder && FolderTools.isFileDrag(event)) {
                handleDragMove(folderViewLayer.view, mapToItem(folderViewLayer.view, event.x, event.y));
            }
        }

        onDragLeave: event => {
            // Cancel autoscroll.
            if (isFolder) {
                handleDragEnd(folderViewLayer.view);
            }
        }

        onDrop: event => {
            if (isFolder && FolderTools.isFileDrag(event)) {
                handleDragEnd(folderViewLayer.view);
                folderViewLayer.view.drop(root, event, mapToItem(folderViewLayer.view, event.x, event.y));
            } else if (isContainment) {

                function appletName(event) {
                    if (event.mimeData.formats.indexOf("text/x-plasmoidservicename") < 0) {
                        return null;
                    }
                    var plasmoidId = event.mimeData.getDataAsByteArray("text/x-plasmoidservicename");
                    return plasmoidId;
                }

                var plasmoidId = appletName(event);
                if (!plasmoidId) {
                    event.ignore();
                    return;
                }
                console.log(event.x, event.y, mapToItem(appletsLayout, event.x, event.y).x,  mapToItem(appletsLayout, event.x, event.y).y)
                Plasmoid.newTask(plasmoidId, mapToItem(appletsLayout, event.x, event.y).x, mapToItem(appletsLayout, event.x, event.y).y);
            }
        }

        Component {
            id: compactRepresentation
            CompactRepresentation { folderView: folderViewLayer.view }
        }

        Loader {
            id: folderViewLayer

            anchors.fill: parent
            anchors.leftMargin: appletsLayout.anchors.leftMargin
            anchors.rightMargin: appletsLayout.anchors.rightMargin

            property bool ready: status === Loader.Ready
            property Item view: item?.view ?? null
            property QtObject model: item?.model ?? null

            focus: true

            active: isFolder
            asynchronous: false

            source: "FolderViewLayer.qml"

            onFocusChanged: {
                if (!focus && model) {
                    model.clearSelection();
                }
            }

            Connections {
                target: folderViewLayer.view

                // `FolderViewDropArea` is not a FocusScope. We need to forward manually.
                function onPressed() {
                    folderViewLayer.forceActiveFocus();
                }
            }
        } // folder view

        Connections {
            target: Plasmoid

            function onAppletsAdded() { positionManager.ensurePositions(); console.log("hi"); }
        }

        PositionManager {
            id: positionManager

            container: appletsLayout
            onRefreshed: Plasmoid.configuration.plasmoidPositions = JSON.stringify(positions);

            Component.onCompleted: positionManager.positions = JSON.parse(Plasmoid.configuration.plasmoidPositions);
        }

        Item {
            id: appletsLayout

            Connections {
                target: Containment

                // sanity check
                function onAppletAboutToBeRemoved(applet) {
                    var plasmoid;

                    for(var i = 0; i < appletsLayout.plasmoids.length; i++) {
                        if(appletsLayout.plasmoids[i].applet.Plasmoid == applet) {
                            plasmoid = appletsLayout.plasmoids[i];
                            break;
                        }
                    }

                    if(plasmoid) {
                        plasmoid.remove();
                        appletsLayout.deleteApplet(plasmoid);
                    }
                }
            }

            signal plasmoidCreated(var plasmoid)

            property PlasmoidContainer plasmoid_aboveAll
            property list<PlasmoidContainer> plasmoids: []

            property bool isDragging: false
            onIsDraggingChanged: if(!isDragging) positionManager.refresh();

            property alias positionManager: positionManager

            function deleteApplet(plasmoid: var) {
                if(plasmoid) {
                    var plasmoidIndex = plasmoid.index;

                    plasmoid.remove();

                    // remove the plasmoid from the plasmoids list and reorder the others
                    plasmoids.splice(plasmoidIndex, 1);
                    for(var i = plasmoidIndex; i < plasmoids.length; i++) plasmoids[i].index--;

                    // refresh the positions JSON array
                    positionManager.refresh();
                }
            }

            function createApplet(applet: var, x: int, y: int) {
                // FIXME TODO: this doesn't work, fix later
                var createAtX;
                if(!x) createAtX = 0;
                else createAtX = x;

                var createAtY;
                if(!y) createAtY = 0;
                else createAtY = y;

                var component = Qt.createComponent("PlasmoidContainer.qml", appletsLayout);

                if(component.status == Component.Ready) {
                    var plasmoid = component.createObject(appletsLayout, {
                        x: createAtX,
                        y: createAtY,
                        index: plasmoids.length,
                        applet: root.itemFor(applet)
                    });
                    if(!plasmoid.isSidebar) plasmoids.push(plasmoid);

                } else if(component.status == Component.Error) {
                    console.log("desktop: Error creating plasmoid container:\n", component.errorString());

                }

            }

            anchors.fill: parent
        } // plasmoid layout

        Plasma5Support.DataSource {
            id: execEngine
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => {
                var exitCode = data["exit code"]
                var exitStatus = data["exit status"]
                var stdout = data["stdout"]
                var stderr = data["stderr"]
                exited(sourceName, exitCode, exitStatus, stdout, stderr)
                disconnectSource(sourceName)
            }
            function exec(cmd) {
                if (cmd) {
                    connectSource(cmd)
                }
            }
            signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
        }

        Plasmoid.contextualActions: []

        PlasmaCore.Action {
            id: configAction
            text: i18n("Personalize")
            icon.name: "preferences-desktop-wallpaper"
            shortcut: "alt+d,alt+s"
            onTriggered: Plasmoid.containment.configureRequested(Plasmoid)
        }

        Component.onCompleted: Plasmoid.setInternalAction("configure", configAction);
    }

    // set the plasmoid layout after creation, so the C++ backend can add the applets
    Component.onCompleted: {
        Plasmoid.layout = appletsLayout;
    }
}
