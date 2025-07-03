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
import org.kde.plasma.plasma5support as Plasma5Support

import org.kde.graphicaleffects as KGraphicalEffects
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.draganddrop as DnD

import "items"

ContainmentItem {
    id: root

    property var wrapper: null

    // Expose the configuration values for io.gitgud.catpswin56.sidebar
    readonly property int sidebarWidth: Plasmoid.configuration.width
    readonly property int sidebarLocation: Plasmoid.configuration.location

    property bool sidebarCollapsed: Plasmoid.configuration.collapsed

    width: sidebarWidth

    states: [
        State {
            name: "rightSidebar"
            when: root.sidebarLocation == 0 && root.wrapper != null

            AnchorChanges {
                target: root

                anchors.top: root.parent.top
                anchors.bottom: root.parent.bottom
                anchors.left: undefined
                anchors.right: root.parent.right
            }
        },
        State {
            name: "leftSidebar"
            when: root.sidebarLocation == 1 && root.wrapper != null

            AnchorChanges {
                target: root

                anchors.top: root.parent.top
                anchors.bottom: root.parent.bottom
                anchors.left: root.parent.left
                anchors.right: undefined
            }
        }
    ]

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

    Plasma5Support.DataSource {
        id: execEngine
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    SystemTrayIcon {
        id: trayIcon

        icon.name: "gadgets-sidebar"
        menu: Menu {
            MenuItem {
                text: root.sidebarCollapsed ? i18n("Open sidebar") : i18n("Close sidebar")
                onTriggered: Plasmoid.configuration.collapsed = !root.sidebarCollapsed;
            }
            MenuItem {
                text: i18n("Options")
                onTriggered: Plasmoid.internalAction("configure").trigger()
            }
            MenuItem {
                text: i18n("Exit")
                onTriggered: root.wrapper.plasmoid.internalAction("remove").trigger();
            }
        }
        tooltip: "Windows Sidebar"
        onActivated: Plasmoid.configuration.collapsed = !root.sidebarCollapsed;

        visible: !Plasmoid.configuration.disableTrayIcon

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
        delegate: PlasmoidDelegate {  }
    }

    Item {
        id: containerRect

        width: parent.width
        height: parent.height

        visible: yAnimation.duration == 125 && y != Screen.height
        y: root.sidebarCollapsed ? Screen.height : 0
        Behavior on y {
            NumberAnimation { id: yAnimation; duration: 125 }
        }

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

                color: "#173c5c"

                opacity: 0.5

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: (Kirigami.Units.smallSpacing * 2) - 1
                    anchors.rightMargin: anchors.leftMargin

                    spacing: 8

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

                            anchors.fill: parent

                            hoverEnabled: true
                            propagateComposedEvents: true

                            onClicked: execEngine.exec("qdbus6 org.kde.plasmashell /PlasmaShell toggleWidgetExplorer; qdbus6 org.kde.plasmashell /PlasmaShell editMode false");
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: 1

                        color: "white"

                        opacity: 0.4
                    }

                    RowLayout {
                        Layout.leftMargin: -2

                        spacing: 5

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

                            Layout.leftMargin: -1

                            imagePath: Qt.resolvedUrl("svgs/controls.svg")
                            elementId: "right"

                            opacity: 0.4
                        }
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

                color: "#173c5c"

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

                opacity: addMa.containsMouse ? 0.5 : 0

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
