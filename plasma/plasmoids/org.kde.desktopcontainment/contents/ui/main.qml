/*
    SPDX-FileCopyrightText: 2011-2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2011-2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.kirigami 2.20 as Kirigami

import org.kde.private.desktopcontainment.folder 0.1 as Folder

import org.kde.plasma.private.containmentlayoutmanager 1.0 as ContainmentLayoutManager

import "code/FolderTools.js" as FolderTools

ContainmentItem {
    id: root

    switchWidth: { switchSize(); }
    switchHeight: { switchSize(); }

    // Only exists because the default CompactRepresentation doesn't:
    // - open on drag
    // - allow defining a custom drop handler
    // TODO remove once it gains that feature (perhaps optionally?)
    compactRepresentation: (isFolder && !isContainment) ? compactRepresentation : null

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

    property bool isFolder: (Plasmoid.pluginName === "org.kde.plasma.folder")
    property bool isContainment: Plasmoid.isContainment
    property bool isPopup: (Plasmoid.location !== PlasmaCore.Types.Floating)
    property bool useListViewMode: isPopup && Plasmoid.configuration.viewMode === 0

    property Component appletAppearanceComponent
    property Item toolBox

    property int handleDelay: 800
    property real haloOpacity: 0.5

    property int iconSize: Kirigami.Units.iconSizes.small
    property int iconWidth: iconSize
    property int iconHeight: iconWidth

    readonly property int hoverActivateDelay: 750 // Magic number that matches Dolphin's auto-expand folders delay.

    readonly property Loader folderViewLayer: fullRepresentationItem.folderViewLayer
    readonly property ContainmentLayoutManager.AppletsLayout appletsLayout: fullRepresentationItem.appletsLayout

    // Plasmoid.title is set by a Binding {} in FolderViewLayer
    toolTipSubText: ""
    Plasmoid.icon: (!Plasmoid.configuration.useCustomIcon && folderViewLayer.ready) ? symbolicizeIconName(folderViewLayer.view.model.iconName) : Plasmoid.configuration.icon

    onIconHeightChanged: updateGridSize()

    Rectangle {
        anchors.fill: parent
        z: -1
        color: "black"
        visible: Plasmoid.configuration.watermarkTrueGenuine && Plasmoid.configuration.watermarkGenuine
    }

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

    function updateGridSize() {
        // onIconHeightChanged can be triggered before this component is complete and all the children are created
        if (!toolBoxSvg) {
            return;
        }
        appletsLayout.cellWidth = 150;
        appletsLayout.cellHeight = appletsLayout.cellWidth/6;
        appletsLayout.defaultItemWidth = appletsLayout.cellWidth;
        appletsLayout.defaultItemHeight = appletsLayout.cellHeight;
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
            leftMargin: (isContainment && root.availableScreenRect) ? root.availableScreenRect.x : 0
            topMargin: (isContainment && root.availableScreenRect) ? root.availableScreenRect.y : 0

            rightMargin: (isContainment && root.availableScreenRect && parent)
                ? (parent.width - root.availableScreenRect.x - root.availableScreenRect.width) : 0

            bottomMargin: (isContainment && root.availableScreenRect && parent)
                ? (parent.height - root.availableScreenRect.y - root.availableScreenRect.height) : 0
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
            } else if (isContainment) {
                appletsLayout.showPlaceHolderAt(
                    Qt.rect(event.x - appletsLayout.minimumItemWidth / 2,
                    event.y - appletsLayout.minimumItemHeight / 2,
                    appletsLayout.minimumItemWidth,
                    appletsLayout.minimumItemHeight)
                );
            }
        }

        onDragLeave: event => {
            // Cancel autoscroll.
            if (isFolder) {
                handleDragEnd(folderViewLayer.view);
            }

            if (isContainment) {
                appletsLayout.hidePlaceHolder();
            }
        }

        onDrop: event => {
            if (isFolder && FolderTools.isFileDrag(event)) {
                handleDragEnd(folderViewLayer.view);
                folderViewLayer.view.drop(root, event, mapToItem(folderViewLayer.view, event.x, event.y));
            } else if (isContainment) {
                root.processMimeData(event.mimeData,
                    event.x - appletsLayout.placeHolder.width / 2,
                    event.y - appletsLayout.placeHolder.height / 2);
                event.accept(event.proposedAction);
                appletsLayout.hidePlaceHolder();
            }
        }

        Component {
            id: compactRepresentation
            CompactRepresentation { folderView: folderViewLayer.view }
        }

        Connections {
            target: Plasmoid.containment.corona
            ignoreUnknownSignals: true

            function onEditModeChanged() {
                appletsLayout.editMode = Plasmoid.containment.corona.editMode;
            }
        }

        Loader {
            id: folderViewLayer

            anchors.fill: parent

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
        }

        Rectangle {
            id: bg

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }

            width: 150
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 1.0; color: "black" }
                GradientStop { position: 0.0; color: "transparent" }
            }
            opacity: 0.8

            visible: Plasmoid.configuration.fakeSidebar

            MouseArea {
                id: bgMa
                anchors.fill: parent

                hoverEnabled: true
                propagateComposedEvents: true
            }

            Item {
                anchors.left: parent.left
                height: parent.height
                width: 2

                opacity: bgMa.containsMouse ? 0.6 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 500 }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: "black"
                    }
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        width: 1
                        color: "white"
                    }
                }
            }

            Rectangle {
                anchors.fill: parent

                color: "white"

                opacity: bgMa.containsMouse ? 0.1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 500 }
                }

                z: -1
            }
        }

        Rectangle {
            id: pillThingy

            anchors {
                top: bg.top
                topMargin: Kirigami.Units.smallSpacing*2
                right: bg.right
                rightMargin: Kirigami.Units.smallSpacing*2
            }

            height: 22
            width: 79

            border.width: 1
            border.color: "white"
            radius: 12

            color: "#214d72"

            opacity: 0.4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing*2 - Kirigami.Units.smallSpacing/2
                anchors.rightMargin: Kirigami.Units.smallSpacing*2 - Kirigami.Units.smallSpacing/2

                KSvg.SvgItem {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    imagePath: Qt.resolvedUrl("svgs/controls.svg")
                    elementId: "add"

                    opacity: addMa.containsMouse ? (addMa.containsPress ? 0.8 : 1) : 0.8

                    KSvg.SvgItem {
                        anchors.fill: parent
                        imagePath: Qt.resolvedUrl("svgs/controls.svg")
                        elementId: "hover"

                        opacity: addMa.containsMouse ? (addMa.containsPress ? 0.8 : 1) : 0.0
                    }

                    MouseArea {
                        id: addMa

                        property QtObject qAction: root.Plasmoid.internalAction("add widgets")

                        anchors.fill: parent

                        hoverEnabled: true
                        propagateComposedEvents: true

                        onClicked: {
                            qAction.trigger();
                            // appletsLayout.editMode = !appletsLayout.editMode;
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 12
                    Layout.preferredWidth: 1
                    color: "white"
                }

                KSvg.SvgItem {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    imagePath: Qt.resolvedUrl("svgs/controls.svg")
                    elementId: "left"
                    opacity: 0.4
                }
                KSvg.SvgItem {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    imagePath: Qt.resolvedUrl("svgs/controls.svg")
                    elementId: "right"
                    opacity: 0.4
                }
            }

            visible: Plasmoid.configuration.fakeSidebar
        }

        Rectangle {
            id: addTextBg

            anchors {
                top: bg.top
                topMargin: Kirigami.Units.smallSpacing*2
                right: pillThingy.left
                rightMargin: -Kirigami.Units.smallSpacing*2
            }

            height: 22
            width: addText.implicitWidth + Kirigami.Units.smallSpacing*5

            topLeftRadius: 12
            bottomLeftRadius: 12

            color: "#214d72"

            opacity: addMa.containsMouse ? 0.6 : 0

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

            z: -1
        }

        Text {
            id: addText

            anchors.centerIn: addTextBg
            anchors.horizontalCenterOffset: -Kirigami.Units.smallSpacing/2

            text: "Gadgets"
            color: "white"

            opacity: addMa.containsMouse

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        ContainmentLayoutManager.AppletsLayout {
            id: appletsLayout
            anchors.fill: Plasmoid.configuration.fakeSidebar ? bg : parent
            anchors.topMargin:Plasmoid.configuration.fakeSidebar ? pillThingy.height + Kirigami.Units.smallSpacing*5 : 0
            relayoutLock: width !== root.availableScreenRect.width || height !== root.availableScreenRect.height
            // NOTE: use root.availableScreenRect and not own width and height as they are updated not atomically
            configKey: "ItemGeometries-" + Math.round(root.screenGeometry.width) + "x" + Math.round(root.screenGeometry.height)
            fallbackConfigKey: root.availableScreenRect.width > root.availableScreenRect.height ? "ItemGeometriesHorizontal" : "ItemGeometriesVertical"

            containment: Plasmoid
            containmentItem: root
            editModeCondition: Plasmoid.immutable
                    ? ContainmentLayoutManager.AppletsLayout.Locked
                    : ContainmentLayoutManager.AppletsLayout.AfterPressAndHold

            onEditModeChanged: Plasmoid.containment.corona.editMode = editMode;

            minimumItemWidth: 0
            minimumItemHeight: 0

            cellWidth: 0
            cellHeight: 0

            eventManagerToFilter: folderViewLayer.item?.view.view ?? null

            appletContainerComponent: ContainmentLayoutManager.BasicAppletContainer {
                id: appletContainer

                editModeCondition: Plasmoid.immutable
                    ? ContainmentLayoutManager.ItemContainer.Locked
                    : ContainmentLayoutManager.ItemContainer.AfterPressAndHold

                configOverlaySource: "ConfigOverlay.qml"

                MouseArea {
                    id: appletMa

                    anchors.fill: parent

                    hoverEnabled: true
                    propagateComposedEvents: true

                    visible: Plasmoid.configuration.fakeSidebar

                    Item {
                        anchors.right: parent.right
                        anchors.top: parent.top

                        height: 48
                        width: 11

                        visible: opacity

                        opacity: parent.containsMouse

                        Behavior on opacity {
                            NumberAnimation { duration: 250 }
                        }

                        Rectangle {
                            anchors.fill: parent

                            border.width: 1
                            border.color: "white"
                            radius: 4

                            color: "#214d72"

                            opacity: 0.3
                        }
                        ColumnLayout {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.rightMargin: -1
                            anchors.horizontalCenter: parent.horizontalCenter

                            spacing: 0

                            KSvg.FrameSvgItem {
                                property string suffix: closeMa.containsMouse ? (closeMa.containsPress ? "-pressed" : "-hover") : ""

                                Layout.preferredHeight: 15
                                Layout.preferredWidth: 11

                                imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                prefix: "close" + suffix

                                KSvg.SvgItem {
                                    anchors.centerIn: parent
                                    width: 9
                                    height: 8
                                    imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                    elementId: "close"
                                }

                                MouseArea {
                                    id: closeMa

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    onClicked: appletContainer.applet.plasmoid.internalAction("remove").trigger()
                                }
                            }

                            Rectangle {
                                Layout.preferredHeight: 1
                                Layout.preferredWidth: 7
                                Layout.leftMargin: 2
                                Layout.topMargin: -1
                                color: "white"
                                opacity: 0.3
                            }

                            KSvg.FrameSvgItem {
                                property string suffix: optionsMa.containsMouse ? (optionsMa.containsPress ? "-pressed" : "-hover") : ""

                                Layout.preferredHeight: 15
                                Layout.preferredWidth: 11

                                imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                prefix: "other" + suffix

                                KSvg.SvgItem {
                                    anchors.centerIn: parent
                                    width: 9
                                    height: 9
                                    imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                    elementId: "options"
                                }

                                MouseArea {
                                    id: optionsMa

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    onClicked: appletContainer.applet.plasmoid.internalAction("configure").trigger()
                                }
                            }

                            Rectangle {
                                Layout.preferredHeight: 1
                                Layout.preferredWidth: 7
                                Layout.leftMargin: 2
                                Layout.topMargin: -1
                                Layout.bottomMargin: 3
                                color: "white"
                                opacity: 0.3
                            }

                            KSvg.SvgItem {
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 11
                                Layout.alignment: Qt.AlignHCenter
                                Layout.rightMargin: 2
                                imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                elementId: "drag"
                            }
                        }
                    }

                    z: -1
                }

                onUserDrag: (newPosition, dragCenter) => {
                    const pos = mapToItem(root.parent, dragCenter.x, dragCenter.y);
                    const newCont = root.containmentItemAt(pos.x, pos.y);

                    if (newCont && newCont.plasmoid !== Plasmoid) {
                        const newPos = newCont.mapFromApplet(Plasmoid, pos.x, pos.y);

                        // First go out of applet edit mode, get rid of the config overlay, release mouse grabs in preparation of applet reparenting
                        cancelEdit();
                        newCont.Plasmoid.addApplet(appletContainer.applet.plasmoid, Qt.rect(newPos.x, newPos.y, appletContainer.applet.width, appletContainer.applet.height));
                        appletsLayout.hidePlaceHolder();
                    }
                }

                ShortDropBehavior on x { }
                ShortDropBehavior on y { }
            }

            placeHolder: ContainmentLayoutManager.PlaceHolder {}
        }

        PlasmaCore.Action {
            id: configAction
            text: i18n("Desktop and Wallpaper")
            icon.name: "preferences-desktop-wallpaper"
            shortcut: "alt+d,alt+s"
            onTriggered: Plasmoid.containment.configureRequested(Plasmoid)
        }

        Component.onCompleted: {
            if (!Plasmoid.isContainment) {
                return;
            }

            Plasmoid.setInternalAction("configure", configAction)
            updateGridSize();
        }
    }
}
