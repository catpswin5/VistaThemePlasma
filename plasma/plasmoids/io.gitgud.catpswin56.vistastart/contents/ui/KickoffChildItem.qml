/*
    Copyright (C) 2011  Martin Gräßlin <mgraesslin@kde.org>
    Copyright (C) 2012  Gregor Taetzner <gregor@freenet.de>
    Copyright 2014 Sebastian Kügler <sebas@kde.org>
    Copyright (C) 2015-2018  Eike Hein <hein@kde.org>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

//This is the generic item delegate used by FavoritesView, RecentlyUsedView and SearchView. 

import QtQuick
import QtQuick.Layouts

import org.kde.draganddrop
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

import "code/tools.js" as Tools

Item {
    id: listItem

    required property var model
    required property int index

    property int pressX: -1
    property int pressY: -1
    signal reset
    signal actionTriggered(string actionId, variant actionArgument)
    signal aboutToShowActionMenu(variant actionMenu)
    signal addBreadcrumb(var model, string title)

    property alias toolTip: toolTip
    property alias toolTipTimer: toolTipTimer
    property bool smallIcon: false
    readonly property int itemIndex: model?.index ?? -1
    readonly property string url: model?.url ?? ""
    readonly property var decoration: model?.decoration ?? ""

    property bool dropEnabled: false
    property bool appView: false
    property bool modelChildren: model?.hasChildren ?? false
    property var childModel

    property bool hasActionList: ((model?.favoriteId !== null)
        || (("hasActionList" in model) && (model?.hasActionList)))
    property Item menu: actionMenu

    property bool expanded: false
    property var listView: listItem.ListView.view

    property var parentKickoffItem

    readonly property bool isFavorites: listView?.isFavorites ?? false
    readonly property bool isDefaultInternetApp: isFavorites && Plasmoid.configuration.defaultInternetApp == model?.display
    readonly property bool isDefaultEmailApp: isFavorites && Plasmoid.configuration.defaultEmailApp == model?.display

    readonly property string title: {
        if(model) {
            if(isDefaultInternetApp)
                return i18n("Internet");
            else if(isDefaultEmailApp)
                return i18n("E-mail");
            else
                return model.display;
        }
    }
    readonly property string subtitle: model?.display

    onAboutToShowActionMenu: (actionMenu) => {
        var actionList = hasActionList ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, listItem.listView.model.favoritesModel, model.favoriteId);
    }

    onActionTriggered: (actionId, actionArgument) => {
        kicker.expanded = false;

        if (Tools.triggerAction(listItem.listView.model, model.index, actionId, actionArgument) === true) {
            kicker.expanded = false;
        }
    }

    enabled: model ? (!model.disabled && title !== "") : false
    visible: title !== ""
    implicitWidth: listView?.width ?? parent.width
    implicitHeight: column.height

    function activate() {
        var view = listView;

        if (model.hasChildren) {
            childModel = view.model.modelForRow(index);
            listItem.expanded = !listItem.expanded;
        } else {
            childModel.trigger(model.index, "", null);
            listItem.reset();
            Plasmoid.expanded = false;
        }
    }

    function openActionMenu(x, y) {
        aboutToShowActionMenu(actionMenu);
        if(actionMenu.actionList.length === 0) return;
        actionMenu.visualParent = listItem;
        actionMenu.open(x, y);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu();
        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
            event.accepted = true;
            listItem.activate();
        }
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: (actionId, actionArgument) => {
            actionTriggered(actionId, actionArgument);
        }
    }

    Column {
        id: column

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: mainItem.height

        Item {
            id: mainItem

            implicitWidth: parent.width
            implicitHeight: model?.display !== "" ?
                (Kirigami.Units.smallSpacing / (small ? 2 : 1)) + Math.max(elementIcon.height, titleElement.implicitHeight) + (small ? 1 : 0)
                : 0

            KSvg.FrameSvgItem {
                id: newHighlight

                anchors.fill: background

                imagePath: Qt.resolvedUrl("svgs/" + startStyles.currentStyle.styleName + "/" + "menuitem.svg")
                prefix: "new"

                visible: model?.isNewlyInstalled ?? false

                Rectangle {
                    anchors.fill: parent

                    color: "#ffe599"

                    visible: listItem.smallIcon
                }
            }

            KSvg.FrameSvgItem {
                id: background

                anchors {
                    fill: parent
                    leftMargin: listItem.smallIcon ? Kirigami.Units.smallSpacing-1 : Kirigami.Units.smallSpacing
                }

                imagePath: Qt.resolvedUrl("svgs/" + startStyles.currentStyle.styleName + "/" + "menuitem.svg")
                prefix: "hover"

                opacity: {
                    if(ma.containsMouse) return 1;
                    if(listItem.parentKickoffItem.childIndex === model.index) return 0.5;
                    return 0;
                }
            }

            Kirigami.Icon {
                id: elementIcon

                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.largeSpacing*3
                    verticalCenter: parent.verticalCenter
                }

                width: smallIcon ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                height: width

                animated: false

                source: (listItem.appView && Plasmoid.configuration.useGenericIcons && model.hasChildren) ? "folder" : (model ? model.decoration : "")
            }

            ColumnLayout {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: elementIcon.right
                    right: parent.right
                    leftMargin: listItem.appView ? Kirigami.Units.mediumSpacing-1 : Kirigami.Units.smallSpacing * 2
                    rightMargin: Kirigami.Units.smallSpacing * 2
                }

                spacing: 2

                PlasmaComponents.Label {
                    id: titleElement

                    Layout.fillWidth: true

                    text: listItem.title
                    font.bold: listItem.isFavorites && !Plasmoid.configuration.disableBold
                        || listItem.isDefaultInternetApp
                        || listItem.isDefaultEmailApp
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    color: startStyles.currentStyle.leftPanel.itemTextColor
                }

                PlasmaComponents.Label {
                    id: subTitleElement

                    Layout.fillWidth: true

                    height: implicitHeight
                    color: startStyles.currentStyle.leftPanel.itemTextColor
                    text: isDefaultEmailApp || isDefaultInternetApp ? listItem.subtitle : listItem.title
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft

                    visible: listItem.title !== model?.display
                }
            }

            PlasmaCore.ToolTipArea {
                id: toolTip

                anchors.fill: parent

                active: titleElement.truncated
                interactive: false
                mainText: model?.display ?? ""
            }

            Timer {
                id: toolTipTimer

                interval: Kirigami.Units.longDuration*2
                onTriggered: {
                    toolTip.showToolTip();
                }
            }


            MouseArea {
                id: ma

                anchors.fill: parent

                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: listItem.modelChildren || !listItem.smallIcon ? undefined : Qt.PointingHandCursor
                onEntered: {
                    if(listItem.parentKickoffItem.childItem && listItem.parentKickoffItem.childItem === listItem) {
                        listItem.parentKickoffItem.childItem.toolTipTimer.stop();
                        listItem.parentKickoffItem.childItem.toolTip.hideToolTip();
                    }
                    listItem.parentKickoffItem.childItem = listItem;
                    toolTipTimer.start();
                }
                onExited: {
                    toolTipTimer.stop();
                    toolTip.hideToolTip();
                    listItem.parentKickoffItem.childItem = null;
                    listItem.pressX = -1;
                    listItem.pressY = -1;
                }
                onPressed: mouse => {
                    if(mouse.button === Qt.LeftButton) {
                        listItem.pressX = mouse.x;
                        listItem.pressY = mouse.y;
                    }

                }
                onPositionChanged: mouse => {
                    if(listItem.pressX != -1 && model.url && dragHelper.isDrag(listItem.pressX, listItem.pressY, mouse.x, mouse.y)) {
                        kicker.dragSource = listItem;
                        dragHelper.dragIconSize = Kirigami.Units.iconSizes.small;
                        dragHelper.startDrag(kicker, model.url, model.decoration);
                    }
                }
                onReleased: mouse => {
                    if(mouse.button === Qt.LeftButton) {
                        if (mouse.source == Qt.MouseEventSynthesizedByQt) {
                            positionChanged(mouse);
                        }
                        listItem.pressX = -1;
                        listItem.pressY = -1;
                    }
                }
                onClicked: mouse => {
                    if(mouse.button === Qt.LeftButton) {
                        listItem.activate();
                        root.visible = false;
                    } else if(mouse.button === Qt.RightButton) {
                        if(listItem.hasActionList) {
                            listItem.openActionMenu(mouse.x, mouse.y);
                        }
                    }
                }
            }
        }
    }
}
