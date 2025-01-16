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
    property bool containsDrag: false

    width: 162
    height: (30 * thumbnailList.count) + (Kirigami.Units.smallSpacing * 2) + (2 * (thumbnailList.count - 1))

    hoverEnabled: true
    propagateComposedEvents: true

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
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.leftMargin: 2
        anchors.rightMargin: 3

        interactive: false
        spacing: 2
        orientation: ListView.Vertical

        model: listModel
    }

    visible: root && root.mainItem == groupThumbnails // only visible if tooltip exists and mainItem is set to the correct one
}
