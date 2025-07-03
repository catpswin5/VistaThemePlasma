import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.ksvg as KSvg
import org.kde.kwindowsystem

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

MouseArea {
    id: groupThumbnails

    property QtObject root

    readonly property bool isList: (154 * thumbnailModel.count) > tasks.availableScreenRect.width
        || !Plasmoid.configuration.previewGroupEnabled || !Plasmoid.configuration.extPreviewFunc
    readonly property bool containsDrag: root.containsDrag
    readonly property bool isOverflowing: thumbnailList.contentHeight > tasks.availableScreenRect.height

    readonly property alias thumbnailHeight: thumbnailList.maxThumbnailHeight

    implicitWidth: (isList ? thumbnailList.maxThumbnailWidth : thumbnailList.contentWidth)
    implicitHeight: (isList ? (isOverflowing ? tasks.availableScreenRect.height : thumbnailList.contentHeight) : thumbnailList.maxThumbnailHeight) + (isOverflowing ? 0 : scrollView.anchors.topMargin + scrollView.anchors.bottomMargin)

    hoverEnabled: true
    propagateComposedEvents: true

    KSvg.FrameSvgItem {
        anchors.fill: parent
        anchors.bottomMargin: -4

        imagePath: Qt.resolvedUrl("svgs/tooltip.svg")
        prefix: "list"

        visible: parent.isList
    }

    DelegateModel {
        id: thumbnailModel

        model: tasksModel
        rootIndex: tasksModel.makeModelIndex(root.taskIndex)
        delegate: WindowThumbnail {
            isGroupDelegate: true
            root: groupThumbnails.root
        }
    }
    DelegateModel {
        id: listModel

        model: tasksModel
        rootIndex: tasksModel.makeModelIndex(root.taskIndex)
        delegate: WindowListDelegate {
            root: groupThumbnails.root
        }
    }

    QQC2.ScrollView {
        id: scrollView

        anchors.fill: parent
        anchors.bottomMargin: !isList ? 0 : Kirigami.Units.smallSpacing
        anchors.topMargin: !isList ? 0 : Kirigami.Units.smallSpacing
        anchors.leftMargin: 0
        anchors.rightMargin: 0

        rightPadding: QQC2.ScrollBar.vertical.visible ? QQC2.ScrollBar.vertical.width : 0

        ListView {
            id: thumbnailList

            property int maxThumbnailWidth: maxThumbnailItem !== null ? maxThumbnailItem.implicitWidth : 154
            property int maxThumbnailHeight: maxThumbnailItem !== null ? maxThumbnailItem.implicitHeight : 154
            property Item maxThumbnailItem

            function updateMaxSize() {
                var thumbnailItem = itemAtIndex(0);
                for(var i = 0; i < thumbnailList.count; i++) {
                    if(thumbnailItem?.implicitWidth >= thumbnailList.maxThumbnailWidth)
                        thumbnailList.maxThumbnailItem = thumbnailItem;
                }
                if(!isList) {
                    for(var i = 0; i < thumbnailList.count; i++) {
                        if(thumbnailItem?.implicitHeight >= thumbnailList.maxThumbnailHeight)
                            thumbnailList.maxThumbnailItem = thumbnailItem;
                    }
                }
            }

            interactive: false
            spacing: isList ? 0 : -4
            orientation: !isList ? ListView.Horizontal : ListView.Vertical
            model: !isList ? thumbnailModel : listModel
            clip: true

            // HACK: delay the update by 15 ms to leave time for the thumbnail item's implicitHeight/implicitWidth property to correct itself
            onCountChanged: if(count > 1) updateDelayTimer.start()

            Timer {
                id: updateDelayTimer

                interval: 15
                repeat: false
                triggeredOnStart: false
                onTriggered: thumbnailList.updateMaxSize();
            }
        }
    }
}
