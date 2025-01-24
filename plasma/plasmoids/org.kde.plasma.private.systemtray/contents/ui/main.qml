/*
 *    SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
 *    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>
 *
 *    SPDX-License-Identifier: LGPL-2.0-or-later
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

    Layout.minimumWidth: vertical ? Kirigami.Units.iconSizes.small : mainLayout.implicitWidth + Kirigami.Units.largeSpacing+1
    Layout.minimumHeight: vertical ? mainLayout.implicitHeight + Kirigami.Units.smallSpacing : Kirigami.Units.iconSizes.small

    LayoutMirroring.enabled: !vertical && Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    readonly property alias tasksGrid: tasksGrid
    readonly property alias activeModel: activeModel
    readonly property alias systemTrayState: systemTrayState
    readonly property alias itemSize: tasksGrid.itemSize
    readonly property alias visibleLayout: tasksGrid
    readonly property alias hiddenLayout: expandedRepresentation.hiddenLayout
    readonly property bool oneRowOrColumn: tasksGrid.rowsOrColumns === 1

    property bool showHidden: false

    // Milestone 2 mode settings
    property bool milestone2Mode: {
        let item = this;
        while (item.parent) {
            item = item.parent;
            if (item.milestone2Mode !== undefined) {
                return item.milestone2Mode
            }
        }
    }

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

            visible: true
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
             *                saveConfiguration();
        }*/
        }
        Item {
            id: hiddenOrderingManager
            property var orderObject: {}

            function saveConfiguration() {
                for(var i = 0; i < passiveModel.items.count; i++) {
                    var item = passiveModel.items.get(i);
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
             *       saveConfiguration();
        }*/
        }
        Item {
            id: systemOrderingManager
            property var orderObject: {}

            function saveConfiguration() {
                for(var i = 0; i < systemModel.items.count; i++) {
                    var item = systemModel.items.get(i);
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
        }

        KItemModels.KSortFilterProxyModel {
            id: nonFilteredActiveModel
            sourceModel: Plasmoid.systemTrayModel
            filterRoleName: "effectiveStatus"
            filterRowCallback: (sourceRow, sourceParent) => {
                let value = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole);
                return value == PlasmaCore.Types.ActiveStatus;
            }
        }

        KItemModels.KSortFilterProxyModel {
            id: filteredActiveModel
            sourceModel: Plasmoid.systemTrayModel
            filterRoleName: "effectiveStatus"
            function filterItemId(itemId) {
                return !root.milestone2Mode && (itemId == "org.kde.plasma.battery" || itemId == "org.kde.plasma.networkmanagement" || itemId == "io.gitgud.catpswin56.volumemixer")
            }
            filterRowCallback: (sourceRow, sourceParent) => {
                let value = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole);
                var itemIdRole = KItemModels.KRoleNames.role("itemId");
                let value2 = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), itemIdRole);
                return (value == PlasmaCore.Types.ActiveStatus && !filterItemId(value2));
            }
        }

        DelegateModel {
            id: activeModel
            model: root.milestone2Mode ? nonFilteredActiveModel : filteredActiveModel
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
                    //var shouldInsert = item.model.itemId !== "" || (typeof item.model.hasApplet !== "undefined");
                    var i = determinePosition(item); //orderingManager.getItemOrder(item.model.itemId);
                    item.groups = "items";
                    items.move(item.itemsIndex, i);
                }
            }
            items.includeByDefault: false
            groups: DelegateModelGroup {
                id: unsortedItems
                name: "unsorted"

                includeByDefault: true
                onChanged: {
                    activeModel.sort();
                }
            }
            delegate: ItemLoader {
                id: delegate
                width: tasksGrid.cellWidth
                height: tasksGrid.cellHeight
                property int visualIndex: DelegateModel.itemsIndex
                minLabelHeight: 0
                // We need to recalculate the stacking order of the z values due to how keyboard navigation works
                // the tab order depends exclusively from this, so we redo it as the position in the list
                // ensuring tab navigation focuses the expected items
                Component.onCompleted: {
                    let item = tasksGrid.itemAtIndex(index - 1);
                    if (item) {
                        Plasmoid.stackItemBefore(delegate, item)
                    } else {
                        item = tasksGrid.itemAtIndex(index + 1);
                    }
                    if (item) {
                        Plasmoid.stackItemAfter(delegate, item)
                    }
                }
            }
        }
        DelegateModel {
            id: passiveModel
            model: KItemModels.KSortFilterProxyModel {
                sourceModel: Plasmoid.systemTrayModel
                filterRoleName: "effectiveStatus"
                function filterItemId(itemId) {
                    if(root.milestone2Mode) return false
                    else return itemId == "org.kde.plasma.battery" || itemId == "org.kde.plasma.networkmanagement" || itemId == "io.gitgud.catpswin56.volumemixer"
                }
                filterRowCallback: (sourceRow, sourceParent) => {
                    let value = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole);
                    var itemIdRole = KItemModels.KRoleNames.role("itemId");
                    let value2 = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), itemIdRole);
                    return (value == PlasmaCore.Types.PassiveStatus && !filterItemId(value2));
                }
            }
            function determinePosition(item) {
                let lower = 0;
                let upper = items.count
                while(lower < upper) {
                    const middle = Math.floor(lower + (upper - lower) / 2)
                    var middleItem = items.get(middle);

                    var first = hiddenOrderingManager.getItemOrder(item.model.itemId);
                    var second = hiddenOrderingManager.getItemOrder(middleItem.model.itemId);

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
                while(hiddenUnsortedItems.count > 0) {
                    const item = hiddenUnsortedItems.get(0);
                    //var shouldInsert = item.model.itemId !== "" || (typeof item.model.hasApplet !== "undefined");
                    var i = determinePosition(item); //orderingManager.getItemOrder(item.model.itemId);
                    item.groups = "items";
                    items.move(item.itemsIndex, i);
                }
            }
            items.includeByDefault: false
            groups: DelegateModelGroup {
                id: hiddenUnsortedItems
                name: "unsorted"

                includeByDefault: true
                onChanged: {
                    passiveModel.sort();
                }
            }
            delegate: ItemLoader {
                id: hiddenDelegate
                width: hiddenTasksGrid.cellWidth
                height: hiddenTasksGrid.cellHeight
                property int visualIndex: DelegateModel.itemsIndex
                minLabelHeight: 0
                // We need to recalculate the stacking order of the z values due to how keyboard navigation works
                // the tab order depends exclusively from this, so we redo it as the position in the list
                // ensuring tab navigation focuses the expected items
                Component.onCompleted: {
                    let item = hiddenTasksGrid.itemAtIndex(index - 1);
                    if (item) {
                        Plasmoid.stackItemBefore(delegate, item)
                    } else {
                        item = hiddenTasksGrid.itemAtIndex(index + 1);
                    }
                    if (item) {
                        Plasmoid.stackItemAfter(delegate, item)
                    }
                }
            }
        }
        DelegateModel {
            id: systemModel
            model: KItemModels.KSortFilterProxyModel {
                sourceModel: Plasmoid.systemTrayModel
                filterRoleName: "itemId"
                function isEnabled(item) {
                    switch (item) {
                        case ("org.kde.plasma.battery"):
                            return Plasmoid.configuration.batteryEnabled;
                            break;
                        case ("org.kde.plasma.networkmanagement"):
                            return Plasmoid.configuration.networkEnabled;
                            break;
                        case ("io.gitgud.catpswin56.volumemixer"):
                            return Plasmoid.configuration.volumeEnabled;
                            break;
                    }
                }
                filterRowCallback: (sourceRow, sourceParent) => {
                    let value = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), filterRole);
                    return isEnabled(value);
                }
            }
            function determinePosition(item) {
                let lower = 0;
                let upper = items.count
                while(lower < upper) {
                    const middle = Math.floor(lower + (upper - lower) / 2)
                    var middleItem = items.get(middle);

                    var first = systemOrderingManager.getItemOrder(item.model.itemId);
                    var second = systemOrderingManager.getItemOrder(middleItem.model.itemId);

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
                while(systemUnsortedItems.count > 0) {
                    const item = systemUnsortedItems.get(0);
                    //var shouldInsert = item.model.itemId !== "" || (typeof item.model.hasApplet !== "undefined");
                    var i = determinePosition(item); //orderingManager.getItemOrder(item.model.itemId);
                    item.groups = "items";
                    items.move(item.itemsIndex, i);
                }
            }
            items.includeByDefault: false
            groups: DelegateModelGroup {
                id: systemUnsortedItems
                name: "unsorted"

                includeByDefault: true
                onChanged: {
                    systemModel.sort();
                }
            }
            delegate: ItemLoader {
                id: systemDelegate
                width: systemIconsGrid.cellWidth
                height: systemIconsGrid.cellHeight
                property int visualIndex: DelegateModel.itemsIndex
                minLabelHeight: 0
                // We need to recalculate the stacking order of the z values due to how keyboard navigation works
                // the tab order depends exclusively from this, so we redo it as the position in the list
                // ensuring tab navigation focuses the expected items
                Component.onCompleted: {
                    let item = systemIconsGrid.itemAtIndex(index - 1);
                    if (item) {
                        Plasmoid.stackItemBefore(delegate, item)
                    } else {
                        item = systemIconsGrid.itemAtIndex(index + 1);
                    }
                    if (item) {
                        Plasmoid.stackItemAfter(delegate, item)
                    }
                }
            }
        }

        //Main Layout
        GridLayout {
            id: mainLayout

            rowSpacing: 0
            columnSpacing: 0
            anchors.fill: parent
            anchors.topMargin: root.milestone2Mode ? 0
                                                   : (Plasmoid.configuration.offsetIcons ? -Kirigami.Units.smallSpacing*2 + Kirigami.Units.smallSpacing/2 - Kirigami.Units.smallSpacing/4 : 0)

            flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight

            ExpanderArrow {
                id: expander
                Layout.alignment: vertical ? Qt.AlignVCenter : Qt.AlignHCenter
                Layout.topMargin: !vertical ? (Plasmoid.configuration.offsetIcons ? Kirigami.Units.smallSpacing*2 : 0) : 0
                Layout.rightMargin: -Kirigami.Units.smallSpacing/2
                visible: root.hiddenLayout.itemCount > 0 && !root.milestone2Mode
            }
            ExpanderArrowM2 {
                id: expanderM2
                Layout.alignment: vertical ? Qt.AlignVCenter : Qt.AlignHCenter
                Layout.topMargin: !vertical ? 1 : 0
                visible: root.hiddenLayout.itemCount > 0 && root.milestone2Mode
            }
            GridView { // hidden icons
                id: hiddenTasksGrid

                Layout.alignment: Qt.AlignCenter

                interactive: false //disable features we don't need
                flow: vertical ? GridView.LeftToRight : GridView.TopToBottom

                // The icon size to display when not using the auto-scaling setting
                readonly property int smallIconSize: Kirigami.Units.iconSizes.small

                // Automatically use autoSize setting when in tablet mode, if it's
                // not already being used
                readonly property bool autoSize: Plasmoid.configuration.scaleIconsToFit || Kirigami.Settings.tabletMode

                readonly property int gridThickness: root.vertical ? root.width : root.height
                // Should change to 2 rows/columns on a 56px panel (in standard DPI)
                readonly property int rowsOrColumns: 1

                // Add margins only if the panel is larger than a small icon (to avoid large gaps between tiny icons)
                readonly property int cellSpacing: Kirigami.Units.smallSpacing/2
                readonly property int smallSizeCellLength: gridThickness < smallIconSize ? smallIconSize : smallIconSize + cellSpacing

                cellHeight: {
                    if (root.vertical) {
                        return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
                    } else {
                        return autoSize ? root.height : Math.floor(root.height / rowsOrColumns)
                    }
                }
                cellWidth: {
                    if (root.vertical) {
                        return autoSize ? root.width : Math.floor(root.width / rowsOrColumns)
                    } else {
                        return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
                    }
                }

                //depending on the form factor, we are calculating only one dimension, second is always the same as root/parent
                implicitHeight: root.vertical ? cellHeight * Math.ceil(count / rowsOrColumns) : root.height
                implicitWidth: !root.vertical ? (showHidden ? cellWidth * Math.ceil(count / rowsOrColumns) : 0) : root.width

                Behavior on implicitWidth {
                    NumberAnimation { duration: 150 }
                }

                readonly property int itemSize: {
                    if (autoSize) {
                        return Kirigami.Units.iconSizes.roundedIconSize(Math.min(Math.min(root.width, root.height) / rowsOrColumns, Kirigami.Units.iconSizes.enormous))
                    } else {
                        return smallIconSize
                    }
                }

                model: root.milestone2Mode ? undefined : passiveModel

                visible: implicitWidth == 0 ? false : true

                MouseArea {
                    id: hiddenMa

                    anchors.fill: parent

                    hoverEnabled: true
                    propagateComposedEvents: true
                }
            }
            GridView { // non-hidden icons (active)
                id: tasksGrid

                Layout.alignment: Qt.AlignCenter

                interactive: false //disable features we don't need
                flow: vertical ? GridView.LeftToRight : GridView.TopToBottom

                // The icon size to display when not using the auto-scaling setting
                readonly property int smallIconSize: Kirigami.Units.iconSizes.small

                // Automatically use autoSize setting when in tablet mode, if it's
                // not already being used
                readonly property bool autoSize: Plasmoid.configuration.scaleIconsToFit || Kirigami.Settings.tabletMode

                readonly property int gridThickness: root.vertical ? root.width : root.height
                // Should change to 2 rows/columns on a 56px panel (in standard DPI)
                readonly property int rowsOrColumns: 1

                // Add margins only if the panel is larger than a small icon (to avoid large gaps between tiny icons)
                readonly property int cellSpacing: Kirigami.Units.smallSpacing/2
                readonly property int smallSizeCellLength: gridThickness < smallIconSize ? smallIconSize : smallIconSize + cellSpacing

                cellHeight: {
                    if (root.vertical) {
                        return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
                    } else {
                        return autoSize ? root.height : Math.floor(root.height / rowsOrColumns)
                    }
                }
                cellWidth: {
                    if (root.vertical) {
                        return autoSize ? root.width : Math.floor(root.width / rowsOrColumns)
                    } else {
                        return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
                    }
                }

                //depending on the form factor, we are calculating only one dimension, second is always the same as root/parent
                implicitHeight: root.vertical ? cellHeight * Math.ceil(count / rowsOrColumns) : root.height
                implicitWidth: !root.vertical ? cellWidth * Math.ceil(count / rowsOrColumns) : root.width

                readonly property int itemSize: {
                    if (autoSize) {
                        return Kirigami.Units.iconSizes.roundedIconSize(Math.min(Math.min(root.width, root.height) / rowsOrColumns, Kirigami.Units.iconSizes.enormous))
                    } else {
                        return smallIconSize
                    }
                }

                model: activeModel
            }
            Item {
                id: trayGap
                Layout.preferredWidth: !vertical ? Plasmoid.configuration.trayGapSize : 0
                Layout.preferredHeight: vertical ? Plasmoid.configuration.trayGapSize : 0

                visible: !root.milestone2Mode && systemIconsGrid.count > 0 && tasksGrid.count > 0
            }
            GridView { // system icons
                id: systemIconsGrid

                Layout.alignment: Qt.AlignCenter

                interactive: false //disable features we don't need
                flow: vertical ? GridView.LeftToRight : GridView.TopToBottom

                // The icon size to display when not using the auto-scaling setting
                readonly property int smallIconSize: Kirigami.Units.iconSizes.small

                // Automatically use autoSize setting when in tablet mode, if it's
                // not already being used
                readonly property bool autoSize: Plasmoid.configuration.scaleIconsToFit || Kirigami.Settings.tabletMode

                readonly property int gridThickness: root.vertical ? root.width : root.height
                // Should change to 2 rows/columns on a 56px panel (in standard DPI)
                readonly property int rowsOrColumns: 1

                // Add margins only if the panel is larger than a small icon (to avoid large gaps between tiny icons)
                readonly property int cellSpacing: Kirigami.Units.smallSpacing/2
                readonly property int smallSizeCellLength: gridThickness < smallIconSize ? smallIconSize : smallIconSize + cellSpacing

                cellHeight: {
                    if (root.vertical) {
                        return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
                    } else {
                        return autoSize ? root.height : Math.floor(root.height / rowsOrColumns)
                    }
                }
                cellWidth: {
                    if (root.vertical) {
                        return autoSize ? root.width : Math.floor(root.width / rowsOrColumns)
                    } else {
                        return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
                    }
                }

                //depending on the form factor, we are calculating only one dimension, second is always the same as root/parent
                implicitHeight: root.vertical ? cellHeight * Math.ceil(count / rowsOrColumns) : root.height
                implicitWidth: !root.vertical ? cellWidth * Math.ceil(count / rowsOrColumns) : root.width

                readonly property int itemSize: {
                    if (autoSize) {
                        return Kirigami.Units.iconSizes.roundedIconSize(Math.min(Math.min(root.width, root.height) / rowsOrColumns, Kirigami.Units.iconSizes.enormous))
                    } else {
                        return smallIconSize
                    }
                }

                model: systemModel

                visible: !root.milestone2Mode
            }
        }

        Timer {
            id: autoClose
            running: root.showHidden && !hiddenMa.containsMouse
            interval: 3000
            onTriggered: root.showHidden = false;
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

            backgroundHints: PlasmaCore.Dialog.SolidBackground

            onWidthChanged: setDialogPosition();
            onHeightChanged: setDialogPosition();
            function setDialogPosition() {
                var pos = root.mapToGlobal(root.x, root.y);
                pos = root.mapToGlobal(currentHighlight.x, currentHighlight.y);
                var availScreen = Plasmoid.containment.availableScreenRect;
                var screen = root.screenGeometry;

                x = pos.x - width / 2 + (expandedRepresentation.hiddenLayout.visible && root.milestone2Mode ? flyoutMargin + Kirigami.Units.smallSpacing/2 : currentHighlight.width / 2);
                y = pos.y - height + Kirigami.Units.smallSpacing*4;

                if(x <= 0) x += flyoutMargin;
                if((x + dialog.width - screen.x) >= availScreen.width) {
                    x = screen.x + availScreen.width - dialog.width;

                }
                if(y <= 0) y += flyoutMargin;
                if((y + dialog.height - screen.y) >= availScreen.height) {
                    y = screen.y + availScreen.height - dialog.height;
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
                    } else if (expandedRepresentation.hiddenLayout.visible) {
                        expandedRepresentation.hiddenLayout.forceActiveFocus();
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
}
