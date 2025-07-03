import QtQuick
import QtQml.Models

import org.kde.plasma.plasmoid
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.core as PlasmaCore

import "../items"


DelegateModel {
    id: delegateModel

    required property Item orderingManager

    model: KItemModels.KSortFilterProxyModel {
        sourceModel: Plasmoid.systemTrayModel
        filterRoleName: "itemId"
        function isEnabled(item) {
            switch (item) {
                case ("io.gitgud.catpswin56.battery"):
                    return Plasmoid.configuration.batteryEnabled;
                    break;
                case ("io.gitgud.catpswin56.networkmanagement"):
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
            delegateModel.sort();
        }
    }
    delegate: ItemLoader {
        id: delegate
        width: root.systemIconsGrid.cellWidth
        height: root.systemIconsGrid.cellHeight
        modelStr: "system"
        property int visualIndex: DelegateModel.itemsIndex
        // We need to recalculate the stacking order of the z values due to how keyboard navigation works
        // the tab order depends exclusively from this, so we redo it as the position in the list
        // ensuring tab navigation focuses the expected items
        Component.onCompleted: {
            let item = root.systemIconsGrid.itemAtIndex(index - 1);
            if (item) {
                Plasmoid.stackItemBefore(delegate, item)
            } else {
                item = root.systemIconsGrid.itemAtIndex(index + 1);
            }
            if (item) {
                Plasmoid.stackItemAfter(delegate, item)
            }
        }
    }
}
