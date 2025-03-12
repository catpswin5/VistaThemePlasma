/*
 *  SPDX-FileCopyrightText: 2015 David Rosca <nowrep@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

import org.kde.kirigami as Kirigami
import org.kde.draganddrop as DragAndDrop

import io.gitgud.catpswin56.private.quicklaunch

import "layout.js" as LayoutManager

PlasmoidItem {
    id: root

    readonly property int maxSectionCount: Plasmoid.configuration.maxSectionCount
    readonly property bool showLauncherNames : Plasmoid.configuration.showLauncherNames
    readonly property bool enablePopup : Plasmoid.configuration.enablePopup
    readonly property string title : ""
    readonly property bool vertical : Plasmoid.formFactor == PlasmaCore.Types.Vertical || (Plasmoid.formFactor == PlasmaCore.Types.Planar && height > width)
    readonly property bool horizontal : Plasmoid.formFactor == PlasmaCore.Types.Horizontal
    property bool dragging: false
    onDraggingChanged: if(!dragging) saveConfiguration()

    Layout.minimumWidth: !grid.visible ? 50 : LayoutManager.minimumWidth() + (Plasmoid.configuration.extraPadding ? Plasmoid.configuration.extraPaddingSize : 0)
    Layout.minimumHeight: LayoutManager.minimumHeight()

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    Item {
        anchors.fill: parent

        DragAndDrop.DropArea {
            anchors.fill: parent
            preventStealing: true
            enabled: !Plasmoid.immutable

            onDragEnter: drag => {
                var item = grid.itemAt(drag.x, drag.y);
                item.leftSep.visible = true;
            }

            onDrop: event => {
                if (isInternalDrop(event)) {
                    event.accept(Qt.IgnoreAction);
                    saveConfiguration();
                } else {
                    var index = grid.indexAt(event.x, event.y);
                    var item = grid.itemAt(event.x, event.y);
                    launcherModel.insertUrls(index == -1 ? launcherModel.count : index, event.mimeData.urls);
                    item.leftSep.visible = false;
                    event.accept(event.proposedAction);
                }
            }
        }

        Item {
            id: launcher

            anchors {
                top: title.length ? titleLabel.bottom : parent.top
                left: parent.left
                right: !vertical && popupArrow.visible ? popupArrow.left : parent.right
                bottom: vertical && popupArrow.visible ? popupArrow.top : parent.bottom
            }

            GridView {
                id: grid
                anchors.fill: parent

                interactive: false
                flow: horizontal ? GridView.FlowTopToBottom : GridView.FlowLeftToRight
                cellWidth: Plasmoid.configuration.showLauncherNames ? 160 : 24
                cellHeight: 26
                visible: count

                model: UrlModel {
                    id: launcherModel
                }

                delegate: IconItem { }

                function moveItemToPopup(iconItem, url) {
                    if (!popupArrow.visible) {
                        return;
                    }

                    popup.visible = true;
                    popup.mainItem.popupModel.insertUrl(popup.mainItem.popupModel.count, url);
                    popup.mainItem.listView.currentIndex = popup.mainItem.popupModel.count - 1;
                    iconItem.removeLauncher();
                }
            }
        }

        PlasmaCore.Dialog {
            id: popup
            type: PlasmaCore.Dialog.PopupMenu
            flags: Qt.WindowStaysOnTopHint
            hideOnWindowDeactivate: true
            location: Plasmoid.location
            visualParent: vertical ? popupArrow : root

            mainItem: Popup {
                Keys.onEscapePressed: popup.visible = false
            }
        }

        PlasmaCore.ToolTipArea {
            id: popupArrow
            visible: enablePopup
            location: Plasmoid.location

            anchors {
                top: vertical ? undefined : parent.top
                right: parent.right
                bottom: parent.bottom
            }

            subText: popup.visible ? i18n("Hide icons") : i18n("Show hidden icons")

            MouseArea {
                id: arrowMouseArea
                anchors.fill: parent

                activeFocusOnTab: parent.visible

                Keys.onPressed: {
                    switch (event.key) {
                    case Qt.Key_Space:
                    case Qt.Key_Enter:
                    case Qt.Key_Return:
                    case Qt.Key_Select:
                        arrowMouseArea.clicked(null);
                        break;
                    }
                }
                Accessible.name: parent.subText
                Accessible.role: Accessible.Button

                onClicked: {
                    popup.visible = !popup.visible
                }

                Kirigami.Icon {
                    anchors.fill: parent

                    rotation: popup.visible ? 180 : 0
                    Behavior on rotation {
                        RotationAnimation {
                            duration: Kirigami.Units.shortDuration * 3
                        }
                    }

                    source: {
                        if (Plasmoid.location == PlasmaCore.Types.TopEdge) {
                            return "arrow-down";
                        } else if (Plasmoid.location == PlasmaCore.Types.LeftEdge) {
                            return "arrow-right";
                        } else if (Plasmoid.location == PlasmaCore.Types.RightEdge) {
                            return "arrow-left";
                        } else if (vertical) {
                            return "arrow-right";
                        } else {
                            return "arrow-up";
                        }
                    }
                }
            }
        }
    }

    Logic {
        id: logic

        onLauncherAdded: {
            var m = isPopup ? popup.mainItem.popupModel : launcherModel;
            m.appendUrl(url);
        }

        onLauncherEdited: {
            var m = isPopup ? popup.mainItem.popupModel : launcherModel;
            m.changeUrl(index, url);
        }
    }

    // States to fix binding loop with enabled popup
    states: [
        State {
            name: "normal"
            when: !vertical

            PropertyChanges {
                target: popupArrow
                width: Kirigami.Units.iconSizes.smallMedium
                height: root.height
            }
        },

        State {
            name: "vertical"
            when: vertical

            PropertyChanges {
                target: popupArrow
                width: root.width
                height: Kirigami.Units.iconSizes.smallMedium
            }
        }
    ]

    Connections {
        target: Plasmoid.configuration
       function onLauncherUrlsChanged() {
            launcherModel.urlsChanged.disconnect(root.saveConfiguration);
            launcherModel.setUrls(Plasmoid.configuration.launcherUrls);
            launcherModel.urlsChanged.connect(root.saveConfiguration);
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action", "Add Launcher…")
            icon.name: "list-add"
            onTriggered: logic.addLauncher()
        }
    ]

    Component.onCompleted: {
        launcherModel.setUrls(Plasmoid.configuration.launcherUrls);
        launcherModel.urlsChanged.connect(root.saveConfiguration);
    }

    function saveConfiguration()
    {
        if (!root.dragging) {
            Plasmoid.configuration.launcherUrls = launcherModel.urls();
        }
    }

    function isInternalDrop(event)
    {
        return event.mimeData.source
            && event.mimeData.source.GridView
            && event.mimeData.source.GridView.view == grid;
    }
}
