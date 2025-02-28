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

    property bool list

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
        if(!Plasmoid.configuration.showPreviews || childCount > 0) return true
        else return false
    }
    property bool firstCreation: false
    property bool compositionEnabled: tasks.compositionEnabled

    onTaskXChanged: correctScreenLocation();

    backgroundHints: PlasmaCore.Types.NoBackground
    type: PlasmaCore.Dialog.Dock // for blur region and animation to work properly
    flags: Qt.WindowDoesNotAcceptFocus
    location: "Floating"
    title: "seventasks-tooltip"
    objectName: "tooltipWindow"

    function correctScreenLocation() { // FIXME: completely breaks under wayland for whatever reason.
        var globalPos = parent.mapToGlobal(tasks.x, tasks.y);
        var yPadding = !tooltip.shouldDisplayToolTip ? (!list ? Kirigami.Units.smallSpacing - 1 : 0) : 0;

        tooltip.y = globalPos.y - tooltip.height - yPadding;


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


    onVisibleChanged: correctScreenLocation();

    onWidthChanged: {
        correctScreenLocation();
        refreshBlur();
    }
    onHeightChanged: {
        correctScreenLocation();
        refreshBlur();
    }

    mainItem: shouldDisplayToolTip && !list ? pinnedToolTip : (list ? groupThumbnails : windowThumbnail)
}
