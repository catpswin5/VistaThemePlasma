/*
 *  SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "layout.js" as LayoutManager

Item {
    id: iconItem

    readonly property int itemIndex : index
    property bool dragging : false
    property bool isPopupItem : false
    readonly property var launcher : logic.launcherData(url)
    readonly property string iconName : launcher.iconName || "fork"

    width: isPopupItem ? LayoutManager.popupItemWidth() : grid.cellWidth
    height: isPopupItem ? LayoutManager.popupItemHeight() : grid.cellHeight

    function setRequestedInhibitDnd(value) {
        // This is modifying the value in the panel containment that
        // inhibits accepting drag and drop, so that we don't accidentally
        // drop the task on this panel.
        let item = this;
        while (item.parent) {
            item = item.parent;
            if (item.appletRequestsInhibitDnD !== undefined) {
                item.appletRequestsInhibitDnD = value
            }
        }
    }

    PlasmaCore.ToolTipArea {
        id: tooltip

        anchors.fill: parent

        mainText: iconItem.launcher.applicationName
    }

    Item {
        id: itemRect

        width: iconItem.width
        height: iconItem.height

        Drag.active: mouseArea.held
        Drag.source: mouseArea
        Drag.hotSpot.x: Math.floor(width / 2)
        Drag.hotSpot.y: Math.floor(height / 2)

        states: [
            State {
                name: "dragging"
                when: mouseArea.held

                ParentChange {
                    target: itemRect
                    parent: grid
                }
            }
        ]

        KSvg.FrameSvgItem {
            id: frame

            anchors.fill: parent

            imagePath: Qt.resolvedUrl("svgs/button.svg")
            prefix: mouseArea.containsPress ? "pressed" : "hover"

            visible: mouseArea.containsMouse && !mouseArea.held
        }

        Kirigami.Icon {
            id: icon

            anchors {
                left: showLauncherNames ? parent.left : undefined
                leftMargin: 3
                verticalCenter: parent.verticalCenter
                horizontalCenter: showLauncherNames ? undefined : parent.horizontalCenter
            }

            width: 16
            height: width
            source: iconName

            opacity: mouseArea.held ? 0.5 : 1.0
        }

        PlasmaComponents3.Label {
            id: label

            anchors {
                left: icon.right
                leftMargin: 4
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -1
            }

            text: iconItem.launcher.applicationName
            textFormat: Text.PlainText
            maximumLineCount: 1
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            width: 134
        }

        PlasmaExtras.Menu {
            id: contextMenu

            property var jumpListItems : []

            visualParent: mouseArea

            PlasmaExtras.MenuItem {
                id: jumpListSeparator
                separator: true
            }

            PlasmaExtras.MenuItem {
                text: i18n("Properties")
                onClicked: editLauncher()
            }

            PlasmaExtras.MenuItem {
                text: i18n("Remove")
                onClicked: removeLauncher()
            }

            PlasmaExtras.MenuItem {
                separator: true
            }

            PlasmaExtras.MenuItem {
                action: Plasmoid.internalAction("configure")
            }

            function refreshActions() {
                for (var i = 0; i < jumpListItems.length; ++i) {
                    var item = jumpListItems[i];
                    removeMenuItem(item);
                    item.destroy();
                }
                jumpListItems = [];

                for (var i = 0; i < launcher.jumpListActions.length; ++i) {
                    var action = launcher.jumpListActions[i];
                    var item = menuItemComponent.createObject(iconItem, {
                        "text": action.name,
                        "icon": action.icon
                    });
                    item.clicked.connect(function() {
                        logic.openExec(this.exec);
                    }.bind(action));

                    addMenuItem(item, jumpListSeparator);
                    jumpListItems.push(item);
                }
            }
        }

        Component {
            id: menuItemComponent
            PlasmaExtras.MenuItem { }
        }

        Timer {
            interval: 1000
            running: mouseArea.containsMouse
            onTriggered: tooltip.showToolTip();
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property bool held: false
            property int itemIndex: model.index

            onHeldChanged: {
                if(held) {
                    setRequestedInhibitDnd(true);
                    root.dragging = true;
                } else {
                    setRequestedInhibitDnd(false);
                    root.dragging = false;
                }
            }

            hoverEnabled: true
            propagateComposedEvents: true

            drag.smoothed: false
            drag.threshold: 0
            drag.target: held ? itemRect : undefined
            drag.axis: Drag.XAndYAxis

            function resetPos() {
                held = false;
                itemRect.x = dropArea.x;
                itemRect.y = dropArea.y;
                itemRect.Drag.cancel();
            }

            onReleased: event => {
                if(held) resetPos();
            }
            onPositionChanged: {
                if(containsPress) held = true;
            }

            onClicked: mouse => {
                if (mouse.button == Qt.RightButton) {
                    contextMenu.refreshActions();
                    contextMenu.open(mouse.x, mouse.y);
                }
                if (mouse.button == Qt.LeftButton) {
                    logic.openUrl(url)
                }
            }
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: parent

        visible: root.dragging

        onEntered: (drag) => {
            if(drag.source.itemIndex !== model.index) iconItem.GridView.view.model.moveUrl(drag.source.itemIndex, model.index);
        }
    }

    states: [
        State {
            name: "popup"
            when: isPopupItem

            AnchorChanges {
                target: icon
                anchors.right: undefined
                anchors.bottom: undefined
            }

            AnchorChanges {
                target: label
                anchors.top: label.parent.top
                anchors.left: icon.right
            }

            PropertyChanges {
                target: label
                horizontalAlignment: Text.AlignHLeft
                visible: true
                elide: Text.ElideRight
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
            }
        },

        State {
            name: "grid"
            when: !isPopupItem

            AnchorChanges {
                target: label
                anchors.top: undefined
            }

            PropertyChanges {
                target: label
                visible: showLauncherNames
            }
        },

        State {
            name: "menu"
            when: !contextMenu.visible

            PropertyChanges {
                target: dragArea
                enabled: true
            }
        }
    ]

    function addLauncher()
    {
        logic.addLauncher(isPopupItem);
    }

    function editLauncher()
    {
        logic.editLauncher(url, itemIndex, isPopupItem);
    }

    function removeLauncher()
    {
        var m = isPopupItem ? popupModel : launcherModel;
        m.removeUrl(itemIndex);
    }
}
