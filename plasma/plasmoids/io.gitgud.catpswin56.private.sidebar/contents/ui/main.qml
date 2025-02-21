/*
 *  SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts

import Qt.labs.platform

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import org.kde.graphicaleffects as KGraphicalEffects
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.draganddrop as DnD

import "items"

ContainmentItem {
    id: root

    // Expose the configuration values for io.gitgud.catpswin56.sidebar
    readonly property int sidebarWidth: Plasmoid.configuration.width
    readonly property int sidebarLocation: Plasmoid.configuration.location
    readonly property bool sidebarCollapsed: Plasmoid.configuration.collapse

    Containment.onAppletAdded: addApplet(applet);
    Containment.onAppletRemoved: {
        for (var i = 0; i < mainStack.count; i++) {
            if (mainStack.itemAtIndex(i).applet.Plasmoid.id === applet.id) {
                appletsModel.remove(i, 0);
                break;
            }
        }
    }

    function addApplet(applet) {
        const appletItem = root.itemFor(applet);

        appletsModel.insert(mainStack.count, { applet: appletItem, plasmoidId: appletItem.Plasmoid.pluginName })
    }

    SystemTrayIcon {
        id: trayIcon

        icon.name: "gadgets-sidebar"
        menu: Menu {
            MenuItem {
                text: root.sidebarCollapsed ? i18n("Show sidebar") : i18n("Hide sidebar")
                onTriggered: Plasmoid.configuration.collapse = !root.sidebarCollapsed;
            }
            MenuItem {
                text: i18n("Options")
                onTriggered: Plasmoid.internalAction("configure").trigger()
            }
        }
        tooltip: "Windows Sidebar"

        visible: true

        Component.onCompleted: menu.visible = false;
    }

    ListModel { id: appletsModel }

    Item {
        id: orderingManager

        property var orderObject: {}

        function saveConfiguration() {
            for(var i = 0; i < delegateModel.items.count; i++) {
                var item = delegateModel.items.get(i);
                if(item.model.plasmoidId !== "")
                    setItemOrder(item.model.plasmoidId, item.itemsIndex, false);
            }
            writeToConfig();
        }

        function setItemOrder(id, index, write = true) {
            if(typeof orderObject === "undefined")
                orderObject = {};
            orderObject[id] = index;
            if(write) writeToConfig();
        }

        function getItemOrder(id) {
            if(typeof orderObject[id] === "undefined") return -1;
            return orderObject[id];
        }

        function writeToConfig() {
            Plasmoid.configuration.itemOrdering = JSON.stringify(orderObject);
            Plasmoid.configuration.writeConfig();
        }

        Component.onCompleted: {
            var list = Plasmoid.configuration.itemOrdering;
            if(list !== "")
                orderObject = JSON.parse(list);

            if(typeof orderObject === "undefined")
                orderObject = {};
        }
    }

    DelegateModel {
        id: delegateModel

        model: appletsModel
        function determinePosition(item) {
            let lower = 0;
            let upper = items.count
            while(lower < upper) {
                const middle = Math.floor(lower + (upper - lower) / 2)
                var middleItem = items.get(middle);

                var first = orderingManager.getItemOrder(item.model.plasmoidId);
                var second = orderingManager.getItemOrder(middleItem.model.plasmoidId);

                const result = first < second;
                if(result) {
                    upper = middle;
                } else {
                    lower = middle + 1;
                }
            }
            return lower;
        }
        function sort() {
            while(unsortedItems.count > 0) {
                const item = unsortedItems.get(0);
                //var shouldInsert = item.model.itemId !== "" || (typeof item.model.hasApplet !== "undefined");
                var i = determinePosition(item); //orderingManager.getItemOrder(item.model.itemId);
                item.groups = "items";
                items.move(item.itemsIndex, i);
            }
        }
        items.includeByDefault: false
        groups: DelegateModelGroup {
            id: unsortedItems
            name: "unsorted"

            includeByDefault: true

            onChanged: delegateModel.sort();
        }
        delegate: PlasmoidItem {
            id: plasmoidDelegate

            signal loadingCompleted()
            onLoadingCompleted: {
                delegateModel.sort();
            }

            required property var model
            property int plasmoidIndex: DelegateModel.itemsIndex

            width: mainStack.width

            ParallelAnimation {
                id: plasmoidBackAnim
                NumberAnimation { id: plasmoidBackAnimX; target: plasmoidContainer; property: "x"; easing.type: Easing.Linear; duration: 125 }
                NumberAnimation { id: plasmoidBackAnimY; target: plasmoidContainer; property: "y"; easing.type: Easing.Linear; duration: 125 }
                onRunningChanged: {
                    if(!running) {
                        dragHndMa.held = false;
                    }
                }
            }

            Item {
                id: plasmoidContainer

                states: [
                    State {
                        name: "dragging"
                        when: dragHndMa.held

                        ParentChange {
                            target: plasmoidContainer
                            parent: mainStack
                        }
                    }
                ]

                width: plasmoidDelegate.width
                height: plasmoidDelegate.height

                Drag.active: dragHndMa.held
                Drag.source: dragHndMa
                Drag.hotSpot.x: Math.floor(width / 2.5)
                Drag.hotSpot.y: Math.floor(height / 2.5)

                Item {
                    id: gadgetToolbox

                    anchors.right: parent.right
                    anchors.top: parent.top

                    height: 48
                    width: 11

                    visible: opacity

                    opacity: plasmoidMa.hovered

                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }

                    Rectangle {
                        anchors.fill: parent

                        border.width: 1
                        border.color: "white"
                        radius: 4

                        color: "#214d72"

                        opacity: 0.3
                    }
                    ColumnLayout {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: -1
                        anchors.horizontalCenter: parent.horizontalCenter

                        spacing: 0

                        KSvg.FrameSvgItem {
                            property string suffix: closeMa.containsMouse ? (closeMa.containsPress ? "-pressed" : "-hover") : ""

                            Layout.preferredHeight: 15
                            Layout.preferredWidth: 11

                            imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                            prefix: "close" + suffix

                            KSvg.SvgItem {
                                anchors.centerIn: parent
                                width: 9
                                height: 8
                                imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                elementId: "close"
                            }

                            MouseArea {
                                id: closeMa

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    plasmoidDelegate.applet.plasmoid.internalAction("remove").trigger();
                                    appletsModel.remove(model.index, 1);
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: 1
                            Layout.preferredWidth: 7
                            Layout.leftMargin: 2
                            Layout.topMargin: -1
                            color: "white"
                            opacity: 0.3
                        }

                        KSvg.FrameSvgItem {
                            property string suffix: optionsMa.containsMouse ? (optionsMa.containsPress ? "-pressed" : "-hover") : ""

                            Layout.preferredHeight: 15
                            Layout.preferredWidth: 11

                            imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                            prefix: "other" + suffix

                            KSvg.SvgItem {
                                anchors.centerIn: parent
                                width: 9
                                height: 9
                                imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                                elementId: "options"
                            }

                            MouseArea {
                                id: optionsMa

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: plasmoidDelegate.applet.plasmoid.internalAction("configure").trigger()
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: 1
                            Layout.preferredWidth: 7
                            Layout.leftMargin: 2
                            Layout.topMargin: -1
                            Layout.bottomMargin: 3

                            color: "white"
                            opacity: 0.3
                        }

                        KSvg.SvgItem {
                            Layout.preferredWidth: 5
                            Layout.preferredHeight: 11
                            Layout.alignment: Qt.AlignHCenter
                            Layout.rightMargin: 2

                            imagePath: Qt.resolvedUrl("svgs/gadget-buttons.svg")
                            elementId: "drag"

                            MouseArea {
                                id: dragHndMa

                                anchors.fill: parent
                                anchors.margins: -Kirigami.Units.smallSpacing

                                property bool held: false
                                property alias plasmoidIndex: plasmoidDelegate.plasmoidIndex

                                property point beginDrag
                                property point currentDrag
                                property point dragThreshold: Qt.point(-1,-1);

                                onHeldChanged: {
                                    if(held) mainStack.plasmoidIsBeingDragged = true;
                                    else mainStack.plasmoidIsBeingDragged = false;
                                }

                                hoverEnabled: true
                                propagateComposedEvents: true

                                drag.smoothed: false
                                drag.threshold: 0
                                drag.target: held ? plasmoidContainer : undefined
                                drag.axis: Drag.XAndYAxis

                                function sendItemBack() {
                                    beginDrag = Qt.point(plasmoidDelegate.x, plasmoidDelegate.y);
                                    plasmoidBackAnimX.from = currentDrag.x //- taskList.contentX;
                                    plasmoidBackAnimX.to = beginDrag.x - mainStack.contentX;
                                    plasmoidBackAnimY.from = currentDrag.y// - taskList.contentY;
                                    plasmoidBackAnimY.to = beginDrag.y - mainStack.contentY;
                                    plasmoidBackAnim.start();
                                    dragThreshold = Qt.point(-1,-1);
                                }
                                onReleased: event => {
                                    if(held) sendItemBack();
                                }
                                onPressed: event => {
                                    dragHndMa.beginDrag = Qt.point(plasmoidDelegate.x, plasmoidDelegate.y);
                                    dragThreshold = Qt.point(mouseX, mouseY);
                                }
                                onExited: {
                                    if((dragThreshold.x !== -1 && dragThreshold.y !== -1)) {
                                        held = true;
                                    }
                                }
                                onPositionChanged: {
                                    if(dragHndMa.containsPress && (dragThreshold.x !== -1 && dragThreshold.y !== -1)) {
                                        if(Math.abs(dragThreshold.x - mouseX) > 10 || Math.abs(dragThreshold.y - mouseY) > 10) {

                                        }
                                    }
                                    currentDrag = Qt.point(plasmoidContainer.x, plasmoidContainer.y);
                                }
                            }
                        }
                    }
                }
            }

            applet: model.applet

            KSvg.FrameSvgItem {
                anchors.fill: parent
                anchors.topMargin: -Kirigami.Units.smallSpacing * 2
                anchors.bottomMargin: -Kirigami.Units.smallSpacing * 2
                anchors.rightMargin: Kirigami.Units.smallSpacing * 2

                imagePath: "widgets/background"

                visible: applet?.Plasmoid.backgroundHints != 0
                z: -2
            }

            HoverHandler { id: plasmoidMa }

            DropArea {
                id: plasmoidDropArea

                anchors.fill: parent

                visible: !dragHndMa.held

                onEntered: (drag) => {
                    if(drag.source.plasmoidIndex != plasmoidDelegate.plasmoidIndex) {
                        delegateModel.items.move(drag.source.plasmoidIndex, plasmoidDelegate.plasmoidIndex);
                        orderingManager.saveConfiguration();
                    } else return;
                }

                onDropped: {
                    console.log("dropped!!")
                }

                z: 99999999
            }

            onAppletChanged: {
                // console.log("\n\n\n\n\n\n\n\n")

                applet.parent = plasmoidContainer;
                applet.anchors.fill = plasmoidContainer;
                applet.z = -1;
                applet.visible = true;

                plasmoidDelegate.height = mainStack.findPositive(applet?.Layout.preferredHeight, 125);

                plasmoidDelegate.loadingCompleted();
            }
        }
    }

    Item {
        id: containerRect

        anchors.fill: parent

        HoverHandler { id: sidebarMa }

        Rectangle {
            id: bg

            anchors.fill: parent

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }

            opacity: 0.8
            rotation: root.sidebarLocation ? 180 : 0

            Item {
                anchors.left: parent.left

                height: parent.height
                width: 2

                opacity: sidebarMa.hovered ? 0.6 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 2200 }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1

                        color: "black"
                    }
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1

                        color: "white"
                    }
                }
            }

            Rectangle {
                anchors.fill: parent

                color: "white"

                opacity: sidebarMa.hovered ? 0.1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 2200 }
                }

                z: -1
            }
        }

        Item {
            id: sidebarToolbox

            anchors {
                top: parent.top
                topMargin: Kirigami.Units.smallSpacing*2
                right: parent.right
                rightMargin: Kirigami.Units.smallSpacing*2
            }

            Rectangle {
                id: sidebarTlbxContainer

                anchors.right: parent.right

                height: 22
                width: 79

                border.width: 1
                border.color: "white"
                radius: 12

                color: "#214d72"

                opacity: 0.4

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing*2 - Kirigami.Units.smallSpacing/2
                    anchors.rightMargin: Kirigami.Units.smallSpacing*2 - Kirigami.Units.smallSpacing/2

                    KSvg.SvgItem {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        imagePath: Qt.resolvedUrl("svgs/controls.svg")
                        elementId: "add"

                        opacity: addMa.containsMouse ? (addMa.containsPress ? 0.8 : 1) : 0.8

                        KSvg.SvgItem {
                            anchors.fill: parent
                            imagePath: Qt.resolvedUrl("svgs/controls.svg")
                            elementId: "hover"

                            opacity: addMa.containsMouse ? (addMa.containsPress ? 0.8 : 1) : 0.0
                        }

                        MouseArea {
                            id: addMa

                            property QtObject qAction: root.Plasmoid.internalAction("add widgets")

                            anchors.fill: parent

                            hoverEnabled: true
                            propagateComposedEvents: true

                            onClicked: qAction.trigger();
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 12
                        Layout.preferredWidth: 1
                        color: "white"
                    }

                    KSvg.SvgItem {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        imagePath: Qt.resolvedUrl("svgs/controls.svg")
                        elementId: "left"
                        opacity: 0.4
                    }
                    KSvg.SvgItem {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        imagePath: Qt.resolvedUrl("svgs/controls.svg")
                        elementId: "right"
                        opacity: 0.4
                    }
                }
            }

            Rectangle {
                id: addTextBg

                anchors {
                    right: sidebarTlbxContainer.left
                    rightMargin: -Kirigami.Units.smallSpacing*2
                }

                height: 22
                width: addText.implicitWidth + Kirigami.Units.smallSpacing*5

                topLeftRadius: 12
                bottomLeftRadius: 12

                color: "#214d72"

                z: -1
            }

            Item {
                id: addTextBgMask
                anchors.fill: addTextBg
                Rectangle {
                    color: "red"
                    x: addTextBg.width - (Kirigami.Units.smallSpacing * 2)
                    y: 0
                    width: 21
                    height: 21
                    border.color: "black"
                    border.width: 1
                    border.pixelAligned: true
                    radius: 19
                }
            }

            KGraphicalEffects.BadgeEffect {
                id: maskedAddTextBg

                anchors.fill: addTextBg

                source: ShaderEffectSource {
                    sourceItem: addTextBg
                    hideSource: true
                    live: false
                }
                mask: ShaderEffectSource {
                    sourceItem: addTextBgMask
                    hideSource: true
                    live: false
                }

                opacity: addMa.containsMouse ? 0.6 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
            }

            Text {
                id: addText

                anchors.centerIn: addTextBg
                anchors.horizontalCenterOffset: -Kirigami.Units.smallSpacing/2

                text: i18n("Gadgets")
                color: "white"

                opacity: addMa.containsMouse

                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
            }
        }

        ListView {
            id: mainStack

            property bool plasmoidIsBeingDragged: false

            anchors {
                top: sidebarToolbox.bottom
                bottom: parent.bottom
                right: parent.right
                left: parent.left

                topMargin: sidebarTlbxContainer.height + (Kirigami.Units.smallSpacing * 5)
            }

            function findPositive(first, second) { return first > 0 ? first : second }

            displaced: Transition {
                NumberAnimation {
                    properties: "x,y,width,height"
                    easing.type: Easing.Linear
                    duration: 125
                }
            }

            model: delegateModel
            interactive: false
            spacing: 10
        }
    }

    DnD.DropArea {
        anchors.fill: parent

        preventStealing: true

        visible: !mainStack.plasmoidIsBeingDragged

        /** Extracts the name of the applet in the drag data if present
         * otherwise returns null*/
        function appletName(event) {
            if (event.mimeData.formats.indexOf("text/x-plasmoidservicename") < 0) {
                return null;
            }
            var plasmoidId = event.mimeData.getDataAsByteArray("text/x-plasmoidservicename");
            return plasmoidId;
        }

        onDragEnter: (event) => {
            if (!appletName(event)) {
                event.ignore();
            }
        }

        onDrop: (event) => {
            var plasmoidId = appletName(event);
            if (!plasmoidId) {
                event.ignore();
                return;
            }
            plasmoid.newTask(plasmoidId);
        }
    }

    Component.onCompleted: {
        var applets = Containment.applets;
        for (var i = 0 ; i < applets.length; i++) {
            addApplet(applets[i]);
        }
    }
}
