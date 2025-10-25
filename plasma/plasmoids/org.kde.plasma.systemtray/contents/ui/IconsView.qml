import QtQuick

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

ListView {
    interactive: false //disable features we don't need
    flow: vertical ? ListView.LeftToRight : ListView.TopToBottom

    // The icon size to display when not using the auto-scaling setting
    readonly property int smallIconSize: Kirigami.Units.iconSizes.small

    // Automatically use autoSize setting when in tablet mode, if it's
    // not already being used
    readonly property bool autoSize: Plasmoid.configuration.scaleIconsToFit || Kirigami.Settings.tabletMode

    readonly property int gridThickness: root.vertical ? root.width : root.height
    // Should change to 2 rows/columns on a 56px panel (in standard DPI)
    readonly property int rowsOrColumns: autoSize ? 1 : Math.max(1, Math.min(count, Math.floor(gridThickness / (smallIconSize + Kirigami.Units.smallSpacing))))

    // Add margins only if the panel is larger than a small icon (to avoid large gaps between tiny icons)
    readonly property int cellSpacing: Kirigami.Units.smallSpacing/2
    readonly property int smallSizeCellLength: gridThickness < smallIconSize ? smallIconSize : smallIconSize + cellSpacing

    readonly property int normalWidth: !root.vertical ? cellWidth * Math.ceil(count / rowsOrColumns) : root.width

    property int normalCellHeight: {
        if (root.vertical) {
            return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
        } else {
            return autoSize ? root.height : Math.floor(root.height / rowsOrColumns)
        }
    }
    property int normalCellWidth: {
        if (root.vertical) {
            return autoSize ? root.width : Math.floor(root.width / rowsOrColumns)
        } else {
            return autoSize ? itemSize + (gridThickness < itemSize ? 0 : cellSpacing) : smallSizeCellLength
        }
    }

    cellWidth: normalCellWidth // If I assign directly to cellWidth for whatever reason that causes a plasmashell crash????? Weird.
    cellHeight: normalCellHeight

    //depending on the form factor, we are calculating only one dimension, second is always the same as root/parent
    implicitHeight: root.vertical ? cellHeight * Math.ceil(count / rowsOrColumns) : root.height
    implicitWidth: {
        if(model == root.hiddenModel) {
            if(root.showHidden) return normalWidth;
            else return 0;
        } else return normalWidth;
    }

    readonly property int itemSize: {
        if (autoSize) {
            return Kirigami.Units.iconSizes.roundedIconSize(Math.min(Math.min(root.width, root.height) / rowsOrColumns, Kirigami.Units.iconSizes.enormous))
        } else {
            return smallIconSize
        }
    }

    visible: implicitWidth != 0
}
