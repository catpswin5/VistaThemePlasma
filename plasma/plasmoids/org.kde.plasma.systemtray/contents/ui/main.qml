/*
    SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.5
import QtQml.Models 2.10
import QtQuick.Layouts 1.1
import QtQuick.Window 2.15

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasmoid 2.0
import org.kde.draganddrop 2.0 as DnD
import org.kde.kirigami 2.5 as Kirigami // For Settings.tabletMode
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.kwindowsystem

import "items"
import "models" as ItemModels

ContainmentItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : mainLayout.implicitWidth + Kirigami.Units.largeSpacing+1
    Layout.minimumHeight: vertical ? mainLayout.implicitHeight + Kirigami.Units.smallSpacing : Kirigami.Units.iconSizes.small

    LayoutMirroring.enabled: !vertical && Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    readonly property alias systemTrayState: systemTrayState
    readonly property alias itemSize: activeIconsGrid.itemSize
    readonly property bool oneRowOrColumn: activeIconsGrid.rowsOrColumns === 1

    readonly property alias hiddenIconsGrid: hiddenIconsGrid
    readonly property alias activeIconsGrid: activeIconsGrid
    readonly property alias systemIconsGrid: systemIconsGrid

    readonly property alias hiddenModel: hiddenIconsModel
    readonly property alias activeModel: activeIconsModel
    readonly property alias systemModel: systemIconsModel

    property bool showHidden: false

    property bool compositionEnabled: KWindowSystem.isPlatformX11 ? KX11Extras.compositingActive : true

    KSvg.Svg {
        id: buttonIcons
        imagePath: Qt.resolvedUrl("svgs/icons.svg");
    }
    KSvg.FrameSvgItem {
        id: dialogSvg
        visible: false
        imagePath: "solid/dialogs/background"
    }

    MouseArea {
        id: tray

        anchors.fill: parent

        onWheel: {
            // Don't propagate unhandled wheel events
            wheel.accepted = true;
        }

        SystemTrayState {
            id: systemTrayState
        }

        //being there forces the items to fully load, and they will be reparented in the popup one by one, this item is *never* visible
        Item {
            id: preloadedStorage
            visible: false
        }

        CurrentItemHighLight {
            id: currentHighlight
            location: Plasmoid.location
            parent: root

            onHighlightedItemChanged: {
                if(dialog.visible) {
                    dialog.raise();
                    dialog.setDialogPosition();
                }
            }
        }

        DnD.DropArea {
            anchors.fill: parent

            preventStealing: true

            /** Extracts the name of the system tray applet in the drag data if present
            * otherwise returns null*/
            function systemTrayAppletName(event) {
                if (event.mimeData.formats.indexOf("text/x-plasmoidservicename") < 0) {
                    return null;
                }
                const plasmoidId = event.mimeData.getDataAsByteArray("text/x-plasmoidservicename");

                if (!Plasmoid.isSystemTrayApplet(plasmoidId)) {
                    return null;
                }
                return plasmoidId;
            }

            onDragEnter: event => {
                if (!systemTrayAppletName(event)) {
                    event.ignore();
                }
            }

            onDrop: {
                const plasmoidId = systemTrayAppletName(event);
                if (!plasmoidId) {
                    event.ignore();
                    return;
                }

                if (Plasmoid.configuration.extraItems.indexOf(plasmoidId) < 0) {
                    const extraItems = Plasmoid.configuration.extraItems;
                    extraItems.push(plasmoidId);
                    Plasmoid.configuration.extraItems = extraItems;
                }
            }
        }

        ItemModels.IconsModel {
            id: hiddenIconsModel

            status: PlasmaCore.Types.PassiveStatus
            grid: hiddenIconsGrid
            orderingManager: Item {
                id: hiddenOrderingManager

                property var orderObject: {}

                function saveConfiguration() {
                    for(var i = 0; i < hiddenIconsModel.items.count; i++) {
                        var item = hiddenIconsModel.items.get(i);
                        if(item.model.itemId !== "")
                            setItemOrder(item.model.itemId, item.itemsIndex, false);
                    }
                    writeToConfig();
                }

                function setItemOrder(id, index, write = true) {
                    if(typeof orderObject === "undefined")
                        orderObject = {};
                    orderObject[id] = index;
                    if(write) writeToConfig();
                }

                function getItemOrder(id) {
                    if(typeof orderObject[id] === "undefined") return -1;
                    return orderObject[id];
                }

                function writeToConfig() {
                    Plasmoid.configuration.hiddenItemOrdering = JSON.stringify(orderObject);
                    Plasmoid.configuration.writeConfig();
                }

                Component.onCompleted: {
                    var list = Plasmoid.configuration.hiddenItemOrdering;
                    if(list !== "")
                        orderObject = JSON.parse(list);

                    if(typeof orderObject === "undefined")
                        orderObject = {};
                }
            }
        }
        ItemModels.IconsModel {
            id: activeIconsModel

            status: PlasmaCore.Types.ActiveStatus
            grid: activeIconsGrid
            orderingManager: Item {
                id: activeOrderingManager

                property var orderObject: {}

                function saveConfiguration() {
                    for(var i = 0; i < activeIconsModel.items.count; i++) {
                        var item = activeIconsModel.items.get(i);
                        if(item.model.itemId !== "")
                            setItemOrder(item.model.itemId, item.itemsIndex, false);
                    }
                    writeToConfig();
                }

                function setItemOrder(id, index, write = true) {
                    if(typeof orderObject === "undefined")
                        orderObject = {};
                    orderObject[id] = index;
                    if(write) writeToConfig();
                }

                function getItemOrder(id) {
                    if(typeof orderObject[id] === "undefined") return -1;
                    return orderObject[id];
                }

                function writeToConfig() {
                    Plasmoid.configuration.activeItemOrdering = JSON.stringify(orderObject);
                    Plasmoid.configuration.writeConfig();
                }

                Component.onCompleted: {
                    var list = Plasmoid.configuration.activeItemOrdering;
                    if(list !== "")
                        orderObject = JSON.parse(list);

                    if(typeof orderObject === "undefined")
                        orderObject = {};
                }
            }
        }
        ItemModels.SystemModel {
            id: systemIconsModel

            orderingManager: Item {
                id: systemOrderingManager

                property var orderObject: {}

                function saveConfiguration() {
                    for(var i = 0; i < systemIconsModel.items.count; i++) {
                        var item = systemIconsModel.items.get(i);
                        if(item.model.itemId !== "")
                            setItemOrder(item.model.itemId, item.itemsIndex, false);
                    }
                    writeToConfig();
                }

                function setItemOrder(id, index, write = true) {
                    if(typeof orderObject === "undefined")
                        orderObject = {};
                    orderObject[id] = index;
                    if(write) writeToConfig();
                }

                function getItemOrder(id) {
                    if(typeof orderObject[id] === "undefined") return -1;
                    return orderObject[id];
                }

                function writeToConfig() {
                    Plasmoid.configuration.systemItemOrdering = JSON.stringify(orderObject);
                    Plasmoid.configuration.writeConfig();
                }

                Component.onCompleted: {
                    var list = Plasmoid.configuration.systemItemOrdering;
                    if(list !== "")
                        orderObject = JSON.parse(list);

                    if(typeof orderObject === "undefined")
                        orderObject = {};
                }
            }
        }

        //Main Layout
        GridLayout {
            id: mainLayout

            anchors.fill: parent
            anchors.topMargin: Plasmoid.configuration.offsetIcons ? -Kirigami.Units.smallSpacing*2 + Kirigami.Units.smallSpacing/2 - Kirigami.Units.smallSpacing/4 : 0

            rowSpacing: 0
            columnSpacing: 0
            flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight

            ExpanderArrow {
                id: expander

                Layout.alignment: vertical ? Qt.AlignVCenter : Qt.AlignHCenter
                Layout.topMargin: !vertical ? (Plasmoid.configuration.offsetIcons ? Kirigami.Units.smallSpacing*2 : 0) : 0
                Layout.rightMargin: -Kirigami.Units.smallSpacing/2

                visible: hiddenIconsGrid.count > 0
            }

            IconsView {
                id: hiddenIconsGrid

                model: hiddenIconsModel

                Behavior on implicitWidth {
                    NumberAnimation { duration: 150 }
                }

                Timer {
                    id: autoCollapse

                    interval: 4000
                    running: root.showHidden && !tray.containsMouse && !dialog.visible // TODO: do this the proper way later
                    onTriggered: root.showHidden = false;
                }
            }
            IconsView {
                id: activeIconsGrid

                Layout.rightMargin: Plasmoid.configuration.trayGapSize - 8 // I have no idea where the extra 7 pixels are coming from.

                model: activeIconsModel
            }

            IconsView {
                id: systemIconsGrid

                model: systemIconsModel
            }
        }

        Timer {
            id: expandedSync
            interval: 100
            onTriggered: systemTrayState.expanded = dialog.visible;
        }

        //Main popup
        PlasmaCore.Dialog {
            id: dialog

            objectName: "popupWindow"
            flags: Qt.WindowStaysOnTopHint
            location: "Floating"

            x: 0
            y: 0

            property int contentMargins: 8

            property int flyoutMargin: Plasmoid.configuration.flyoutMarginEnabled ? Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing/2 : 0
            property bool firstTimePopup: false

            hideOnWindowDeactivate: !Plasmoid.configuration.pin
            visible: systemTrayState.expanded
            appletInterface: root

            backgroundHints: root.compositionEnabled ? PlasmaCore.Dialog.SolidBackground : PlasmaCore.Dialog.NoBackground

            onWidthChanged: setDialogPosition();
            onHeightChanged: setDialogPosition();
            function setDialogPosition() {
                var pos = root.mapToGlobal(root.x, root.y);
                pos = root.mapToGlobal(currentHighlight.x, currentHighlight.y);
                var availScreen = Plasmoid.containment.availableScreenRect;
                var screen = root.screenGeometry;

                x = pos.x - width / 2 + (currentHighlight.width / 2);
                y = pos.y - height + 1 - flyoutMargin;

                if(x <= 0) x += flyoutMargin;
                if((x + dialog.width - screen.x) >= availScreen.width) {
                    x = screen.x + availScreen.width - dialog.width - flyoutMargin;

                }
                if(y <= 0) y += flyoutMargin;
                if((y + dialog.height - screen.y) >= availScreen.height) {
                    y = screen.y + availScreen.height - dialog.height - flyoutMargin;
                }
                /*if(root.vertical) {
                    if(pos.x > dialog.x) dialog.x -= flyoutMargin;
                    else dialog.x += flyoutMargin;
                } else {
                    if(pos.y > dialog.y) dialog.y -= flyoutMargin;
                    else dialog.y += flyoutMargin;
                }*/
            }
            onYChanged: {
                if(!firstTimePopup) { setDialogPosition(); }
                firstTimePopup = true;
            }
            onVisibleChanged: {
                if(visible) {
                    setDialogPosition();
                }
                if (!visible) {
                    expandedSync.restart();
                } else {
                    if (expandedRepresentation.plasmoidContainer.visible) {
                        expandedRepresentation.plasmoidContainer.forceActiveFocus();
                    }
                }
            }
            mainItem: ExpandedRepresentation {
                id: expandedRepresentation

                Keys.onEscapePressed: {
                    systemTrayState.expanded = false
                }

                LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
                LayoutMirroring.childrenInherit: true
            }
        }
    }

    // I hate this.
    Timer {
        id: systemIconsFix
        interval: 35
        onTriggered: {
            Plasmoid.configuration.networkEnabled = !Plasmoid.configuration.networkEnabled;
        }
    }

    Component.onCompleted: {
        Plasmoid.configuration.networkEnabled = !Plasmoid.configuration.networkEnabled;
        systemIconsFix.start();
    }
}
