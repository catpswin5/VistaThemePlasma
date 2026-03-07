// most qode in here is taken directly or improved from the sidebar plasmoid

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: plasmoid_root

    required property int index

    readonly property string id: applet?.plasmoid.pluginName
    readonly property Item positionManager: parent.positionManager

    // special cases
    property bool isGadget: applet?.plasmoidType == "Gadget"
    property bool isSidebar: applet?.plasmoidType == "Sidebar"
    property bool gadgetResizable: false
    onGadgetResizableChanged: updateSizes();

    property bool checkingPosition: false

    property int minimumWidth: 0
    property int minimumHeight: 0

    property int preferredWidth: 0
    property int preferredHeight: 0

    property int maximumWidth: 0
    property int maximumHeight: 0

    property var applet: null
    onAppletChanged: {
        if(applet) {
            if(isSidebar) {
                plasmoid_root.visible = false;
                applet.isVTPcontainment = true;
                applet.desktopContainment = root;
                applet.appletsLayout = appletsLayout;
                return;
            }

            if(isGadget) {
                gadgetResizable = Qt.binding(() => applet.resizable);
                applet.requestSizeUpdate.connect(updateSizes);
            }

            applet.Plasmoid.destroyedChanged.connect(function() {
               if(applet.Plasmoid.destroyedChanged.destroyed) plasmoid_root.remove();
            });

            applet.parent = representation_container;
            applet.anchors.fill = representation_container;
            applet.visible = true;

            updateSizes();
        }
        else plasmoid_root.remove();
    }

    function remove() {
        if(applet?.plasmoid) applet.plasmoid.internalAction("remove").trigger();
        destroy();
    }

    function updateSizes() {
        if(applet.Layout.minimumWidth) plasmoid_root.minimumWidth = Qt.binding(() => applet?.Layout.minimumWidth);
        if(applet.Layout.minimumHeight) plasmoid_root.minimumHeight = Qt.binding(() => applet?.Layout.minimumHeight);

        if(plasmoid_root.minimumWidth <= 1) plasmoid_root.minimumWidth = Kirigami.Units.gridUnit*8;
        if(plasmoid_root.minimumHeight <= 1) plasmoid_root.minimumHeight = Kirigami.Units.gridUnit*8;

        if(applet.Layout.preferredWidth >= plasmoid_root.minimumWidth) plasmoid_root.preferredWidth = Qt.binding(() => applet?.Layout.preferredWidth);
        if(applet.Layout.preferredHeight >= plasmoid_root.minimumHeight) plasmoid_root.preferredHeight = Qt.binding(() => applet?.Layout.preferredHeight);

        if(isGadget && !gadgetResizable) {
            plasmoid_root.width = Qt.binding(() => minimumWidth);
            plasmoid_root.height = Qt.binding(() => minimumHeight);
        } else {
            plasmoid_root.width = Qt.binding(() => implicitWidth);
            plasmoid_root.height = Qt.binding(() => implicitHeight);
        }
    }

    function correctPositions() {
        plasmoid_root.checkingPosition = true;

        // console.log(x, width, parent.x, parent.width);
        // console.log(y, height, parent.y, parent.height);

        if((parent.width > 0 || parent.height > 0) && (parent.x >= 0 || parent.y >= 0)) {
            // ensure that the plasmoid stays within layout bounds
            if(plasmoid_root.x + plasmoid_root.width > parent.x + parent.width)
                plasmoid_root.x = (parent.x + parent.width) - plasmoid_root.width;
            if(plasmoid_root.y + plasmoid_root.height > parent.y + parent.height)
                plasmoid_root.y = (parent.y + parent.height) - plasmoid_root.height;

            if(plasmoid_root.x < parent.x)
                plasmoid_root.x = parent.x;
            if(plasmoid_root.y < parent.y)
                plasmoid_root.y = parent.y;

        } else {
            waiter.start(); // wait for sizes or positions to be correct
            return;
        }

        plasmoid_root.x = Math.floor(plasmoid_root.x);
        plasmoid_root.y = Math.floor(plasmoid_root.y);

        plasmoid_root.checkingPosition = false;
    }

    onXChanged: {
        if(!checkingPosition) correctPositions();
        positionManager.savePositions();
    }
    onYChanged: {
        if(!checkingPosition) correctPositions();
        positionManager.savePositions();
    }

    readonly property int implicitWidth: (preferredWidth < minimumWidth ? minimumWidth : preferredWidth)
                                       + 15 // idk what this was for ngl
                                       + ((applet?.plasmoid.backgroundHints !== 0 ?? false) ? 10 : 0) // bg border

    readonly property int implicitHeight: (preferredHeight < minimumHeight ? minimumHeight : preferredHeight)
                                        + ((applet?.plasmoid.backgroundHints !== 0 ?? false) ? 10 : 0) // bg border

    width: implicitWidth
    onWidthChanged: {
        if(!checkingPosition) correctPositions();
        positionManager.savePositions();
    }
    height: implicitHeight
    onHeightChanged: {
        if(!checkingPosition) correctPositions();
        positionManager.savePositions();
    }

    Drag.active: dragHndMa.held
    Drag.source: dragHndMa
    Drag.hotSpot.x: Math.floor(width / 2.5)
    Drag.hotSpot.y: Math.floor(height / 2.5)

    function setAbove() {
        if(parent.plasmoid_aboveAll)
            parent.plasmoid_aboveAll.z = 0;

        parent.plasmoid_aboveAll = plasmoid_root;
        parent.plasmoid_aboveAll.z = 1;
    }

    Timer {
        id: waiter

        interval: 100
        repeat: false
        onTriggered: plasmoid_root.correctPositions();
    }

    HoverHandler {
        id: plasmoidMa
        blocking: true
        parent: plasmoid_root
        margin: 1
    }
    TapHandler {
        onPressedChanged: plasmoid_root.setAbove();
    }

    Item {
        id: plasmoidContainer

        anchors.fill: parent

        BorderImage {
            id: plasmoidBg

            anchors.fill: parent
            anchors.rightMargin: 15

            border {
                left: 6
                right: 6
                top: 6
                bottom: 6
            }
            source: (backgroundControl.bgEnabled || !backgroundControl.canConfigureBg) && !isGadget ? "pngs/gadget-bg.png" : ""

            z: -2
        }

        Item {
            id: representation_container
            objectName: "io.gitgud.catpswin56.desktopcontainment.representation_container"

            anchors.fill: plasmoidBg
            anchors.margins: !plasmoid_root.isGadget ? 5 : 0

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: (backgroundControl.bgEnabled || !backgroundControl.canConfigureBg) || isGadget
                                     ? Kirigami.Theme.View : Kirigami.Theme.Complementary

            clip: !plasmoid_root.isGadget

            Loader {
                id: shadow

                anchors.fill: parent

                active: applet && (!backgroundControl.bgEnabled && backgroundControl.canConfigureBg)
                sourceComponent: shadowComponent
                asynchronous: true

                Component {
                    id: shadowComponent

                    MultiEffect {
                        source: applet
                        shadowEnabled: true
                    }
                }
            }
        }

        Image {
            id: busy

            anchors.centerIn: representation_container
            anchors.horizontalCenterOffset: -12

            property int frame: 0

            source: "pngs/loading-circle/loading-" + frame + ".png"

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
            anchors.centerIn: representation_container

            text: i18n("Configure…")
            onClicked: applet?.plasmoid.internalAction("configure").trigger();

            visible: applet?.plasmoid.configurationRequired
            z: 1
        }

        ColumnLayout {
            id: gadgetToolbox

            anchors.right: parent.right
            anchors.top: parent.top

            onHeightChanged: if(plasmoid_root.height < height) plasmoid_root.height += height;

            spacing: 0

            visible: opacity
            opacity: plasmoidMa.hovered
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

            SegmentedControl {
                id: remove

                pixmap: Qt.resolvedUrl("pngs/gadget-remove.png")
                count: 3
                onClicked: plasmoid_root.remove();
            }

            SegmentedControl {
                id: configure

                property var action: plasmoid_root.applet?.plasmoid.internalAction("configure")

                pixmap: Qt.resolvedUrl("pngs/gadget-configure.png")
                count: 3
                onClicked: action.trigger()
                visible: action != null
            }

            SegmentedControl {
                id: backgroundControl

                readonly property bool canConfigureBg: applet?.plasmoid.backgroundHints & PlasmaCore.Types.ConfigurableBackground
                readonly property bool bgEnabled: applet?.plasmoid.userBackgroundHints != PlasmaCore.Types.ShadowBackground

                pixmap: Qt.resolvedUrl("pngs/gadget-background-" + (bgEnabled ? "disabled" : "enabled") + ".png")
                count: 3
                onClicked: {
                    if(bgEnabled) applet.plasmoid.userBackgroundHints = PlasmaCore.Types.ShadowBackground;
                    else applet.plasmoid.userBackgroundHints = applet.plasmoid.backgroundHints;
                }
                visible: canConfigureBg
            }

            Image {
                id: drag

                source: Qt.resolvedUrl("pngs/gadget-drag.png")

                MouseArea {
                    id: dragHndMa

                    anchors.fill: parent

                    property bool held: false

                    property point beginDrag
                    property point currentDrag
                    property point dragThreshold: Qt.point(-1,-1);

                    hoverEnabled: true
                    propagateComposedEvents: true

                    drag.smoothed: false
                    drag.threshold: 0
                    drag.target: held ? plasmoid_root : undefined
                    drag.axis: Drag.XAndYAxis

                    onReleased: event => {
                        if(held) held = false;
                        plasmoid_root.parent.isDragging = false;
                    }
                    onPressed: event => {
                        plasmoid_root.setAbove();
                        dragHndMa.beginDrag = Qt.point(plasmoid_root.x, plasmoid_root.y);
                        dragThreshold = Qt.point(mouseX, mouseY);
                        plasmoid_root.parent.isDragging = true;
                    }
                    onExited: if((dragThreshold.x !== -1 && dragThreshold.y !== -1)) held = true;
                    onPositionChanged: currentDrag = Qt.point(plasmoid_root.x, plasmoid_root.y);
                }
            }
        }
    }

    Item {
        id: dragHandles

        anchors.fill: parent
        anchors.rightMargin: 15

        visible: Plasmoid.corona.editMode && (!isGadget || gadgetResizable)

        ResizeHandle {
            anchors.verticalCenter: parent.bottom
            anchors.horizontalCenter: parent.right
            position: "bottomright"
        }

        ResizeHandle {
            anchors.verticalCenter: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            position: "bottom"
        }

        ResizeHandle {
            anchors.verticalCenter: parent.bottom
            anchors.horizontalCenter: parent.left
            position: "bottomleft"
        }


        ResizeHandle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.left
            position: "left"
        }


        ResizeHandle {
            anchors.verticalCenter: parent.top
            anchors.horizontalCenter: parent.left
            position: "topleft"
        }

        ResizeHandle {
            anchors.verticalCenter: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            position: "top"
        }

        ResizeHandle {
            anchors.verticalCenter: parent.top
            anchors.horizontalCenter: parent.right
            position: "topright"
        }


        ResizeHandle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.right
            position: "right"
        }
    }


    Component.onCompleted: {
        correctPositions();
        if(!isSidebar) parent.plasmoidCreated(plasmoid_root);
    }
}
