// most qode in here is taken directly or improved from the sidebar plasmoid

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: containerRoot

    required property int index

    readonly property string id: applet?.plasmoid.pluginName
    readonly property QtObject positionManager: parent.positionManager

    // PositionManager
    readonly property int posIdx: index
    readonly property string posId: id

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
                containerRoot.visible = false;
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
               if(applet.Plasmoid.destroyedChanged.destroyed) containerRoot.remove();
            });

            applet.parent = representation_container;
            applet.anchors.fill = representation_container;
            applet.visible = true;

            updateSizes();
        } else {
            containerRoot.remove();
        }
    }

    function remove() {
        if(applet?.plasmoid) applet.plasmoid.internalAction("remove").trigger();
        destroy();
    }

    function updateSizes() {
        if(applet.Layout.minimumWidth) containerRoot.minimumWidth = Qt.binding(() => applet?.Layout.minimumWidth);
        if(applet.Layout.minimumHeight) containerRoot.minimumHeight = Qt.binding(() => applet?.Layout.minimumHeight);

        if(containerRoot.minimumWidth <= 1) containerRoot.minimumWidth = Kirigami.Units.gridUnit*8;
        if(containerRoot.minimumHeight <= 1) containerRoot.minimumHeight = Kirigami.Units.gridUnit*8;

        if(applet.Layout.preferredWidth >= containerRoot.minimumWidth) containerRoot.preferredWidth = Qt.binding(() => applet?.Layout.preferredWidth);
        if(applet.Layout.preferredHeight >= containerRoot.minimumHeight) containerRoot.preferredHeight = Qt.binding(() => applet?.Layout.preferredHeight);

        if(isGadget && !gadgetResizable) {
            containerRoot.width = Qt.binding(() => minimumWidth);
            containerRoot.height = Qt.binding(() => minimumHeight);
        } else {
            containerRoot.width = Qt.binding(() => implicitWidth);
            containerRoot.height = Qt.binding(() => implicitHeight);
        }
    }

    function correctPositions() {
        containerRoot.checkingPosition = true;

        if((parent.width > 0 || parent.height > 0) && (parent.x >= 0 || parent.y >= 0)) {
            // ensure that the plasmoid stays within layout bounds
            if(containerRoot.x + containerRoot.width > parent.x + parent.width) {
                containerRoot.x = (parent.x + parent.width) - containerRoot.width;
            }
            if(containerRoot.y + containerRoot.height > parent.y + parent.height) {
                containerRoot.y = (parent.y + parent.height) - containerRoot.height;
            }

            if(containerRoot.x < parent.x) {
                containerRoot.x = parent.x;
            }
            if(containerRoot.y < parent.y) {
                containerRoot.y = parent.y;
            }

        } else {
            waiter.start(); // wait for sizes or positions to be correct
            return;
        }

        containerRoot.x = Math.floor(containerRoot.x);
        containerRoot.y = Math.floor(containerRoot.y);

        containerRoot.checkingPosition = false;
    }

    onXChanged: {
        if(!checkingPosition) {
            correctPositions();
        }
    }
    onYChanged: {
        if(!checkingPosition) {
            correctPositions();
        }
    }

    readonly property int implicitWidth: (preferredWidth < minimumWidth ? minimumWidth : preferredWidth)
                                       + 15 // idk what this was for ngl
                                       + ((applet?.plasmoid.backgroundHints !== 0 ?? false) ? 10 : 0) // bg border

    readonly property int implicitHeight: (preferredHeight < minimumHeight ? minimumHeight : preferredHeight)
                                        + ((applet?.plasmoid.backgroundHints !== 0 ?? false) ? 10 : 0) // bg border

    width: implicitWidth
    onWidthChanged: {
        if(!checkingPosition) {
            correctPositions();
        }
    }
    height: implicitHeight
    onHeightChanged: {
        if(!checkingPosition) {
            correctPositions();
        }
    }

    Drag.active: dragHndMa.held
    Drag.source: dragHndMa
    Drag.hotSpot.x: Math.floor(width / 2.5)
    Drag.hotSpot.y: Math.floor(height / 2.5)

    function setAbove() {
        if(parent.plasmoid_aboveAll)
            parent.plasmoid_aboveAll.z = 0;

        parent.plasmoid_aboveAll = containerRoot;
        parent.plasmoid_aboveAll.z = 1;
    }

    Timer {
        id: waiter

        interval: 100
        repeat: false
        onTriggered: containerRoot.correctPositions();
    }

    HoverHandler {
        id: plasmoidMa
        blocking: true
        parent: containerRoot
        margin: 1
    }
    TapHandler {
        onPressedChanged: containerRoot.setAbove();
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
            anchors.margins: !containerRoot.isGadget ? 5 : 0

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: (backgroundControl.bgEnabled || !backgroundControl.canConfigureBg) || isGadget
                                     ? Kirigami.Theme.View : Kirigami.Theme.Complementary

            clip: !containerRoot.isGadget

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

            onHeightChanged: if(containerRoot.height < height) containerRoot.height += height;

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
                onClicked: containerRoot.remove();
            }

            SegmentedControl {
                id: configure

                property var action: containerRoot.applet?.plasmoid.internalAction("configure")

                pixmap: Qt.resolvedUrl("pngs/gadget-configure.png")
                count: 3
                onClicked: action.trigger();

                visible: action != null
            }

            SegmentedControl {
                id: backgroundControl

                readonly property bool canConfigureBg: applet?.plasmoid.backgroundHints & PlasmaCore.Types.ConfigurableBackground
                readonly property bool bgEnabled: applet?.plasmoid.userBackgroundHints != PlasmaCore.Types.ShadowBackground

                pixmap: Qt.resolvedUrl("pngs/gadget-background-" + (bgEnabled ? "disabled" : "enabled") + ".png")
                count: 3
                onClicked: {
                    if(bgEnabled) {
                        applet.plasmoid.userBackgroundHints = PlasmaCore.Types.ShadowBackground;
                    } else {
                        applet.plasmoid.userBackgroundHints = applet.plasmoid.backgroundHints;
                    }
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
                    drag.target: held ? containerRoot : undefined
                    drag.axis: Drag.XAndYAxis

                    onReleased: event => {
                        if(held) held = false;
                        containerRoot.parent.isDragging = false;
                    }
                    onPressed: event => {
                        containerRoot.setAbove();
                        dragHndMa.beginDrag = Qt.point(containerRoot.x, containerRoot.y);
                        dragThreshold = Qt.point(mouseX, mouseY);
                        containerRoot.parent.isDragging = true;
                    }
                    onExited: if((dragThreshold.x !== -1 && dragThreshold.y !== -1)) held = true;
                    onPositionChanged: currentDrag = Qt.point(containerRoot.x, containerRoot.y);
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
    }
}
