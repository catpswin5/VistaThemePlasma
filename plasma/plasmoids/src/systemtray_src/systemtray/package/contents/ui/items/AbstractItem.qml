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

    // input agnostic way to trigger the main action
    signal activated(var pos)

    // proxy signals for MouseArea
    signal clicked(var mouse)
    signal pressed(var mouse)
    signal wheel(var wheel)
    signal contextMenu(var mouse)

    readonly property bool isReorderingDisabled: index === -1
    readonly property int size: root.itemSize
    readonly property bool shouldBeHidden: !root.hiddenItemsVisible && !isReorderingDisabled
    onShouldBeHiddenChanged: {
        if(isReorderingDisabled) return;

        if(effectiveStatus == PlasmaCore.Types.PassiveStatus) {
            if(shouldBeHidden) {
                seqAnim.to = 0;
                seqAnim.start();

            } else if(!shouldBeHidden) {
                seqAnim.to = size;
                seqAnim.start();

            }
        }
    }

    property int index: visualIndex
    property var model: itemModel
    property int oldEffectiveStatus: PlasmaCore.Types.UnknownStatus
    property int effectiveStatus: model.effectiveStatus || PlasmaCore.Types.UnknownStatus
    onEffectiveStatusChanged: {
        if(oldEffectiveStatus == PlasmaCore.Types.PassiveStatus && effectiveStatus == PlasmaCore.Types.ActiveStatus) {
            root.hiddenItemsCount -= 1;
            abstractItem.implicitWidth = abstractItem.size;

        } else if(oldEffectiveStatus == PlasmaCore.Types.ActiveStatus && effectiveStatus == PlasmaCore.Types.PassiveStatus) {
            root.hiddenItemsCount += 1;
            root.hiddenItemsVisible = true;

        }

        oldEffectiveStatus = effectiveStatus;
    }

    property string text
    property string itemId
    property int status: model.status || PlasmaCore.Types.UnknownStatus
    property bool effectivePressed: false

    property alias mouseArea: mouseArea
    property alias held: mouseArea.held
    property alias iconContainer: iconContainer
    property alias seqAnim: seqAnim

    /* subclasses need to assign to this tooltip properties
    mainText:
    subText:
    */

    SequentialAnimation {
        id: seqAnim

        property int to: 0

        NumberAnimation { target: abstractItem; property: "implicitWidth"; to: seqAnim.to; duration: 75 }
    }

    implicitWidth: size
    implicitHeight: size

    location: Plasmoid.location

    Item {
        width: abstractItem.width
        height: abstractItem.height

        clip: true

        FocusScope {
            id: iconContainer

            property alias container: abstractItem

            width: abstractItem.size
            height: abstractItem.size

            x: -(parent.width - width)
            y: -(parent.height - height)

            Drag.active: mouseArea.drag.active
            Drag.source: abstractItem.parent
            Drag.hotSpot: Qt.point(width/2, height/2)

            Accessible.name: abstractItem.text
            Accessible.description: abstractItem.subText
            Accessible.role: Accessible.Button
            Accessible.onPressAction: abstractItem.activated(Plasmoid.popupPosition(iconContainer, iconContainer.width/2, iconContainer.height/2));

            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false

            activeFocusOnTab: true
            focus: true
            opacity: Drag.active ? 0.5 : 1.0

            states: [
                State {
                    when: iconContainer.Drag.active

                    ParentChange {
                        target: iconContainer
                        parent: representationItem
                    }

                    PropertyChanges {
                        target: iconContainer
                        x: mouseArea.mapToItem(representationItem, mouseArea.mouseX, mouseArea.mouseY).x - iconContainer.width * 0.75
                        y: mouseArea.mapToItem(representationItem, mouseArea.mouseX, mouseArea.mouseY).y - iconContainer.height / 2
                    }
                }
            ]

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
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: abstractItem

        property bool held: false
        onHeldChanged: setRequestedInhibitDnd(held);

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

        drag.filterChildren: true
        drag.target: held && !abstractItem.isReorderingDisabled ? iconContainer : null
        propagateComposedEvents: true
        hoverEnabled: true
        // Necessary to make the whole delegate area forward all mouse events
        acceptedButtons: Qt.AllButtons
        // Using onPositionChanged instead of onEntered because changing the
        // index in a scrollable view also changes the view position.
        // onEntered will change the index while the items are scrolling,
        // making it harder to scroll.
        onPositionChanged: if(mouseArea.containsPress) held = true;
        onClicked: mouse => {
            abstractItem.clicked(mouse)
        }
        onReleased: {
            iconContainer.Drag.drop();
            held = false;
        }
        onPressed: mouse => {
            abstractItem.hideImmediately()
            abstractItem.pressed(mouse)
        }
        onPressAndHold: mouse => {
            if(mouse.button === Qt.LeftButton) abstractItem.contextMenu(mouse);
        }
        onWheel: wheel => {
            abstractItem.wheel(wheel);
            //Don't accept the event in order to make the scrolling by mouse wheel working
            //for the parent scrollview this icon is in.
            wheel.accepted = false;
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: parent
        anchors.margins: 0

        property bool hasDrag: false

        visible: !abstractItem.isReorderingDisabled

        Rectangle {
            id: leftBar

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom

                topMargin: Kirigami.Units.smallSpacing/2
                bottomMargin: Kirigami.Units.smallSpacing/2
            }

            width: 1

            color: "#70ffffff"

            visible: false
            z: -1
        }

        Rectangle {
            id: rightBar

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom

                topMargin: Kirigami.Units.smallSpacing/2
                bottomMargin: Kirigami.Units.smallSpacing/2
            }

            width: 1

            color: "#70ffffff"

            visible: false
            z: -1
        }

        onEntered: drag => {
            leftBar.visible = drag.source.visualIndex > abstractItem.parent.visualIndex;
            rightBar.visible = drag.source.visualIndex < abstractItem.parent.visualIndex;
            hasDrag = true;
        }
        onExited: drag => {
            rightBar.visible = false;
            leftBar.visible = false;
            hasDrag = false;
        }
        onDropped: drag => {
            root.activeModel.items.move(drag.source.visualIndex, abstractItem.parent.visualIndex);
            hasDrag = false;
            rightBar.visible = false;
            leftBar.visible = false;
            orderingManager.saveConfiguration();
        }
    }

    Component.onCompleted: {
        if(effectiveStatus == PlasmaCore.Types.PassiveStatus) {
            root.hiddenItemsCount += 1;
            abstractItem.implicitWidth = 0;
            root.hiddenItemsVisible = false;
        }
    }
}

