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
import org.kde.draganddrop 2.0 as DragAndDrop
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

    Keys.onPressed: {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            logic.openUrl(url);
            break;
        case Qt.Key_Menu:
            contextMenu.refreshActions();
            contextMenu.open(0,0);
            event.accepted = true;
            break;
        case Qt.Key_Backspace:
        case Qt.Key_Delete:
            removeLauncher();
            event.accepted = true;
            break;
        }

        // BEGIN Arrow keys
        if (!(event.modifiers & Qt.ControlModifier) || !(event.modifiers & Qt.ShiftModifier)) {
            return;
        }

        switch (event.key) {
        case Qt.Key_Up: {
            if (iconItem.isPopupItem && iconItem.itemIndex === 0 && Plasmoid.location === PlasmaCore.Types.TopEdge) {
                iconItem.ListView.view.moveItemToGrid(iconItem, url);
                break;
            } else if (!iconItem.isPopupItem && Plasmoid.location === PlasmaCore.Types.BottomEdge) {
                iconItem.GridView.view.moveItemToPopup(iconItem, url);
                break;
            }

            decreaseIndex();
            break;
        }

        case Qt.Key_Down: {
            if (iconItem.isPopupItem && iconItem.itemIndex === iconItem.ListView.view.count - 1 && Plasmoid.location === PlasmaCore.Types.BottomEdge) {
                iconItem.ListView.view.moveItemToGrid(iconItem, url);
                break;
            } else if (!iconItem.isPopupItem && Plasmoid.location === PlasmaCore.Types.TopEdge) {
                iconItem.GridView.view.moveItemToPopup(iconItem, url);
                break;
            }

            increaseIndex();
            break;
        }

        case Qt.Key_Left: {
            if (iconItem.isPopupItem && Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                iconItem.ListView.view.moveItemToGrid(iconItem, url);
                break;
            } else if (!iconItem.isPopupItem && Plasmoid.location === PlasmaCore.Types.RightEdge) {
                iconItem.GridView.view.moveItemToPopup(iconItem, url);
                break;
            }

            decreaseIndex();
            break;
        }
        case Qt.Key_Right: {
            if (iconItem.isPopupItem && Plasmoid.location === PlasmaCore.Types.RightEdge) {
                iconItem.ListView.view.moveItemToGrid(iconItem, url);
                break;
            } else if (!iconItem.isPopupItem && Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                iconItem.GridView.view.moveItemToPopup(iconItem, url);
                break;
            }

            increaseIndex();
            break;
        }
        default:
            return;
        }

        event.accepted = true;
        // END Arrow keys
    }

    function decreaseIndex() {
        const newIndex = iconItem.itemIndex - 1;
        if (newIndex < 0) {
            return;
        }
        if (iconItem.isPopupItem) {
            popupModel.moveUrl(iconItem.itemIndex, newIndex);
            iconItem.ListView.view.currentIndex = newIndex;
        } else {
            launcherModel.moveUrl(iconItem.itemIndex, newIndex);
            iconItem.GridView.view.currentIndex = newIndex;
        }
    }

    function increaseIndex() {
        const newIndex = iconItem.itemIndex + 1;
        if (newIndex === (iconItem.isPopupItem ? iconItem.ListView.view.count : iconItem.GridView.view.count)) {
            return;
        }
        if (iconItem.isPopupItem) {
            popupModel.moveUrl(iconItem.itemIndex, newIndex);
            iconItem.ListView.view.currentIndex = newIndex;
        } else {
            launcherModel.moveUrl(iconItem.itemIndex, newIndex);
            iconItem.GridView.view.currentIndex = newIndex;
        }
    }

    KSvg.FrameSvgItem {
        id: hoverSvg
        anchors.fill: parent
        imagePath: "widgets/button"
        prefix: "keyboard-hover"
        visible: mouseArea.containsMouse
    }

    DragAndDrop.DragArea {
        id: dragArea
        width: iconItem.width
        height: iconItem.height
        enabled: true
        defaultAction: Qt.MoveAction
        supportedActions: Qt.MoveAction
        delegate: icon

        mimeData {
            url: url
            source: iconItem
        }

        onDragStarted: {
            dragging = true;
        }

        onDrop: {
            dragging = false;

            if (action == Qt.MoveAction) {
                removeLauncher();
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            activeFocusOnTab: true
            Accessible.name: iconItem.launcher.applicationName
            Accessible.description: i18n("Launch %1", iconItem.launcher.genericName || iconItem.launcher.applicationName)
            Accessible.role: Accessible.Button

            onActiveFocusChanged: {
                if (activeFocus) {
                    entered();
                }
            }

            onEntered: {
                if (iconItem.ListView.view) {
                    iconItem.ListView.view.currentIndex = iconItem.itemIndex;
                }
            }

            onPressed: {
                if (mouse.button == Qt.RightButton) {
                    contextMenu.refreshActions();
                    contextMenu.open(mouse.x, mouse.y);
                    dragArea.enabled = false
                }
                hoverSvg.prefix = "keyboard-pressed"
            }

            onReleased: {
                hoverSvg.prefix = "keyboard-hover"
            }

            onClicked: {
                if (mouse.button == Qt.LeftButton) {
                    logic.openUrl(url)
                }
            }

            Kirigami.Icon {
                id: icon

                anchors {
                    left: parent.left
                    leftMargin: 3
                    verticalCenter: parent.verticalCenter
                }

                width: 16
                height: width
                source: url == "quicklaunch:drop" ? "" : iconName
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

            KSvg.FrameSvgItem {
                anchors.fill: parent
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: dragging || url == "quicklaunch:drop"
            }

            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                active: !dragging
                mainText: iconItem.launcher.applicationName
                subText: iconItem.launcher.genericName
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
                    text: i18nc("@action:inmenu", "Add Launcher…")
                    icon: "list-add"
                    onClicked: addLauncher()
                }

                PlasmaExtras.MenuItem {
                    text: i18nc("@action:inmenu", "Edit Launcher…")
                    icon: "document-edit"
                    onClicked: editLauncher()
                }

                PlasmaExtras.MenuItem {
                    text: i18nc("@action:inmenu", "Remove Launcher")
                    icon: "list-remove"
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
        }
    }

    states: [
        State {
            name: "popup"
            when: isPopupItem

            AnchorChanges {
                target: dragArea
                anchors.left: dragArea.parent.left
                anchors.right: dragArea.parent.right
                anchors.top: dragArea.parent.top
                anchors.bottom: dragArea.parent.bottom
            }

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
                target: dragArea
                anchors.verticalCenter: dragArea.parent.verticalCenter
                anchors.horizontalCenter: dragArea.parent.horizontalCenter
            }

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
