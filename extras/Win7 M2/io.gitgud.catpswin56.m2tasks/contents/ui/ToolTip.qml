import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.ksvg as KSvg
import org.kde.plasma.private.mpris as Mpris

import org.kde.kquickcontrolsaddons
import org.kde.kwindowsystem

PlasmaCore.Dialog {
    id: tooltip

    signal bindingsUpdated()

    readonly property Mpris.PlayerContainer playerData: mpris2Source.playerForLauncherUrl(launcherUrl, pidParent)

    property QtObject parentTask

    property string display: "undefined"
    property var icon: "undefined"
    property bool active: false
    property bool pinned: false
    property bool minimized: false
    property bool startup: false
    property var windows
    property bool taskHovered: false
    property var modelIndex
    property var taskIndex
    property int pidParent
    property url launcherUrl
    property int childCount
    property bool dragDrop: false

    property int xpos: -1
    property int taskWidth: 0
    property int taskHeight: 0
    property int taskX: 0
    property int taskY: 0

    property bool shouldDisplayToolTip: {
        if(!Plasmoid.configuration.showPreviews) return true
        else {
            if(pinned) return true
            if(startup) return true
            if(!compositionEnabled && childCount == 0) return true
            return false
        }
    }
    property bool firstCreation: false
    property bool compositionEnabled: tasks.compositionEnabled

    onTaskXChanged: {
        correctScreenLocation();
    }

    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Dock // for blur region and animation to work properly
    flags: Qt.WindowDoesNotAcceptFocus | Qt.ToolTip
    location: "Floating"
    title: "seventasks-tooltip"
    objectName: "tooltipWindow"

    function correctScreenLocation() { // FIXME: completely breaks under wayland for whatever reason.
        var globalPos = parent.mapToGlobal(tasks.x, tasks.y);
        var yPadding = !tooltip.shouldDisplayToolTip && compositionEnabled ? (Kirigami.Units.smallSpacing*2 - Kirigami.Units.smallSpacing/2) : 0;

        tooltip.y = globalPos.y - tooltip.height - yPadding


        var parentPos = parent.mapToGlobal(taskX, taskY);
        var xPadding = tooltip.mainItem != "windowThumbnail" ? Kirigami.Units.smallSpacing/2 : 0;
        var firstCreationPadding = tooltip.firstCreation ? Kirigami.Units.smallSpacing/2 : 0;

        xpos = parentPos.x + taskWidth / 2;
        tooltip.x = parentPos.x + taskWidth / 2;
        xpos = parentPos.x +  taskWidth / 2 + 1;
        xpos -= tooltip.width / 2 - xPadding + firstCreationPadding;

        if(xpos <= 0) {
            xpos = Kirigami.Units.largeSpacing;
            tooltip.x = Kirigami.Units.largeSpacing;
        }
        tooltip.x = xpos;
    }

    function refreshBlur() { // FIXME: also breaks under wayland
        if(mainItem == windowThumbnail) Plasmoid.setDashWindow(tooltip, windowThumbnailBg.mask, windowThumbnailBg.imagePath);
        if(mainItem == groupThumbnails) Plasmoid.setDashWindow(tooltip, groupThumbnailsBg.mask, groupThumbnailsBg.imagePath);
    }

    opacity: 0

    onOpacityChanged: {
        if(opacity == 0) refreshBlur();
    }
    onMainItemChanged: {
        refreshBlur();
    }

    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }

    onVisibleChanged: {
        correctScreenLocation();
    }

    Behavior on x {
        NumberAnimation { duration: !shouldDisplayToolTip && !firstCreation && compositionEnabled ? 185 : 0 }
    }

    Behavior on y { // FIXME: open animation kinda weird with the first task item
        NumberAnimation { duration: !shouldDisplayToolTip && compositionEnabled ? (firstCreation ? 300 : 185) : 1 } // I don't know why setting value for pinned app
    }                                                                                                               // tooltips to 1 fixes a really bad y offset issue, but
                                                                                                                    // it does.

    onWidthChanged: {
        correctScreenLocation();
        refreshBlur();
    }
    onHeightChanged: {
        correctScreenLocation();
        refreshBlur();
    }

    mainItem: shouldDisplayToolTip ? pinnedToolTip : (childCount > 1 ? groupThumbnails : windowThumbnail)
}
