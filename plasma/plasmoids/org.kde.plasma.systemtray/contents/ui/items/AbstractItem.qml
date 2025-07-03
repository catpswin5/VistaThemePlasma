/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>
    SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg

PlasmaCore.ToolTipArea {
    id: abstractItem

    property var model: itemModel

    required property string modelStr

    property string text: ""
    property alias mouseArea: mouseArea
    property string itemId
    property alias iconContainer: iconContainer
    property int status: model.status || PlasmaCore.Types.UnknownStatus
    property int effectiveStatus: model.effectiveStatus || PlasmaCore.Types.UnknownStatus
    property bool effectivePressed: false
    property alias held: mouseArea.held

    // input agnostic way to trigger the main action
    signal activated(var pos)

    // proxy signals for MouseArea
    signal clicked(var mouse)
    signal pressed(var mouse)
    signal wheel(var wheel)
    signal contextMenu(var mouse)

    /* subclasses need to assign to this tooltip properties
    mainText:
    subText:
    */



    location: Plasmoid.location

    MouseArea {
        id: mouseArea
        propagateComposedEvents: true
        property bool held: false

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
        onHeldChanged: {
            setRequestedInhibitDnd(held);
        }
        // This needs to be above applets when it's in the grid hidden area
        // so that it can receive hover events while the mouse is over an applet,
        // but below them on regular systray, so collapsing works
        //z: inHiddenLayout ? 1 : 0
        z: 1
        anchors.fill: abstractItem
        hoverEnabled: true
        drag.filterChildren: true
        drag.target: held ? icon : null
        // Necessary to make the whole delegate area forward all mouse events
        acceptedButtons: Qt.AllButtons
        // Using onPositionChanged instead of onEntered because changing the
        // index in a scrollable view also changes the view position.
        // onEntered will change the index while the items are scrolling,
        // making it harder to scroll.

        onPositionChanged: {
            if(mouseArea.containsPress) {
                held = true;
            }
        }
        onClicked: mouse => { abstractItem.clicked(mouse) }
        onReleased: {
            icon.Drag.drop();
            held = false;
            notAllowedIndicator.visible = false;
        }
        onPressed: mouse => {
            abstractItem.hideImmediately()
            abstractItem.pressed(mouse)
        }
        onPressAndHold: mouse => {
            //held = true;

            if (mouse.button === Qt.LeftButton) {
                abstractItem.contextMenu(mouse)
            }
        }
        onWheel: wheel => {
            abstractItem.wheel(wheel);
            //Don't accept the event in order to make the scrolling by mouse wheel working
            //for the parent scrollview this icon is in.
            wheel.accepted = false;
        }
    }

    ColumnLayout {
        id: icon
        anchors.fill: abstractItem
        anchors.topMargin: 1
        spacing: 0

        Drag.active: mouseArea.drag.active// && abstractItem.inHiddenLayout
        Drag.source: abstractItem.parent
        Drag.hotSpot: Qt.point(width/2, height/2)

        states: [
            State {
                when: icon.Drag.active

                ParentChange {
                    target: icon
                    parent: root.activeIconsGrid
                }

                PropertyChanges {
                    target: icon
                    x: mouseArea.mapToItem(root.activeIconsGrid, mouseArea.mouseX, mouseArea.mouseY).x - iconContainer.width * 0.75
                    y: mouseArea.mapToItem(root.activeIconsGrid, mouseArea.mouseX, mouseArea.mouseY).y - iconContainer.height / 2
                }
            }
        ]

        FocusScope {
            id: iconContainer
            property alias notAllowedIndicator: notAllowedIndicator.visible
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
            activeFocusOnTab: true
            Accessible.name: abstractItem.text
            Accessible.description: abstractItem.subText
            Accessible.role: Accessible.Button
            Accessible.onPressAction: abstractItem.activated(Plasmoid.popupPosition(iconContainer, iconContainer.width/2, iconContainer.height/2));
            opacity: icon.Drag.active ? 0.5 : 1
            Keys.onPressed: event => {
                switch (event.key) {
                    case Qt.Key_Space:
                    case Qt.Key_Enter:
                    case Qt.Key_Return:
                    case Qt.Key_Select:
                        abstractItem.activated(Qt.point(width/2, height/2));
                        break;
                    case Qt.Key_Menu:
                        abstractItem.contextMenu(null);
                        event.accepted = true;
                        break;
                }
            }

            property alias container: abstractItem
            readonly property int size: root.itemSize

            Layout.alignment: Qt.Bottom | Qt.AlignHCenter
            Layout.fillHeight: false
            implicitWidth: abstractItem.width
            implicitHeight: abstractItem.height
            //Layout.topMargin: abstractItem.inHiddenLayout ? Kirigami.Units.mediumSpacing : 0

            Image {
                id: notAllowedIndicator

                Timer {
                    running: !dropArea.hasDrag
                    repeat: true
                    interval: 1
                    onTriggered: {
                        if(icon.x == abstractItem.x && !dropArea.hasDrag) {
                            icon.Drag.drop();
                            notAllowedIndicator.visible = false;
                        }
                    }
                }

                anchors {
                    centerIn: parent

                    verticalCenterOffset: 4
                    horizontalCenterOffset: 2
                }

                source: "../imgs/notallowed.png"

                z: 1

                visible: false
            }
        }
    }
    DropArea {
        id: dropArea
        anchors.fill: parent
        anchors.margins: 0
        property bool hasDrag: false
        Rectangle {
            id: leftBar
            color: "#70ffffff"
            width: 1
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing/2
            anchors.bottomMargin: Kirigami.Units.smallSpacing/2
            visible: false
            z: -1
        }
        Rectangle {
            id: rightBar
            color: "#70ffffff"
            width: 1
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing/2
            anchors.bottomMargin: Kirigami.Units.smallSpacing/2
            visible: false
            z: -1
        }
        onEntered: drag => {
            if(drag.source.modelStr == abstractItem.modelStr) {
                drag.source.canMove = true;

                if(drag.source.visualIndex < abstractItem.parent.visualIndex) {
                    rightBar.visible = true;
                    leftBar.visible = false;
                } else {
                    rightBar.visible = false;
                    leftBar.visible = true;
                }
                hasDrag = true;
            } else drag.source.canMove = false;
        }
        onExited: drag => {
            hasDrag = false;
            rightBar.visible = false;
            leftBar.visible = false;
        }
        onDropped: drag => {
            notAllowedIndicator.visible = false;
            switch(abstractItem.modelStr) {
                case("hidden"):
                    if(drag.source.modelStr == "hidden") root.hiddenModel.items.move(drag.source.visualIndex, abstractItem.parent.visualIndex);
                    break;
                case("active"):
                    if(drag.source.modelStr == "active") root.activeModel.items.move(drag.source.visualIndex, abstractItem.parent.visualIndex);
                    break;
                case("system"):
                    if(drag.source.modelStr == "system") root.systemModel.items.move(drag.source.visualIndex, abstractItem.parent.visualIndex);
                    break;
            }
            //orderingManager.setItemOrder(itemId, abstractItem.parent.visualIndex);
            //orderingManager.setItemOrder(drag.source.itemId, drag.source.visualIndex);
            hasDrag = false;
            rightBar.visible = false;
            leftBar.visible = false;
            orderingManager.saveConfiguration();
        }
    }
}

