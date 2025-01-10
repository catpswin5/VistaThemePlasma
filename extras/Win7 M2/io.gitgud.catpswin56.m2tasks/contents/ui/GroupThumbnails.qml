import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid as Plasmoid
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore

MouseArea {
    id: groupThumbnails

    property QtObject root
    property bool isList: thumbnailModel.count >= 8
    property bool compositionEnabled: root.compositionEnabled
    property int thumbnailWidth: { // TODO: simplify these calculations idk
        if(!isList) {
            return (189 * thumbnailList.count) - ((Kirigami.Units.smallSpacing * 4) * (thumbnailList.count - 1))
        } else if(isList) {
            return 189 + (compositionEnabled ? 0 : Kirigami.Units.smallSpacing)// there's not really any way for me to access header's realWidth property from here sooo
        }
    }
    property int thumbnailHeight: {
        if(!isList) {
            return 142 + (root.playerData != null ? (24 - Kirigami.Units.smallSpacing*2) : 0)
        } else if(isList) {
            return ((33 + Kirigami.Units.smallSpacing*4) * thumbnailList.count) - ((Kirigami.Units.smallSpacing * 4) * (thumbnailList.count - 1)) + (compositionEnabled ? Kirigami.Units.smallSpacing*4 : 0)
        }
    }

    width: thumbnailWidth
    height: thumbnailHeight

    Behavior on width { // NOTE: animation too laggy, should it stay anyways? (the other one is in WindowThumbnail.qml)
        NumberAnimation { target: groupThumbnails; property: "width"; from: 189; duration: (root.mainItem != pinnedToolTip && compositionEnabled) ? 185 : 0 }
    }

    hoverEnabled: true
    propagateComposedEvents: true

    visible: root && root.mainItem == groupThumbnails // only visible if tooltip exists and mainItem is set to the correct one

    Timer {
        interval: 200
        running: (!root.taskHovered && !groupThumbnails.containsMouse) && root.mainItem == groupThumbnails // this last one was added because somehow the timer would run on WindowThumbnail too
        onTriggered: {
            root.destroy();
        }
    }

    DelegateModel {
        id: thumbnailModel

        model: tasksModel
        rootIndex: tasksModel.makeModelIndex(root.taskIndex)
        delegate: WindowThumbnail {
            id: thumbnailDelegate

            isGroupDelegate: true
            root: groupThumbnails.root
        }
    }
    DelegateModel {
        id: listModel

        model: tasksModel
        rootIndex: tasksModel.makeModelIndex(root.taskIndex)
        delegate: WindowListDelegate {
            id: listDelegate

            root: groupThumbnails.root
            compositionEnabled: groupThumbnails.compositionEnabled
        }
    }

    ListView {
        id: thumbnailList

        anchors.fill: parent
        anchors.bottomMargin: !isList ? 0 : (compositionEnabled ? Kirigami.Units.smallSpacing*2 : 0)
        anchors.topMargin: !isList ? 0 : (compositionEnabled ? Kirigami.Units.smallSpacing*2 : 0)
        anchors.leftMargin: compositionEnabled ? 0 : Kirigami.Units.smallSpacing
        anchors.rightMargin: compositionEnabled ? 0 : Kirigami.Units.smallSpacing

        interactive: false
        spacing: -Kirigami.Units.smallSpacing*4
        orientation: !isList ? (compositionEnabled ? ListView.Horizontal : ListView.Vertical) : ListView.Vertical

        model: !isList ? (compositionEnabled ? thumbnailModel : listModel) : listModel
    }
}
