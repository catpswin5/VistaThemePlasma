/*
 *  SPDX-FileCopyrightText: 2011 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *  SPDX-FileCopyrightText: 2025 catpswin56 <>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import Qt.labs.platform

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support

import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.draganddrop as DnD

import "items"

ContainmentItem {
    id: root

    property var desktopContainment: null
    onDesktopContainmentChanged: root.parent = desktopContainment;

    Timer {
        running: desktopContainment == null
        interval: 1
        triggeredOnStart: true
        onTriggered: {
            let item = this;
            while (item.parent) {
                item = item.parent;
                if (item.defaultItemWidth !== undefined) {
                    root.parent.parent = item.parent;
                    root.parent.anchors.bottom = root.parent.parent.top;
                    root.desktopContainment = item.parent;
                }
            }
        }
    }

    readonly property int sidebarWidth: {
        var width = Plasmoid.configuration.width * 10;
        var columnsVisibleFound = false;

        for(var i = 1; !columnsVisibleFound; i++) {
            if(width / i == 150) {
                mainStack.visibleColumns = i;
                columnsVisibleFound = true;
                break;
            }
        }

        if(width > 150) width += mainStack.spacing * (mainStack.visibleColumns - 1);

        return width;
    }
    onSidebarWidthChanged: {
        configureWindow.start();
        mainStack.resetPos();
    }

    readonly property int sidebarLocation: Plasmoid.configuration.location
    onSidebarLocationChanged: configureWindow.start();

    readonly property bool sidebarDock: Plasmoid.configuration.dock
    onSidebarDockChanged: configureWindow.start();

    property bool sidebarCollapsed: Plasmoid.configuration.collapsed

    Containment.onAppletAdded: applet => addApplet(applet);
    Containment.onAppletRemoved: applet => {
        for (var i = 0; i < mainStack.count; i++) {
            if (mainStack.itemAtIndex(i).applet.Plasmoid.id === applet.id) {
                Plasmoid.cleanupTask(applet.id);
                appletsModel.remove(i, 0);
                break;
            }
        }
    }

    // there's probably some sort of better way through C++ but whatever
    function is_panel_bottom() {
        var availableScreenSpace = Plasmoid.availableScreenRect;
        return availableScreenSpace.y == 0 && availableScreenSpace.height !== Screen.height;
    }
    function is_panel_top() {
        var availableScreenSpace = Plasmoid.availableScreenRect;
        return availableScreenSpace.y !== 0 && availableScreenSpace.height !== Screen.height;
    }

    function showGadgetExplorer() {
        execEngine.exec("qdbus6 org.kde.plasmashell /PlasmaShell toggleWidgetExplorer; qdbus6 org.kde.plasmashell /PlasmaShell editMode false");
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

    PlasmaExtras.Menu {
        id: sidebarMenu

        transientParent: window

        PlasmaExtras.MenuItem {
            text: root.sidebarCollapsed ? i18n("Open") : i18n("Close")
            onClicked: window.openClose();
        }

        PlasmaExtras.MenuItem { separator: true }

        PlasmaExtras.MenuItem {
            text: i18n("Bring Gadgets to Front")
            onClicked: window.raise(); // cba to test this under Wayland atm of writing this so praying it works
            enabled: !root.sidebarDock
        }
        PlasmaExtras.MenuItem {
            text: i18n("Add Gadgets...")
            onClicked: root.showGadgetExplorer();
        }

        PlasmaExtras.MenuItem { separator: true }

        PlasmaExtras.MenuItem {
            text: i18n("Properties")
            onClicked: Plasmoid.internalAction("configure").trigger();
        }
        PlasmaExtras.MenuItem {
            text: i18n("Help")
            onClicked: console.log("sidebar: no")
        }

        PlasmaExtras.MenuItem { separator: true }

        PlasmaExtras.MenuItem {
            text: i18n("Exit")
            onClicked: exitDialog.show();
        }
    }

    SystemTrayIcon {
        id: trayIcon

        icon.name: "gadgets-sidebar"
        tooltip: "Windows Sidebar"
        menu: Menu {
            visible: false
            onVisibleChanged: close();
            onAboutToShow: sidebarMenu.open(Plasmoid.cursorPosition().x, Plasmoid.cursorPosition().y);

            MenuItem {
                text: ""
                visible: false
            }
        }
        onActivated: (reason) => {
            if(reason == SystemTrayIcon.Trigger) {
                if(root.sidebarDock) window.openClose();
                else window.raise();
            }
            else sidebarMenu.open(Plasmoid.cursorPosition().x, Plasmoid.cursorPosition().y)
        }

        visible: !Plasmoid.configuration.disableTrayIcon
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

    ExitDialog { id: exitDialog }

    SidebarWindow {
        id: window

        root: root

        Item {
            id: windowRoot

            anchors.fill: parent

            Container {
                id: sidebarContainer

                width: parent.width
                height: parent.height

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: (eventPoint) => {
                        var position = sidebarContainer.mapToGlobal(eventPoint.position.x, eventPoint.position.y)
                        sidebarMenu.open(position.x, position.y)
                    }
                }

                Flow {
                    id: mainStack

                    property bool plasmoidIsBeingDragged: false
                    property int delegateWidth: 150
                    property int currentColumn: 1
                    property int visibleColumns: 1

                    readonly property int columns: {
                        var loop = true;
                        var totalWidth = 0;
                        var count = 1;

                        while(loop) {
                            totalWidth += delegateWidth + spacing;

                            if(totalWidth < width + spacing) count++;
                            else loop = false;
                        }

                        return count;
                    }
                    onColumnsChanged: {
                        if(columns < currentColumn) {
                            var sidebarWidth = root.sidebarWidth;
                            var difference = columns - currentColumn;

                            sidebarWidth = sidebarWidth * difference;
                            sidebarWidth += spacing * difference;

                            mainStack.x -= sidebarWidth;
                            currentColumn += difference;
                        }
                    }

                    readonly property bool can_scrollLeft: currentColumn > 1
                    readonly property bool can_scrollRight: currentColumn < columns && root.sidebarWidth / width != 1

                    anchors {
                        top: parent.top
                        bottom: parent.bottom

                        topMargin: sidebarContainer.toolboxSpace
                    }

                    function findPositive(first, second) { return first > 0 ? first : second }

                    function resetPos() {
                        x = 0;
                        currentColumn = 1;
                    }

                    function scrollLeft() {
                        var sidebarWidth = root.sidebarWidth;

                        if(sidebarWidth > 150) sidebarWidth += spacing * (visibleColumns - 1);
                        else sidebarWidth += spacing * visibleColumns;

                        mainStack.x += sidebarWidth;
                        currentColumn--;
                    }
                    function scrollRight() {
                        var sidebarWidth = root.sidebarWidth;

                        if(sidebarWidth > 150) sidebarWidth += spacing * (visibleColumns - 1);
                        else sidebarWidth += spacing * visibleColumns;

                        mainStack.x -= sidebarWidth;
                        currentColumn++;
                    }

                    flow: Flow.TopToBottom

                    Repeater {
                        model: delegateModel
                    }

                    move: Transition {
                        NumberAnimation {
                            properties: "x,y,width,height"
                            easing.type: Easing.Linear
                            duration: 125
                        }
                    }

                    Behavior on x {
                        NumberAnimation { duration: 125 }
                    }

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
                    Plasmoid.newTask(plasmoidId);
                }
            }
        }
    }

    // delay the configuration on creation so it gets configured correctly
    Timer {
        id: configureWindow

        interval: 100
        onTriggered: {
            window.setPos();
            console.log("sidebar: configuring sidebar window...")
            Plasmoid.configureWindow(window,
                                     Qt.rect(window.x, window.y, root.sidebarWidth, window.height),
                                     root.sidebarDock,
                                     !root.sidebarLocation);
            window.visible = true;
        }
    }

    Component.onCompleted: {
        var applets = Containment.applets;
        for (var i = 0 ; i < applets.length; i++) {
            addApplet(applets[i]);
        }

        window.setPos();
        configureWindow.start();
    }
}
