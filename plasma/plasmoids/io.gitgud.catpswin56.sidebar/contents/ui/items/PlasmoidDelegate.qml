/*
 *  SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

import org.kde.plasma.components as PlasmaComponents

import "../controls/"
import "../../applet/" as Applet

PlasmoidItem {
    id: plasmoidDelegate

    required property var model

    property int plasmoidIndex: DelegateModel.itemsIndex
    property Applet.DefaultCompactRepresentation compactRepresentation: null
    property bool isGadget: applet?.plasmoid.pluginName.includes("io.gitgud.catpswin56.gadgets")

    signal loadingCompleted()
    onLoadingCompleted: delegateModel.sort();

    width: mainStack.delegateWidth

    function replaceCompactRepresentation(): void {
        // We can't replace the default compact representation item,
        // so instead, we check if a property of that default item
        // exists in the plasmoid's compact representation. If it
        // does, hide the original compact representation and show
        // our own one.

        var plasmoidItem = applet.compactRepresentationItem.plasmoidItem;
        var objectName = applet.compactRepresentationItem.objectName;

        if(plasmoidItem) {
            var component = Qt.createComponent("../../applet/DefaultCompactRepresentation.qml");
            compactRepresentation = component.createObject(plasmoidItem, {
                                                               plasmoidItem: plasmoidItem,
                                                               z: applet.compactRepresentationItem.z + 1
                                                         });

            applet.compactRepresentationItem.opacity = 0.0;
            plasmoidDelegate.height = 40;
            compactRepresentation.anchors.fill = plasmoidItem;
            compactRepresentation.visible = true;
        }
    }

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
                    parent: windowRoot
                }
            }
        ]

        width: plasmoidDelegate.width
        height: plasmoidDelegate.height

        Drag.active: dragHndMa.held
        Drag.source: dragHndMa
        Drag.hotSpot.x: Math.floor(width / 2.5)
        Drag.hotSpot.y: Math.floor(height / 2.5)

        BorderImage {
            id: plasmoidBg

            anchors.fill: parent
            anchors.leftMargin: !plasmoidDelegate.isGadget ? 10 : 0
            anchors.rightMargin: !plasmoidDelegate.isGadget ? 12 : 0

            border {
                left: 6
                right: 6
                top: 6
                bottom: 6
            }
            source: applet?.plasmoid.backgroundHints != 0 ? "../pngs/gadget-bg.png" : ""

            z: -2
        }

        Item {
            id: representation_container
            objectName: "io.gitgud.catpswin56.sidebar.representation_container"

            anchors.fill: plasmoidBg
            anchors.margins: !plasmoidDelegate.isGadget ? 5 : 0

            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            clip: !plasmoidDelegate.isGadget

            Image {
                id: busy

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -12

                property int frame: 0

                source: "../pngs/loading-circle/loading-" + frame + ".png"

                visible: applet?.plasmoid.busy && !isGadget
                z: 1

                SequentialAnimation {
                    running: busy.visible
                    loops: Animation.Infinite

                    NumberAnimation { target: busy; property: "frame"; to: 17; duration: 900 }
                    NumberAnimation { target: busy; property: "frame"; to: 0; duration: 0 }
                }
            }

            Button {
                anchors.centerIn: parent

                text: i18n("Configure…")
                onClicked: applet?.plasmoid.internalAction("configure").trigger();

                visible: applet?.plasmoid.configurationRequired
                z: 1
            }
        }

        ColumnLayout {
            id: gadgetToolbox

            anchors.right: parent.right
            anchors.top: parent.top

            spacing: 0

            visible: opacity
            opacity: plasmoidMa.hovered || (compactRepresentation?.plasmoidItem.expanded ?? false)
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

            SegmentedControl {
                id: remove

                pixmap: Qt.resolvedUrl("../pngs/gadget-remove.png")
                count: 3
                onClicked: {
                    plasmoidDelegate.applet.plasmoid.internalAction("remove").trigger();
                    appletsModel.remove(model.index, 1);
                }
            }

            SegmentedControl {
                id: configure

                property var action: plasmoidDelegate.applet?.plasmoid.internalAction("configure")

                pixmap: Qt.resolvedUrl("../pngs/gadget-configure.png")
                count: 3
                onClicked: action.trigger()
                visible: action != null
            }

            Image {
                id: drag

                source: Qt.resolvedUrl("../pngs/gadget-drag.png")

                MouseArea {
                    id: dragHndMa

                    anchors.fill: parent

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
                        plasmoidBackAnimX.to = beginDrag.x - mainStack.x;
                        plasmoidBackAnimY.from = currentDrag.y// - taskList.contentY;
                        plasmoidBackAnimY.to = beginDrag.y - (-mainStack.y);
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
                    onExited: if((dragThreshold.x !== -1 && dragThreshold.y !== -1)) held = true;
                    onPositionChanged: currentDrag = Qt.point(plasmoidContainer.x, plasmoidContainer.y);
                }
            }
        }
    }

    applet: model.applet

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

        z: 9999
    }

    onAppletChanged: {
        applet.parent = representation_container;
        applet.anchors.fill = representation_container;
        applet.visible = true;

        if(applet?.Layout.minimumHeight != 1 &&
            applet?.Layout.minimumHeight != 0 &&
            applet?.Layout.minimumHeight != -1)
        {
            plasmoidDelegate.height = Qt.binding(() => applet?.Layout.minimumHeight);
        }

        if(applet?.Layout.preferredHeight != 1 &&
            applet?.Layout.preferredHeight != 0 &&
            applet?.Layout.preferredHeight != -1)
        {
            plasmoidDelegate.height = Qt.binding(() => applet?.Layout.preferredHeight);
        }

        if(plasmoidDelegate.height == 0) plasmoidDelegate.height = mainStack.delegateWidth/2;
        if(applet?.plasmoid.backgroundHints != 0) plasmoidDelegate.height += 10;

        applet?.compactRepresentationItemChanged.connect(replaceCompactRepresentation);

        plasmoidDelegate.loadingCompleted();
    }
}
