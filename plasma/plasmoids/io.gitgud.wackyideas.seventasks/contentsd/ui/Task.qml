/*
    SPDX-FileCopyrightText: 2012-2013 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.draganddrop 2.0

import org.kde.plasma.private.taskmanager 0.1 as TaskManagerApplet

import "code/layout.js" as LayoutManager
import "code/tools.js" as TaskTools
import Qt5Compat.GraphicalEffects


PlasmaCore.ToolTipArea {
    id: task

    anchors.top: parent
    anchors.bottom: parent

    width: plasmoid.configuration.labelVisible == true ? (model.IsLauncher == true ? 62 : 162) : 62
    height: 43

    visible: true
    z: 2
    LayoutMirroring.enabled: (Qt.application.layoutDirection == Qt.RightToLeft)
    LayoutMirroring.childrenInherit: (Qt.application.layoutDirection == Qt.RightToLeft)

    readonly property var m: model

    readonly property int pid: model.AppPid !== undefined ? model.AppPid : 0
    readonly property string appName: model.AppName
    readonly property variant winIdList: model.WinIdList
    property int itemIndex: index
    property bool inPopup: false
    property bool isWindow: model.IsWindow === true
    property int childCount: model.ChildCount !== undefined ? model.ChildCount : 0
    property int previousChildCount: 0
    property alias labelText: label.text
    property bool pressed: false
    property int pressX: -1
    property int pressY: -1
    property QtObject contextMenu: null // Pointer to the regular Qt context menu, which is no longer used (deprecated).
    property QtObject tasksMenu: null // Pointer to the reimplemented context menu.
    property bool tasksMenuOpen: false
    property int wheelDelta: 0
    readonly property bool smartLauncherEnabled: !inPopup && model.IsStartup !== true
    property QtObject smartLauncherItem: null
    property alias toolTipAreaItem: toolTipArea
    property alias audioStreamIconLoaderItem: audioStreamIconLoader
    // The dominant color of the task icon.
    property color hoverColor
    property real taskWidth: 0
    property real taskHeight: 0
    property string previousState: ""
    property bool rightClickDragging: false
    property bool toolTipOpen: false

    property Item audioStreamOverlay
    property var audioStreams: []
    property bool delayAudioStreamIndicator: false
    readonly property bool audioIndicatorsEnabled: plasmoid.configuration.indicateAudioStreams
    readonly property bool hasAudioStream: audioStreams.length > 0
    readonly property bool playingAudio: hasAudioStream && audioStreams.some(function (item) {
        return !item.corked
    })
    readonly property bool muted: hasAudioStream && audioStreams.every(function (item) {
        return item.muted
    })

    active: (Plasmoid.configuration.showToolTips || tasks.toolTipOpenedByClick === task) && !inPopup && !tasksRoot.groupDialog
    interactive: model.IsWindow || mainItem.playerData
    location: Plasmoid.location

    // This property determines when the task should be highlighted.
    // In the context of a task in a default state, it determines when hot tracking should be enabled.
    readonly property bool highlighted: (inPopup && activeFocus) || (!inPopup && ma.containsMouse)
        || (task.contextMenu && task.contextMenu.status === PlasmaComponents.DialogStatus.Open)
        || (groupDialog.visible && groupDialog.visualParent === task)


    onHighlightedChanged: {
        // ensure it doesn't get stuck with a window highlighted
        backend.cancelHighlightWindows();
    }

    // Unused so far.
    function closeTask() {
        closingAnimation.start();
    }
    function showToolTip() {
        toolTipArea.showToolTip();
    }
    function hideToolTipTemporarily() {
        toolTipArea.hideToolTip();
    }
    function updateHoverColor() {
        // Calls the C++ function which calculates the dominant color from the icon.
        hoverColor = Plasmoid.getDominantColor(icon.source)
        // When label visibility is toggled, that changes the size of each task item,
        // so we need to update the size of the hot tracking effect too.
        updateHoverSize();

    }
    function updateHoverSize() {
        hoverGradient.verticalRadius = task.width;
        hoverGradient.horizontalRadius = task.width
    }

    // Updates the hot tracking gradient with the mouse position.
    function updateMousePosition(pos) {
        if(!model.IsStartup)
            hoverGradient.horizontalOffset = pos - hoverRect.width/2;
    }
    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }

    onPidChanged: updateAudioStreams({delay: false})
    onAppNameChanged: updateAudioStreams({delay: false})

    onIsWindowChanged: {
        if (isWindow) {
            taskInitComponent.createObject(task);
        }
        hoverEnabled = true;
    }

    onChildCountChanged: {
        if (!childCount && groupDialog.visualParent == task) {
            groupDialog.visible = false;

            return;
        }

        if (containsMouse) {
            groupDialog.activeTask = null;
        }

        if (childCount > previousChildCount) {
            tasksModel.requestPublishDelegateGeometry(modelIndex(), backend.globalRect(task), task);
        }

        previousChildCount = childCount;
        hoverEnabled = true;
    }

    onItemIndexChanged: {
        hideToolTipTemporarily();

        if (!inPopup && !tasks.vertical
            && (LayoutManager.calculateStripes() > 1 || !plasmoid.configuration.separateLaunchers)) {
            tasks.requestLayout();
        }
        hoverEnabled = true;
        taskList.updateHoverFunc();
        toolTipArea.tooltipClicked = true;
    }

    onContainsMouseChanged:  {

        // Just in case
        if(tasksMenu !== null ) {
            Plasmoid.setMouseGrab(true, tasksMenu);
        }
        if(taskList.firstTimeHover === false) {
            taskList.updateHoverFunc();
            taskList.firstTimeHover = true;
        }
        if (containsMouse) {
            task.forceActiveFocus()
        } else {
            pressed = false;
        }
        hoverEnabled = true;

        updateMousePosition(ma.mouseX);
        toolTipArea.tooltipClicked = true;

    }

    onXChanged: {
        if (!completed) {
            return;
        }
        if (oldX < 0) {
            oldX = x;
            return;
        }
        moveAnim.x = oldX - x + translateTransform.x;
        moveAnim.y = translateTransform.y;
        oldX = x;
        moveAnim.restart();
    }
    onYChanged: {
        if (!completed) {
            return;
        }
        if (oldY < 0) {
            oldY = y;
            return;
        }
        moveAnim.y = oldY - y + translateTransform.y;
        moveAnim.x = translateTransform.x;
        oldY = y;
        moveAnim.restart();
    }

    property real oldX: -1
    property real oldY: -1
    SequentialAnimation {
        id: moveAnim
        property real x
        property real y
        onRunningChanged: {
            if (running) {
                ++task.parent.animationsRunning;
            } else {
                --task.parent.animationsRunning;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: translateTransform
                properties: "x"
                from: moveAnim.x
                to: 0
                easing.type: Easing.OutQuad
                duration: Kirigami.Units.longDuration
            }
            NumberAnimation {
                target: translateTransform
                properties: "y"
                from: moveAnim.y
                to: 0
                easing.type: Easing.OutQuad
                duration: Kirigami.Units.longDuration
            }
        }
    }
    transform: Translate {
        id: translateTransform
    }

    onSmartLauncherEnabledChanged: {
        if (smartLauncherEnabled && !smartLauncherItem) {
            var smartLauncher = Qt.createQmlObject("
    import org.kde.plasma.private.taskmanager 0.1 as TaskManagerApplet;
    TaskManagerApplet.SmartLauncherItem { }", task);

            smartLauncher.launcherUrl = Qt.binding(function() { return model.LauncherUrlWithoutIcon; });

            smartLauncherItem = smartLauncher;
        }
    }

    onHasAudioStreamChanged: {
        audioStreamIconLoader.active = hasAudioStream && audioIndicatorsEnabled;
    }

    onAudioIndicatorsEnabledChanged: {
        audioStreamIconLoader.active = hasAudioStream && audioIndicatorsEnabled;
    }

    Keys.onReturnPressed: TaskTools.activateTask(modelIndex(), model, event.modifiers, task)
    Keys.onEnterPressed: Keys.onReturnPressed(event);

    function modelIndex() {
        return (inPopup ? tasksModel.makeModelIndex(groupDialog.visualParent.itemIndex, index)
            : tasksModel.makeModelIndex(index));
    }

    function disableHover() {
        console.log("\nDisabling hover\n")
        hoverGradient.opacity = task.containsMouse
        borderRect.opacity = task.containsMouse
        blendGradient.opacity = task.containsMouse
        console.log("\nDone\n")
    }

    function showContextMenu(args) {
        toolTipArea.hideImmediately();
        tasksMenu = tasks.createTasksMenu(task, modelIndex(), args);
        tasksMenu.menuDecoration = model.decoration;
        tasksMenu.show();
    }

    function updateAudioStreams(args) {
        if (args) {
            // When the task just appeared (e.g. virtual desktop switch), show the audio indicator
            // right away. Only when audio streams change during the lifetime of this task, delay
            // showing that to avoid distraction.
            delayAudioStreamIndicator = !!args.delay;
        }

        var pa = pulseAudio.item;
        if (!pa) {
            task.audioStreams = [];
            return;
        }

        var streams = pa.streamsForPid(task.pid);
        if (streams.length) {
            pa.registerPidMatch(task.appName);
        } else {
            // We only want to fall back to appName matching if we never managed to map
            // a PID to an audio stream window. Otherwise if you have two instances of
            // an application, one playing and the other not, it will look up appName
            // for the non-playing instance and erroneously show an indicator on both.
            if (!pa.hasPidMatch(task.appName)) {
                streams = pa.streamsForAppName(task.appName);
            }
        }

        task.audioStreams = streams;
    }

    function toggleMuted() {
        if (muted) {
            task.audioStreams.forEach(function (item) { item.unmute(); });
        } else {
            task.audioStreams.forEach(function (item) { item.mute(); });
        }
    }

    Connections {
        target: pulseAudio.item
        ignoreUnknownSignals: true // Plasma-PA might not be available
        function onStreamsChanged() {
            task.updateAudioStreams({delay: true})
        }
    }
    Component {
        id: taskInitComponent

        Timer {
            id: timer

            interval: Kirigami.Units.longDuration
            repeat: false

            onTriggered: {
                if (parent.isWindow) {
                    tasksModel.requestPublishDelegateGeometry(parent.modelIndex(),
                        backend.globalRect(parent), parent);
                }
                timer.destroy();
            }

            Component.onCompleted: {

                taskList.updateHoverFunc();
                timer.start();
            }
        }
    }
    NumberAnimation {
        id: closingAnimation
        target: frame
        properties: "opacity"
        from: 1
        to: 0
        duration: 200

        onRunningChanged: {
            if(!closingAnimation.running) {
                opacity: 1;
            }
        }
    }

    TapHandler {
        id: menuTapHandler
        acceptedButtons: Qt.LeftButton
        acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Stylus
        onLongPressed: {
            // When we're a launcher, there's no window controls, so we can show all
            // places without the menu getting super huge.
            if (model.IsLauncher) {
                showContextMenu({showAllPlaces: true});
                tasksMenuOpen = true;
            } else {
                showContextMenu();
                tasksMenuOpen = true;
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        gesturePolicy: TapHandler.WithinBounds // Release grab when menu appears
        onPressedChanged: if (pressed) contextMenuTimer.start()
    }

    Timer {
        id: contextMenuTimer
        interval: 0
        onTriggered: menuTapHandler.longPressed()
    }

    TapHandler {
        id: leftTapHandler
        acceptedButtons: Qt.LeftButton
        onTapped: leftClick()

        function leftClick(): void {
            if (Plasmoid.configuration.showToolTips && task.active) {
                hideToolTip();
            }
            TaskTools.activateTask(modelIndex(), model, point.modifiers, task, Plasmoid, tasks);
        }
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.MiddleButton) {
                if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.NewInstance) {
                    tasksModel.requestNewInstance(modelIndex());
                } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.Close) {
                    tasksRoot.taskClosedWithMouseMiddleButton = model.WinIdList.slice()
                    tasksModel.requestClose(modelIndex());
                } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.ToggleMinimized) {
                    tasksModel.requestToggleMinimized(modelIndex());
                } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.ToggleGrouping) {
                    tasksModel.requestToggleGrouping(modelIndex());
                } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.BringToCurrentDesktop) {
                    tasksModel.requestVirtualDesktops(modelIndex(), [virtualDesktopInfo.currentDesktop]);
                }
            } else if (button === Qt.BackButton || button === Qt.ForwardButton) {
                const playerData = mpris2Source.playerForLauncherUrl(model.LauncherUrlWithoutIcon, model.AppPid);
                if (playerData) {
                    if (button === Qt.BackButton) {
                        playerData.Previous();
                    } else {
                        playerData.Next();
                    }
                } else {
                    eventPoint.accepted = false;
                }
            }

            backend.cancelHighlightWindows();
        }
    }

    KSvg.SvgItem {
        id: frame
        z: -1
        anchors {
            fill: parent

            topMargin: Kirigami.Units.smallSpacing / 4
            bottomMargin: Kirigami.Units.smallSpacing / 4
            rightMargin: {
                if(stack.visible == true) {
                    if(model.ChildCount == 2) return 7
                        else if(model.ChildCount > 2) return 10
                } else return Kirigami.Units.smallSpacing / 4 + Kirigami.Units.smallSpacing / 4
            }
        }
        KSvg.SvgItem {
            id: stack

            z: 3

            anchors {
                fill: parent
                leftMargin: {
                    if(model.ChildCount == 2) {
                        if(plasmoid.configuration.labelVisible == true) return 155
                        else return 55
                    }
                    else if(model.ChildCount > 2) {
                        if(plasmoid.configuration.labelVisible == true) return 152
                        else return 52
                    }
                }
                rightMargin: {
                    if(model.ChildCount == 2) return -5
                        else if(model.ChildCount > 2) return -8
                }
            }

            imagePath: {
                if(model.ChildCount == 2) {

                    return Qt.resolvedUrl("svgs/tasks/groupdouble.svg")
                }
                else if(model.ChildCount > 2) {
                        return Qt.resolvedUrl("svgs/tasks/grouptriple.svg")
                }
            }

            visible: model.ChildCount > 1
        }

        property bool isPinned: false

        imagePath: {
            if(model.IsActive == true) {
                frame.isPinned = false;
                if(plasmoid.configuration.labelVisible == true) return Qt.resolvedUrl("svgs/tasks/taskLabel_active.svg")
                else return Qt.resolvedUrl("svgs/tasks/task_active.svg")
            }
            else if(model.IsLauncher && task.containsMouse == true) {
                frame.isPinned = true;
                if(leftTapHandler.pressed == true) {
                    return Qt.resolvedUrl("svgs/tasks/pinned_pressed.svg")
                }
                else return Qt.resolvedUrl("svgs/tasks/pinned_hot.svg");
            }
            else if(model.IsLauncher != true) {
                frame.isPinned = false;
                if(plasmoid.configuration.labelVisible == true) return Qt.resolvedUrl("svgs/tasks/taskLabel_normal.svg")
                else return Qt.resolvedUrl("svgs/tasks/task_normal.svg");
            }
            else {
                frame.isPinned = true;
                return ""
            }
        }
        property bool isHovered: task.highlighted && plasmoid.configuration.taskHoverEffect && !rightClickDragging

        DragHandler {
            id: dragHandler
            grabPermissions: PointerHandler.TakeOverForbidden

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

            onActiveChanged: if (active) {
                icon.grabToImage((result) => {
                    if (!dragHandler.active) {
                        // BUG 466675 grabToImage is async, so avoid updating dragSource when active is false
                        return;
                    }
                    setRequestedInhibitDnd(true);
                    tasks.dragSource = task;
                    dragHelper.Drag.imageSource = result.url;
                    dragHelper.Drag.mimeData = {
                        "text/x-orgkdeplasmataskmanager_taskurl": backend.tryDecodeApplicationsUrl(model.LauncherUrlWithoutIcon).toString(),
                                 [model.MimeType]: model.MimeData,
                                 "application/x-orgkdeplasmataskmanager_taskbuttonitem": model.MimeData,
                    };
                    dragHelper.Drag.active = dragHandler.active;
                });
            } else {
                setRequestedInhibitDnd(false);
                dragHelper.Drag.active = false;
                dragHelper.Drag.imageSource = "";
            }
        }

        Rectangle {
            id: hoverRect

            visible: frame.isPinned === true ? false : true

            anchors {
                fill: parent

                topMargin: (!tasks.vertical && taskList.rows > 1) ? Kirigami.Units.smallSpacing / 4 +1 : 1
                bottomMargin: (!tasks.vertical && taskList.rows > 1) ? Kirigami.Units.smallSpacing / 4+1 : 1
                leftMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? Kirigami.Units.smallSpacing / 4 : 1
                rightMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? Kirigami.Units.smallSpacing / 4 : 1
            }
            z: -5
            clip: true
                states: [
                State {
                            name: "startup"; when: (model.IsStartup === true)

                            PropertyChanges { target: hoverRect; opacity: 1}
                            StateChangeScript {
                        script:  {
                            if(previousState === "startup") {
                                hoverGradient.verticalRadius = task.width;
                                hoverGradient.horizontalRadius = task.width;
                            }
                            previousState = "startup";
                        }
                    }

                        },
                        State {
                            name: "startup-finished"; when: (model.IsStartup === false)

                            PropertyChanges { target: hoverRect; opacity: 1}
                            StateChangeScript {
                        script:  {
                            if(previousState === "startup") {
                                hoverGradient.verticalRadius = task.width;
                                hoverGradient.horizontalRadius = task.width;
                            }
                            previousState = "startup";
                        }
                    }

                        },
                State {
                    name: "mouse-over"; when: ((frame.isHovered && frame.basePrefix != "active-tab"))
                    PropertyChanges { target: hoverRect; opacity: 1}
                    StateChangeScript {
                        script:  {
                            if(previousState === "startup") {
                                hoverGradient.verticalRadius = task.width;
                                hoverGradient.horizontalRadius = task.width;
                            }
                            previousState = "mouse-over";
                        }
                    }

                },
                State {
                    name: "";
                    PropertyChanges { target: hoverRect; opacity: 0 }
                    StateChangeScript {
                        script:  {
                            if(previousState === "startup") {
                                hoverGradient.verticalRadius = task.width;
                                hoverGradient.horizontalRadius = task.width;
                            }
                            previousState = "";
                        }
                    }
                }
                ]
                transitions: [ Transition {
                    from: "*"; to: "*";
                    NumberAnimation { properties: "opacity"; easing.type: Easing.InOutQuad; duration: 250 }
                },
                    Transition {
                    from: "*"; to: "startup";
                    NumberAnimation { properties: "opacity"; easing.type: Easing.InOutQuad; duration: 250 }
                    SequentialAnimation {
                        id: horizRad
                        NumberAnimation  {
                            id: horizRad1
                            target: hoverGradient
                            property: "horizontalRadius"
                            from: 0; to: task.width;
                            easing.type: Easing.OutQuad; duration: 400
                    }
                    NumberAnimation  {
                            id: horizRad2
                            target: hoverGradient
                            property: "horizontalRadius"
                            //to: 0;
                            from: task.width; to: 0;
                            easing.type: Easing.InQuad; duration: 550
                    }
                    NumberAnimation  {
                            id: horizRad3
                            target: hoverGradient
                            property: "horizontalRadius"
                            from: 0; to: 0;
                            easing.type: Easing.Linear; duration: 3600
                    }
                    NumberAnimation {
                            id: frameOpacity
                            target: task
                            property: "opacity"
                            from: 1; to: 0;
                            easing.type: Easing.OutCubic; duration: 650
                    }
                    }

                    SequentialAnimation {
                        id: vertiRad
                        NumberAnimation  {
                            id: vertiRad1
                            target: hoverGradient
                            property: "verticalRadius"
                            from: 0; to: task.width;
                            easing.type: Easing.OutQuad; duration: 400
                    }
                    NumberAnimation  {
                            id: vertiRad2
                            target: hoverGradient
                            property: "verticalRadius"
                            from: task.width; to: 0;
                            easing.type: Easing.InQuad; duration: 550
                    }
                    NumberAnimation  {
                            id: vertiRad3
                            target: hoverGradient
                            property: "verticalRadius"
                            from: 0; to: 0;
                            easing.type: Easing.Linear; duration: 1250
                    }
                    NumberAnimation  {
                            id: hoverBorder
                            target: hoverRect
                            property: "opacity"
                            from: 1; to: 0;
                            easing.type: Easing.Linear; duration: 550
                    }
                    }

                } ]
                opacity: 0
                color: "#00000000"
                Rectangle {
                    id: borderRect
                    anchors {
                        fill: parent
                        topMargin: (!tasks.vertical && taskList.rows > 1) ? Kirigami.Units.smallSpacing / 4 : 0
                        bottomMargin: (!tasks.vertical && taskList.rows > 1) ? Kirigami.Units.smallSpacing / 4 : 0
                        leftMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? Kirigami.Units.smallSpacing / 4 : 0
                        rightMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? Kirigami.Units.smallSpacing / 4 : 0
                    }
                    z: -5
                    border.color: Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.4);
                    border.width: 2
                    radius: 2
                    color: "#00000000"
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                    opacity: task.containsMouse
                }

                RadialGradient {
                    id: hoverGradient
                    z: -3
                    anchors {
                    fill: parent
                    topMargin: -2 * Kirigami.Units.smallSpacing
                    leftMargin: -2 * Kirigami.Units.smallSpacing
                    bottomMargin: -2 * Kirigami.Units.smallSpacing
                    rightMargin: -2 * Kirigami.Units.smallSpacing
                    }
                    gradient: Gradient {
                        id: radialGrad
                        GradientStop { position: 0.0; color: Qt.tint(hoverColor, "#CFF8F8F8") }
                        GradientStop { position: 0.4; color: Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.75) }
                        //GradientStop { position: 0.4; color: Qt.tint(hoverColor, "#55AAAAAA") }
                        GradientStop { position: 0.85; color: Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.2) }
                    }
                    verticalOffset: hoverRect.height/2.2
                    horizontalOffset: 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                    opacity: task.containsMouse

                }

                Blend {
                    id: blendGradient
                    anchors.fill: borderRect
                    source: borderRect
                    foregroundSource: hoverGradient
                    mode: "addition"
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                    opacity: task.containsMouse
                }

        }
        PlasmaCore.ToolTipArea {
            id: toolTipArea
            z: -1

            MouseArea {
               id: ma
               hoverEnabled: true
    	       propagateComposedEvents: true
               anchors.fill: parent
               onPositionChanged: {
                   task.updateMousePosition(ma.mouseX);
                   task.positionChanged(mouse);
               }
               onContainsMouseChanged: {
                    task.updateMousePosition(ma.mouseX);
               }
               onPressed: mouse.accepted = false;
               onReleased: mouse.accepted = false;
               onWheel: wheel.accepted = false;
            }
            anchors.fill: parent
            location: plasmoid.location
            property bool tooltipClicked: true
            active: !inPopup && !groupDialog.visible && (plasmoid.configuration.showToolTips || tasks.toolTipOpenedByClick === toolTipArea)
            interactive: model.IsWindow === true

            mainItem: (model.IsWindow === true) ? openWindowToolTipDelegate : pinnedAppToolTipDelegate
            property alias mainToolTip: toolTipArea.mainItem
            onToolTipVisibleChanged: {
                task.toolTipOpen = toolTipVisible;
                if(!toolTipVisible) {
                    tasks.toolTipOpenedByClick = null;
                } else {
                    tasks.toolTipAreaItem = toolTipArea;
                }

            }
            onContainsMouseChanged:  {
                updateMousePosition(ma.mouseX);
                if (containsMouse) {

                    mainItem.parentTask = task;
                    mainItem.rootIndex = tasksModel.makeModelIndex(itemIndex, -1);

                    mainItem.appName = Qt.binding(function() {
                        return model.AppName;
                    });
                    mainItem.pidParent = Qt.binding(function() {
                        return model.AppPid !== undefined ? model.AppPid : 0;
                    });
                    mainItem.windows = Qt.binding(function() {
                        return model.WinIdList;
                    });
                    mainItem.isGroup = Qt.binding(function() {
                        return model.IsGroupParent === true;
                    });
                    mainItem.icon = Qt.binding(function() {
                        return model.decoration;
                    });
                    mainItem.launcherUrl = Qt.binding(function() {
                        return model.LauncherUrlWithoutIcon;
                    });
                    mainItem.isLauncher = Qt.binding(function() {
                        return model.IsLauncher === true;
                    });
                    mainItem.isMinimizedParent = Qt.binding(function() {
                        return model.IsMinimized === true;
                    });
                    mainItem.displayParent = Qt.binding(function() {
                        return model.display;
                    });
                    mainItem.genericName = Qt.binding(function() {
                        return model.GenericName;
                    });
                    mainItem.virtualDesktopParent = Qt.binding(function() {
                        return (model.VirtualDesktops !== undefined && model.VirtualDesktops.length > 0) ? model.VirtualDesktops : [0];
                    });
                    mainItem.isOnAllVirtualDesktopsParent = Qt.binding(function() {
                        return model.IsOnAllVirtualDesktops === true;
                    });
                    mainItem.activitiesParent = Qt.binding(function() {
                        return model.Activities;
                    });

                    mainItem.smartLauncherCountVisible = Qt.binding(function() {
                        return task.smartLauncherItem && task.smartLauncherItem.countVisible;
                    });
                    mainItem.smartLauncherCount = Qt.binding(function() {
                        return mainItem.smartLauncherCountVisible ? task.smartLauncherItem.count : 0;
                    });
                    tasks.toolTipAreaItem = toolTipArea;
                    task.forceActiveFocus(Qt.MouseFocusReason);
                    task.updateMainItemBindings();
                } else {
                    tasks.toolTipOpenedByClick = null;
                }
            }
        }
    }


    Loader {
        anchors.fill: frame
        asynchronous: true
        source: "TaskProgressOverlay.qml"
        active: task.isWindow && task.smartLauncherItem && task.smartLauncherItem.progressVisible
        z: -7
    }
    Item {
        id: iconBox

        anchors {
            fill: frame

            topMargin: leftTapHandler.pressed == true ? 3 : 0
            rightMargin: plasmoid.configuration.labelVisible == true ? (model.IsLauncher == true ? 0 : 115) : 0
            leftMargin: plasmoid.configuration.labelVisible == true ? (model.IsLauncher == true ? 0 : 5) : 0
        }

        width: 0
        height: {
            if(parent.height <= 30) {
                return Kirigami.Units.iconSizes.small;
            } else {
                return (parent.height - adjustMargin(false, parent.height, taskFrame.margins.top) - adjustMargin(false, parent.height, taskFrame.margins.bottom));
            }
        }

        function adjustMargin(vert, size, margin) {
            if (!size) {
                return margin;
            }

            var margins = vert ? LayoutManager.horizontalMargins() : LayoutManager.verticalMargins();

            if ((size - margins) < Kirigami.Units.iconSizes.small) {
                return Math.ceil((margin * (Kirigami.Units.iconSizes.small / size)) / 2);
            }
            return margin;
        }


        Kirigami.Icon {
            id: icon

            enabled: true

            source: model.decoration

            anchors.fill: parent
            anchors.topMargin: ((pressed) ? Kirigami.Units.smallSpacing / 5 : 0)

            onSourceChanged: {
                updateHoverColor();
            }
        }

        states: [
            // Using a state transition avoids a binding loop between label.visible and
            // the text label margin, which derives from the icon width.
            State {
                name: "standalone"
                when: !label.visible

                AnchorChanges {
                    target: iconBox
                    anchors.left: undefined
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                PropertyChanges {
                    target: iconBox
                    anchors.leftMargin: 0
                    width: parent.width - adjustMargin(true, task.width, taskFrame.margins.left)
                                        - adjustMargin(true, task.width, taskFrame.margins.right)
                }
            }
        ]
    }

    Loader {
        id: audioStreamIconLoader

        readonly property bool shown: item && item.visible
        readonly property var indicatorScale: 1.2

        source: "AudioStream.qml"
        width: Math.min(Math.min(iconBox.width, iconBox.height) * 0.4, Kirigami.Units.iconSizes.smallMedium)
        height: width

        anchors {
            right: frame.right
            top: frame.top
            rightMargin: (parent.height <= 30) ? Kirigami.Units.smallSpacing : taskFrame.margins.right
            topMargin: Math.round(taskFrame.margins.top * indicatorScale)
        }

    }

    PlasmaComponents.Label {
        id: label

        visible: plasmoid.configuration.labelVisible // don't even bother

        anchors {
            fill: frame
            leftMargin: taskFrame.margins.left + iconBox.width + Kirigami.Units.smallSpacing
            topMargin: taskFrame.margins.top
            rightMargin: taskFrame.margins.right + (audioStreamIconLoader.shown ? (audioStreamIconLoader.width + Kirigami.Units.smallSpacing) : 0)
            bottomMargin: taskFrame.margins.bottom
        }

        text: model.display
        wrapMode: (maximumLineCount == 1) ? Text.NoWrap : Text.Wrap
        elide: Text.ElideRight
        textFormat: Text.PlainText
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: plasmoid.configuration.maxTextLines || undefined
        style: Text.Outline
        styleColor: "#20404040"
    }

    states: [
        State {
            name: "launcher"
            when: model.IsLauncher === true

            PropertyChanges {
                target: frame
                basePrefix: "active-tab"
            }
        },
        State {
            name: "attention"
            when: model.IsDemandingAttention === true || (task.smartLauncherItem && task.smartLauncherItem.urgent)

            PropertyChanges {
                target: frame
                imagePath: Qt.resolvedUrl("svgs/tasks/task_attention.svg")
            }
        },
        State {
            name: "minimized"
            when: model.IsMinimized === true

            PropertyChanges {
                target: frame
                basePrefix: "minimized"
            }
        },
        State {
            name: "active"
            when: model.IsActive === true

            PropertyChanges {
                target: frame
                basePrefix: "focus"
            }
        }

    ]

    Component.onCompleted: {

        if (!inPopup && model.IsWindow !== true) {
            taskInitComponent.createObject(task);
        }
        taskList.updateHoverFunc();
        updateAudioStreams({delay: false});
    }
}
