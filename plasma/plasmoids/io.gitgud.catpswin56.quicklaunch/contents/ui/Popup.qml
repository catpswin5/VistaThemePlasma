/*
 *  SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.draganddrop 2.0 as DragAndDrop

import "layout.js" as LayoutManager

Item {
    id: popup

    property bool dragging: false
    property alias popupModel : popupModel
    property alias listView: listView

    width: LayoutManager.popupItemWidth()
    height: Math.max(1, popupModel.count) * LayoutManager.popupItemHeight()

    DragAndDrop.DropArea {
        anchors.fill: parent
        preventStealing: true
        enabled: !plasmoid.immutable

        onDragEnter: {
            dragging = true;
        }

        onDragMove: {
            if (!event.mimeData.hasUrls) {
                return;
            }

            var index = listView.indexAt(event.x, event.y);

            if (isInternalDrop(event)) {
                popupModel.moveUrl(event.mimeData.source.itemIndex, index);
            } else if (event.mimeData.hasUrls) {
                popupModel.showDropMarker(index);
            }
        }

        onDragLeave: {
            dragging = false;
            popupModel.clearDropMarker();
        }

        onDrop: {
            dragging = false;
            popupModel.clearDropMarker();

            if (isInternalDrop(event)) {
                event.accept(Qt.IgnoreAction);
                saveConfiguration();
            } else if (event.mimeData.hasUrls) {
                var index = listView.indexAt(event.x, event.y);
                popupModel.insertUrls(index == -1 ? popupModel.count : index, event.mimeData.urls);
                event.accept(event.proposedAction);
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent

        focus: true
        interactive: true
        keyNavigationWraps: true

        model: UrlModel {
            id: popupModel
        }

        delegate: IconItem {
            isPopupItem: true
        }

        highlight: PlasmaExtras.Highlight {}

        highlightMoveDuration: Kirigami.Units.longDuration
        highlightMoveVelocity: 1

        function moveItemToGrid(iconItem, url) {
            launcherModel.insertUrl(launcherModel.count, url);
            listView.currentIndex = launcherModel.count - 1;
            iconItem.removeLauncher();
        }
    }

    Connections {
        target: plasmoid.configuration
        function onPopupUrlsChanged() {
            popupModel.urlsChanged.disconnect(saveConfiguration);
            popupModel.setUrls(plasmoid.configuration.popupUrls);
            popupModel.urlsChanged.connect(saveConfiguration);
        }
    }

    Component.onCompleted: {
        popupModel.setUrls(plasmoid.configuration.popupUrls);
        popupModel.urlsChanged.connect(saveConfiguration);
    }

    function saveConfiguration()
    {
        if (!dragging) {
            plasmoid.configuration.popupUrls = popupModel.urls();
        }
    }

    function isInternalDrop(event)
    {
        return event.mimeData.source
            && event.mimeData.source.ListView
            && event.mimeData.source.ListView.view == listView;
    }
}
