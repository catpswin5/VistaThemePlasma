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
import org.kde.kitemmodels as KItemModels

import "items"

ContainmentItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: vertical ? itemSize : mainLayout.implicitWidth
    Layout.minimumHeight: vertical ? mainLayout.implicitHeight : itemSize

    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    LayoutMirroring.enabled: !vertical && Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    readonly property alias tasksGrid: tasksGrid
    readonly property alias tasksRepeater: tasksGrid.repeater

    readonly property alias systemTasksGrid: systemTasksGrid
    readonly property alias systemTasksRepeater: systemTasksGrid.repeater

    readonly property alias activeModel: activeModel
    readonly property alias systemTrayState: systemTrayState
    readonly property int itemSize: {
        if (Plasmoid.configuration.scaleIconsToFit || Kirigami.Settings.tabletMode) {
            return Kirigami.Units.iconSizes.roundedIconSize(Math.min(Math.min(root.width, root.height), Kirigami.Units.iconSizes.enormous))
        } else {
            return Kirigami.Units.iconSizes.small
        }
    }
    readonly property alias visibleLayout: tasksGrid

    property bool hiddenItemsVisible: false

    KSvg.Svg {
        id: buttonIcons
        imagePath: Qt.resolvedUrl("svgs/icons.svg");
    }
    KSvg.FrameSvgItem {
        id : dialogSvg
        visible: false
        imagePath: "solid/dialogs/background"
    }
    MouseArea {
        id: representationItem

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
                if(dialog.visible) dialog.setDialogPosition();
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

        Item {
            id: orderingManager
            property var orderObject: {}

            function saveConfiguration() {
                for(var i = 0; i < activeModel.items.count; i++) {
                    var item = activeModel.items.get(i);
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
                Plasmoid.configuration.itemOrdering = JSON.stringify(orderObject);
                Plasmoid.configuration.writeConfig();
            }

            Component.onCompleted: {
                var list = Plasmoid.configuration.itemOrdering;
                if(list !== "")
                    orderObject = JSON.parse(list);

                if(typeof orderObject === "undefined")
                    orderObject = {};
            }
            /*Component.onDestruction: {
                saveConfiguration();
            }*/
        }

        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                shownItemsModel.invalidateFilter();
            }
        }

        DelegateModel {
            id: activeModel

            property int unsortedCount: unsortedItems.count
            property int sortedCount: items.count
            property var hiddenIndexes: []

            signal sortingComplete()
            onSortingComplete: {
                hiddenIndexes = [];
                for(var i = 0; i < items.count; i++) {
                    const item = items.get(i);
                    if(item.model.effectiveStatus === PlasmaCore.Types.PassiveStatus) hiddenIndexes.push(item.itemsIndex);
                }
                expander.visible = activeModel.hiddenIndexes.length > 0;
            }

            model: KItemModels.KSortFilterProxyModel {
                id: shownItemsModel

                function filterItemId(itemId) {
                    return itemId == "io.gitgud.catpswin56.battery" || itemId == "io.gitgud.catpswin56.networkmanagement" || itemId == "io.gitgud.catpswin56.volumemixer"
                }

                sourceModel: Plasmoid.systemTrayModel
                filterRoleName: "effectiveStatus"

                filterRowCallback: (sourceRow, sourceParent) => {
                    let value = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole);

                    var itemIdRole = KItemModels.KRoleNames.role("itemId");
                    let value2 = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), itemIdRole);

                    return (value === PlasmaCore.Types.PassiveStatus || value === PlasmaCore.Types.ActiveStatus) && !filterItemId(value2);
                }
            }

            items.includeByDefault: false
            groups: DelegateModelGroup {
                id: unsortedItems

                name: "unsorted"
                includeByDefault: true

                onChanged: (removed, inserted) => {
                    activeModel.sort();
                    if(activeModel.count != shownItemsModel.count) {
                        shownItemsModel.invalidateFilter();
                    }
                }
            }

            delegate: ItemLoader {
                id: delegate

                visualIndex: DelegateModel.itemsIndex

                visible: !DelegateModel.isUnresolved

                // We need to recalculate the stacking order of the z values due to how keyboard navigation works
                // the tab order depends exclusively from this, so we redo it as the position in the list
                // ensuring tab navigation focuses the expected items
                Component.onCompleted: {
                    let item = tasksGrid.repeater.itemAt(index - 1);
                    if (item) {
                        Plasmoid.stackItemBefore(delegate, item)
                    } else {
                        item = tasksGrid.repeater.itemAt(index + 1);
                    }
                    if (item) {
                        Plasmoid.stackItemAfter(delegate, item)
                    }
                }
            }

            function determinePosition(item) {
                let lower = 0;
                let upper = items.count
                while(lower < upper) {
                    const middle = Math.floor(lower + (upper - lower) / 2)
                    var middleItem = items.get(middle);

                    var first = orderingManager.getItemOrder(item.model.itemId);
                    var second = orderingManager.getItemOrder(middleItem.model.itemId);

                    const result = first < second;
                    if(result) {
                        upper = middle;
                    } else {
                        lower = middle + 1;
                    }
                }
                return lower;
            }

            function sort() {
                while(unsortedItems.count > 0) {
                    const item = unsortedItems.get(0);

                    var i = determinePosition(item);
                    item.groups =  "items";
                    items.move(item.itemsIndex, i);
                }
                sortingComplete();
            }
        }
        // Main Layout

        GridLayout {
            id: mainLayout

            anchors.fill: parent
            anchors.topMargin: !Plasmoid.configuration.dontOffset
                             ? -Kirigami.Units.smallSpacing*2 + Kirigami.Units.smallSpacing/2 - Kirigami.Units.smallSpacing/4
                             : 0

            rowSpacing: 0
            columnSpacing: 0
            flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight

            ExpanderArrow {
                id: expander

                Layout.topMargin: !vertical ? (!Plasmoid.configuration.dontOffset ? Kirigami.Units.smallSpacing*2 : 0) : 0
                Layout.rightMargin: -Kirigami.Units.smallSpacing/2

                visible: activeModel.hiddenIndexes.length > 0
            }

            ItemsGrid {
                id: tasksGrid

                Layout.alignment: Qt.AlignCenter

                Layout.minimumWidth: root.vertical ? root.itemSize : implicitWidth
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: root.vertical ? implicitHeight : root.itemSize
                Layout.maximumHeight: Layout.minimumHeight

                root: root
                model: activeModel
            }

            Item {
                Layout.preferredWidth: vertical ? 0 : Plasmoid.configuration.gapSize
                Layout.preferredHeight: vertical ? Plasmoid.configuration.gapSize : 0

                visible: systemTasksGrid.visible && tasksGrid.visible
            }

            ItemsGrid {
                id: systemTasksGrid

                Layout.alignment: Qt.AlignCenter

                Layout.minimumWidth: root.vertical ? root.itemSize : implicitWidth
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: root.vertical ? implicitHeight : root.itemSize
                Layout.maximumHeight: Layout.minimumHeight

                root: root
                model: DelegateModel {
                    id: systemModel

                    model: KItemModels.KSortFilterProxyModel {
                        id: shownSystemItemsModel

                        function filterItemId(itemId) {
                            return (itemId == "io.gitgud.catpswin56.battery" && Plasmoid.configuration.batteryEnabled)
                                || (itemId == "io.gitgud.catpswin56.networkmanagement" && Plasmoid.configuration.networkEnabled)
                                || (itemId == "io.gitgud.catpswin56.volumemixer" && Plasmoid.configuration.soundEnabled)
                        }

                        sourceModel: Plasmoid.systemTrayModel
                        filterRoleName: "effectiveStatus"

                        filterRowCallback: (sourceRow, sourceParent) => {
                            let value = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole);

                            var itemIdRole = KItemModels.KRoleNames.role("itemId");
                            let value2 = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), itemIdRole);

                            return (value === PlasmaCore.Types.PassiveStatus || value === PlasmaCore.Types.ActiveStatus) && filterItemId(value2);
                        }
                    }

                    items.includeByDefault: false
                    groups: DelegateModelGroup {
                        id: unsortedSystemItems

                        name: "unsorted"
                        includeByDefault: true

                        onChanged: (removed, inserted) => {
                            systemModel.sort();
                            if(systemModel.count != shownSystemItemsModel.count) {
                                shownSystemItemsModel.invalidateFilter();
                            }
                        }
                    }

                    delegate: ItemLoader {  }

                    function sort() {
                        while(unsortedSystemItems.count > 0) {
                            const item = unsortedSystemItems.get(0);

                            item.groups = "items";

                            if(item.itemId == "io.gitgud.catpswin56.battery")
                                items.move(0, 0);

                            if(item.itemId == "io.gitgud.catpswin56.networkmanagement")
                                items.move(1, 1);

                            if(item.itemId == "io.gitgud.catpswin56.volumemixer")
                                items.move(2, 2);
                        }
                    }
                }

                visible: repeater.count !== 0
            }
        }

        Timer {
            id: hideTimer
            interval: 4000
            running: root.hiddenItemsVisible
            onTriggered: root.hiddenItemsVisible = false;
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
            property int flyoutMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing/2
            property bool firstTimePopup: false

            hideOnWindowDeactivate: !Plasmoid.configuration.pin
            visible: systemTrayState.expanded
            appletInterface: root

            backgroundHints: expandedRepresentation.useTransparentFlyout ? PlasmaCore.Dialog.StandardBackground : PlasmaCore.Dialog.SolidBackground

            onWidthChanged: setDialogPosition();
            onHeightChanged: setDialogPosition();

            function setDialogPosition() {
                var rootPos = root.mapToGlobal(root.x, root.y);
                var pos;
                var availScreen = Plasmoid.containment.availableScreenRect;
                var screen = root.screenGeometry;
                var availableScreenGeometry = Qt.rect(availScreen.x + screen.x, availScreen.y + screen.y, availScreen.width, availScreen.height);

                if(Plasmoid.location === PlasmaCore.Types.BottomEdge) {
                    pos = root.mapToGlobal(currentHighlight.x, root.y);

                    x = pos.x - width / 2 + currentHighlight.width / 2;
                    y = pos.y - height;

                } else if(Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                    pos = root.mapToGlobal(root.x + root.width, currentHighlight.y);

                    y = pos.y - height / 2;
                    x = rootPos.x + root.width;

                } else if(Plasmoid.location === PlasmaCore.Types.RightEdge) {
                    pos = root.mapToGlobal(root.x, currentHighlight.y);

                    y = pos.y - height / 2;
                    x = rootPos.x - width;

                } else if(Plasmoid.location === PlasmaCore.Types.TopEdge) {
                    pos = root.mapToGlobal(currentHighlight.x, root.y + root.height);

                    x = pos.x - width / 2 + currentHighlight.width / 2;
                    y = rootPos.y + root.height;
                }

                if(x < availableScreenGeometry.x) x = availableScreenGeometry.x;
                if(x + dialog.width >= availableScreenGeometry.x + availScreen.width) {
                    x = availableScreenGeometry.x + availScreen.width - dialog.width;
                }

                if(y < availableScreenGeometry.y) y = availableScreenGeometry.y;
                if(y + dialog.height >= availableScreenGeometry.y + availScreen.height) {
                    y = availableScreenGeometry.y + availScreen.height - dialog.height;
                }
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

                Timer {
                    running: dialog.visible
                    interval: 200
                    repeat: true
                    onTriggered: dialog.raise();
                }
            }
        }
    }
}
