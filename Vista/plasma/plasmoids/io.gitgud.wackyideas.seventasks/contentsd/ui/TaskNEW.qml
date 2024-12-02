/*
    SPDX-FileCopyrightText: 2012-2013 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.taskmanager 0.1 as TaskManagerApplet
import org.kde.plasma.plasmoid 2.0

import "code/layout.js" as LayoutMetrics
import "code/tools.js" as TaskTools

PlasmaCore.ToolTipArea {
    id: task

    activeFocusOnTab: true

    // To achieve a bottom to top layout, the task manager is rotated by 180 degrees(see main.qml).
    // This makes the tasks mirrored, so we mirror them again to fix that.
    rotation: Plasmoid.configuration.reverseMode && Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 180 : 0

    implicitHeight: inPopup
                    ? LayoutMetrics.preferredHeightInPopup()
                    : Math.max(tasksRoot.height / tasksRoot.plasmoid.configuration.maxStripes,
                             LayoutMetrics.preferredMinHeight())
    Layout.preferredWidth: Plasmoid.configuration.showAppLabels == true ? model.IsLauncher == false ? 150 : 60 : 60

    Layout.maximumHeight: tasksRoot.vertical ? LayoutMetrics.preferredMaxHeight() : -1
    Layout.rightMargin: 2

    required property var model
    required property int index
    required property Item tasksRoot

    readonly property int pid: model.AppPid
    readonly property string appName: model.AppName
    readonly property string appId: model.AppId.replace(/\.desktop/, '')
    readonly property bool isIcon: false
    property bool toolTipOpen: false
    property color hoverColor
    property bool inPopup: false
    property bool isWindow: model.IsWindow
    property int childCount: model.ChildCount
    property QtObject tasksMenu: null // Pointer to the reimplemented context menu.
    property int previousChildCount: 0
    property alias labelText: label.text
    property QtObject contextMenu: null
    readonly property bool smartLauncherEnabled: !inPopup && !model.IsStartup
    property QtObject smartLauncherItem: null

    property Item audioStreamIcon: null
    property var audioStreams: []
    property bool delayAudioStreamIndicator: false
    property bool completed: false
    readonly property bool audioIndicatorsEnabled: Plasmoid.configuration.indicateAudioStreams
    readonly property bool hasAudioStream: audioStreams.length > 0
    readonly property bool playingAudio: hasAudioStream && audioStreams.some(function (item) {
        return !item.corked
    })
    readonly property bool muted: hasAudioStream && audioStreams.every(function (item) {
        return item.muted
    })

    active: (Plasmoid.configuration.showToolTips || tasksRoot.toolTipOpenedByClick === task) && !inPopup && !tasksRoot.groupDialog
    interactive: model.IsWindow || mainItem.playerData
    location: Plasmoid.location
    mainItem: model.IsWindow ? openWindowToolTipDelegate : pinnedAppToolTipDelegate

    function updateHoverColor() {
        // Calls the C++ function which calculates the dominant color from the icon.
        hoverColor = Plasmoid.getDominantColor(icon.source)
        // When label visibility is toggled, that changes the size of each task item,
        // so we need to update the size of the hot tracking effect too.
        updateHoverSize();

    }

    function updateHoverSize() {
        hoverGradient.verticalRadius = LayoutManager.taskHeight();
        hoverGradient.horizontalRadius = LayoutManager.taskWidth();
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
                duration: 200
            }
            NumberAnimation {
                target: translateTransform
                properties: "y"
                from: moveAnim.y
                to: 0
                easing.type: Easing.OutQuad
                duration: 200
            }
        }
    }
    transform: Translate {
        id: translateTransform
    }

    Accessible.name: model.display
    Accessible.description: {
        if (!model.display) {
            return "";
        }

        if (model.IsLauncher) {
            return i18nc("@info:usagetip %1 application name", "Launch %1", model.display)
        }

        let smartLauncherDescription = "";
        if (iconBox.active) {
            smartLauncherDescription += i18ncp("@info:tooltip", "There is %1 new message.", "There are %1 new messages.", task.smartLauncherItem.count);
        }

        if (model.IsGroupParent) {
            switch (Plasmoid.configuration.groupedTaskVisualization) {
            case 0:
                break; // Use the default description
            case 1: {
                if (Plasmoid.configuration.showToolTips) {
                    return `${i18nc("@info:usagetip %1 task name", "Show Task tooltip for %1", model.display)}; ${smartLauncherDescription}`;
                }
                // fallthrough
            }
            case 2: {
                if (effectWatcher.registered) {
                    return `${i18nc("@info:usagetip %1 task name", "Show windows side by side for %1", model.display)}; ${smartLauncherDescription}`;
                }
                // fallthrough
            }
            default:
                return `${i18nc("@info:usagetip %1 task name", "Open textual list of windows for %1", model.display)}; ${smartLauncherDescription}`;
            }
        }

        return `${i18n("Activate %1", model.display)}; ${smartLauncherDescription}`;
    }
    Accessible.role: Accessible.Button
    Accessible.onPressAction: leftTapHandler.leftClick()

    onToolTipVisibleChanged: toolTipVisible => {
                                 task.toolTipOpen = toolTipVisible;
                                 if (!toolTipVisible) {
                                     tasksRoot.toolTipOpenedByClick = null;
                                 } else {
                                     tasksRoot.toolTipAreaItem = task;
                                 }
                             }

    onContainsMouseChanged: if (containsMouse) {
                                task.forceActiveFocus(Qt.MouseFocusReason);
                                task.updateMainItemBindings();
                            } else {
                                tasksRoot.toolTipOpenedByClick = null;
                            }

    onPidChanged: updateAudioStreams({delay: false})
    onAppNameChanged: updateAudioStreams({delay: false})

    onIsWindowChanged: {
        if (model.IsWindow) {
            taskInitComponent.createObject(task);
            updateAudioStreams({delay: false});
        }
    }

    // onChildCountChanged: {
    //     if (TaskTools.taskManagerInstanceCount < 2 && childCount > previousChildCount) {
    //         tasksModel.requestPublishDelegateGeometry(modelIndex(), backend.globalRect(task), task);
    //     }
    //
    //     previousChildCount = childCount;
    // }

    onIndexChanged: {
        hideToolTip();

        if (!inPopup && !tasksRoot.vertical
                && !Plasmoid.configuration.separateLaunchers) {
            tasksRoot.requestLayout();
        }
    }

    onSmartLauncherEnabledChanged: {
        if (smartLauncherEnabled && !smartLauncherItem) {
            const smartLauncher = Qt.createQmlObject(`
import org.kde.plasma.private.taskmanager 0.1 as TaskManagerApplet

TaskManagerApplet.SmartLauncherItem { }
`, task);

            smartLauncher.launcherUrl = Qt.binding(() => model.LauncherUrlWithoutIcon);

            smartLauncherItem = smartLauncher;
        }
    }

    onHasAudioStreamChanged: {
        const audioStreamIconActive = hasAudioStream && audioIndicatorsEnabled;
        if (!audioStreamIconActive) {
            if (audioStreamIcon !== null) {
                audioStreamIcon.destroy();
                audioStreamIcon = null;
            }
            return;
        }
        // Create item on demand instead of using Loader to reduce memory consumption,
        // because only a few applications have audio streams.
        const component = Qt.createComponent("AudioStream.qml");
        audioStreamIcon = component.createObject(task);
        component.destroy();
    }
    onAudioIndicatorsEnabledChanged: task.hasAudioStreamChanged()

    Keys.onMenuPressed: contextMenuTimer.start()
    Keys.onReturnPressed: TaskTools.activateTask(modelIndex(), model, event.modifiers, task, Plasmoid, tasksRoot, effectWatcher.registered)
    Keys.onEnterPressed: Keys.returnPressed(event);
    Keys.onSpacePressed: Keys.returnPressed(event);
    Keys.onUpPressed: Keys.leftPressed(event)
    Keys.onDownPressed: Keys.rightPressed(event)
    Keys.onLeftPressed: if (!inPopup && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
                            tasksModel.move(task.index, task.index - 1);
                        } else {
                            event.accepted = false;
                        }
    Keys.onRightPressed: if (!inPopup && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
                             tasksModel.move(task.index, task.index + 1);
                         } else {
                             event.accepted = false;
                         }

    function modelIndex() {
        return (inPopup ? tasksModel.makeModelIndex(groupDialog.visualParent.index, index)
                        : tasksModel.makeModelIndex(index));
    }

    function showContextMenu(args) {
        task.hideImmediately();
        contextMenu = tasksRoot.createContextMenu(task, modelIndex(), args);
        contextMenu.show();
    }

    // function showContextMenu(args) {
    //     task.hideImmediately();
    //     tasksRoot = tasks
    //     tasksMenu = tasksRoot.createTasksMenu(task, modelIndex(), args);
    //     tasksMenu.menuDecoration = model.decoration;
    //     tasksMenu.show();
    //     // hoverGradient.opacity = 1
    //     // borderRect.opacity = 1
    //     // blendGradient.opacity = 1
    //
    //     //contextMenu = tasks.createContextMenu(task, modelIndex(), args);
    //     //contextMenu.show();
    // }

    function updateAudioStreams(args) {
        if (args) {
            // When the task just appeared (e.g. virtual desktop switch), show the audio indicator
            // right away. Only when audio streams change during the lifetime of this task, delay
            // showing that to avoid distraction.
            delayAudioStreamIndicator = !!args.delay;
        }

        var pa = pulseAudio.item;
        if (!pa || !task.isWindow) {
            task.audioStreams = [];
            return;
        }

        // Check appid first for app using portal
        // https://docs.pipewire.org/page_portal.html
        var streams = pa.streamsForAppId(task.appId);
        if (!streams.length) {
            streams = pa.streamsForPid(model.AppPid);
            if (streams.length) {
                pa.registerPidMatch(model.AppName);
            } else {
                // We only want to fall back to appName matching if we never managed to map
                // a PID to an audio stream window. Otherwise if you have two instances of
                // an application, one playing and the other not, it will look up appName
                // for the non-playing instance and erroneously show an indicator on both.
                if (!pa.hasPidMatch(model.AppName)) {
                    streams = pa.streamsForAppName(model.AppName);
                }
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

    // Will also be called in activateTaskAtIndex(index)
    function updateMainItemBindings() {
        if ((mainItem.parentTask === task && mainItem.rootIndex.row === task.index) || (tasksRoot.toolTipOpenedByClick === null && !task.active) || (tasksRoot.toolTipOpenedByClick !== null && tasksRoot.toolTipOpenedByClick !== task)) {
            return;
        }

        mainItem.blockingUpdates = (mainItem.isGroup !== model.IsGroupParent); // BUG 464597 Force unload the previous component

        mainItem.parentTask = task;
        mainItem.rootIndex = tasksModel.makeModelIndex(index, -1);

        mainItem.appName = Qt.binding(() => model.AppName);
        mainItem.pidParent = Qt.binding(() => model.AppPid);
        mainItem.windows = Qt.binding(() => model.WinIdList);
        mainItem.isGroup = Qt.binding(() => model.IsGroupParent);
        mainItem.icon = Qt.binding(() => model.decoration);
        mainItem.launcherUrl = Qt.binding(() => model.LauncherUrlWithoutIcon);
        mainItem.isLauncher = Qt.binding(() => model.IsLauncher);
        mainItem.isMinimizedParent = Qt.binding(() => model.IsMinimized);
        mainItem.displayParent = Qt.binding(() => model.display);
        mainItem.genericName = Qt.binding(() => model.GenericName);
        mainItem.virtualDesktopParent = Qt.binding(() => model.VirtualDesktops);
        mainItem.isOnAllVirtualDesktopsParent = Qt.binding(() => model.IsOnAllVirtualDesktops);
        mainItem.activitiesParent = Qt.binding(() => model.Activities);

        mainItem.smartLauncherCountVisible = Qt.binding(() => task.smartLauncherItem && task.smartLauncherItem.countVisible);
        mainItem.smartLauncherCount = Qt.binding(() => mainItem.smartLauncherCountVisible ? task.smartLauncherItem.count : 0);

        mainItem.blockingUpdates = false;
        tasksRoot.toolTipAreaItem = task;
    }

    Connections {
        target: pulseAudio.item
        ignoreUnknownSignals: true // Plasma-PA might not be available
        function onStreamsChanged() {
            task.updateAudioStreams({delay: true})
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
                showContextMenu({showAllPlaces: true})
            } else {
                showContextMenu();
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
            TaskTools.activateTask(modelIndex(), model, point.modifiers, task, Plasmoid, tasksRoot, effectWatcher.registered);
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

    KSvg.FrameSvgItem {
        id: frame

        anchors {
            fill: parent

            rightMargin: {
                if(stack.visible == true) {
                    if(model.ChildCount == 2) return 5
                    else if(model.ChildCount > 2) return 8
                } else return 0
            }
        }

        imagePath: model.IsLauncher == true ? Qt.resolvedUrl("svgs/tabbar.svgz") : Qt.resolvedUrl("svgs/tasks.svg")
        property string basePrefix: "normal"
        prefix: {
            if(task.containsMouse && model.IsLauncher == true) return "active-tab"
            else if(model.IsActive == true) return "focus"
            else return "normal"
        }

        // Rectangle {
        //     anchors.fill: parent
        //     z: -1
        //     color: "white"
        //     Text {
        //         text: "Two Apps."
        //     }
        //     visible: model.ChildCount > 1
        // }
        KSvg.SvgItem {
            id: stack

            z: 3

            anchors {
                fill: parent
                leftMargin: {
                    if(model.ChildCount == 2) return 55
                    else if(model.ChildCount > 2) return 52
                }
                rightMargin: {
                    if(model.ChildCount == 2) return -5
                    else if(model.ChildCount > 2) return -8
                }
            }

            imagePath: {
                if(model.ChildCount == 2) {
                    if(model.IsActive == true) return Qt.resolvedUrl("svgs/groupdouble-select.svg")
                    else return Qt.resolvedUrl("svgs/groupdouble.svg")
                }
                else if(model.ChildCount > 2) {
                    if(model.IsActive == true) return Qt.resolvedUrl("svgs/grouptriple-select.svg")
                    else return Qt.resolvedUrl("svgs/grouptriple.svg")
                }
            }

            visible: model.ChildCount > 1
        }

        // Avoid repositioning delegate item after dragFinished
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
                                                      tasksRoot.dragSource = task;
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

            anchors.fill: parent

            // visible: false // Disabled for now.
            visible: model.IsLauncher == true ? false : true

            anchors {
                fill: parent

                topMargin: (!tasks.vertical && taskList.rows > 1) ? Kirigami.Units.smallSpacing / 4 +1 : 1
                bottomMargin: (!tasks.vertical && taskList.rows > 1) ? Kirigami.Units.smallSpacing / 4+1 : 1
                leftMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? Kirigami.Units.smallSpacing / 4+1 : 1
                rightMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? Kirigami.Units.smallSpacing / 4+1 : 1
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
                                hoverGradient.verticalRadius = LayoutMetrics.taskHeight();
                                hoverGradient.horizontalRadius = LayoutMetrics.taskWidth();
                            }
                            previousState = "startup";
                            //console.log("\nTurned to startup state\n" + previousState);
                        }
                    }

                },
                State {
                    name: "startup-finished"; when: (model.IsStartup === false)

                    PropertyChanges { target: hoverRect; opacity: 1}
                    StateChangeScript {
                        script:  {
                            if(previousState === "startup") {
                                hoverGradient.verticalRadius = LayoutMetrics.taskHeight();
                                hoverGradient.horizontalRadius = LayoutMetrics.taskWidth();
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
                                hoverGradient.verticalRadius = LayoutMetrics.taskHeight();
                                hoverGradient.horizontalRadius = LayoutMetrics.taskWidth();
                            }
                            previousState = "mouse-over";
                            //console.log("\nTurned to mouseover state\n" + previousState);
                        }
                    }

                },
                State {
                    name: "";
                    PropertyChanges { target: hoverRect; opacity: 0 }
                    StateChangeScript {
                        script:  {
                            if(previousState === "startup") {
                                hoverGradient.verticalRadius = LayoutMetrics.taskHeight();
                                hoverGradient.horizontalRadius = LayoutMetrics.taskWidth();
                            }
                            previousState = "";
                            //console.log("\nTurned to default state\n" + previousState);
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
                        from: 0; to: LayoutMetrics.taskWidth();//task.height + taskFrame.margins.left + taskFrame.margins.right;
                        easing.type: Easing.OutQuad; duration: 400
                    }
                    /*NumberAnimation  {
                     *               id: horizRad11
                     *               target: hoverGradient
                     *               property: "horizontalRadius"
                     *               from: LayoutMetrics.taskWidth(); to: LayoutMetrics.taskWidth();//task.height + taskFrame.margins.left + taskFrame.margins.right;
                     *               easing.type: Easing.Linear; duration:
                }*/
                    NumberAnimation  {
                        id: horizRad2
                        target: hoverGradient
                        property: "horizontalRadius"
                        //to: 0;
                        from: LayoutMetrics.taskWidth()/*task.height + taskFrame.margins.left + taskFrame.margins.right*/; to: 0;
                        easing.type: Easing.InQuad; duration: 550
                    }
                    NumberAnimation  {
                        id: horizRad3
                        target: hoverGradient
                        property: "horizontalRadius"
                        //to: 0;
                        from: 0; to: 0; //LayoutMetrics.taskWidth()/*task.height + taskFrame.margins.left + taskFrame.margins.right*/; to: 0;
                        easing.type: Easing.Linear; duration: 3600
                    }
                    NumberAnimation {
                        id: frameOpacity
                        target: task
                        property: "opacity"
                        from: 1; to: 0;
                        easing.type: Easing.OutCubic; duration: 650
                    }
                    //loops: 3
                }

                SequentialAnimation {
                    id: vertiRad
                    NumberAnimation  {
                        id: vertiRad1
                        target: hoverGradient
                        property: "verticalRadius"
                        from: 0; to: LayoutMetrics.taskHeight();
                        easing.type: Easing.OutQuad; duration: 400
                    }
                    /*NumberAnimation  {
                     *               id: vertiRad11
                     *               target: hoverGradient
                     *               property: "verticalRadius"
                     *               from: LayoutMetrics.taskHeight(); to: LayoutMetrics.taskHeight();
                     *               easing.type: Easing.Linear; duration: 50
                }*/
                    NumberAnimation  {
                        id: vertiRad2
                        target: hoverGradient
                        property: "verticalRadius"
                        from: LayoutMetrics.taskHeight(); to: 0;
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
                    //loops: 3
                }

            } ]
            opacity: 0//(frame.isHovered && frame.basePrefix != "") ? 1.0 : 0
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
                //border.color: Qt.tint(hoverColor, "#22777777")
                border.width: 2
                radius: 2
                color: "purple"
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
                    /*topMargin: (!tasks.vertical && taskList.rows > 1) ? -PlasmaCore.Units.smallSpacing / 4 : 0
                     *       bottomMargin: (!tasks.vertical && taskList.rows > 1) ? -PlasmaCore.Units.smallSpacing / 4 : 0
                     *       leftMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? PlasmaCore.Units.smallSpacing / 4 : 0
                     *       rightMargin: ((inPopup || tasks.vertical) && taskList.columns > 1) ? -PlasmaCore.Units.smallSpacing / 4 : 0*/
                }
                gradient: Gradient {
                    id: radialGrad
                    GradientStop { position: 0.0; color: Qt.tint(hoverColor, "#CFF8F8F8") }
                    GradientStop { position: 0.4; color: Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.75) }
                    //GradientStop { position: 0.4; color: Qt.tint(hoverColor, "#55AAAAAA") }
                    GradientStop { position: 0.85; color: Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.2) }
                }
                verticalOffset: 5000
                horizontalOffset: 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
                opacity: task.containsMouse
                //hoverGradient.horizontalOffset = task.mouseX - hoverRect.width/2

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
            //z: -1

        }
    }

    Loader {
        id: taskProgressOverlayLoader

        z: -1

        anchors.fill: frame
        asynchronous: true
        active: model.IsWindow && task.smartLauncherItem && task.smartLauncherItem.progressVisible

        source: "TaskProgressOverlay.qml"
    }
    // MouseArea {
    //     anchors.fill: parent
    //     onPressed: {
    //         iconBox.anchors.topMargin = 1
    //     }
    //     onReleased: {
    //         iconBox.anchors.topMargin = 0
    //     }
    //     onClicked: {
    //         leftTapHandler.leftClick()
    //     }
        Loader {
            id: iconBox

            anchors {
                fill: frame
            }

            asynchronous: true
            active: height >= Kirigami.Units.iconSizes.small
                    && task.smartLauncherItem && task.smartLauncherItem.countVisible

            Kirigami.Icon {
                id: icon

                anchors {
                    centerIn: parent
                }

                width: 32
                height: 32

                active: task.highlighted
                enabled: true

                source: model.decoration
            }

            states: [
                // Using a state transition avoids a binding loop between label.visible and
                // the text label margin, which derives from the icon width.
                State {
                    name: "standalone"
                    when: !label.visible && task.parent

                    AnchorChanges {
                        target: iconBox
                        anchors.left: undefined
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    PropertyChanges {
                        target: iconBox
                        anchors.leftMargin: 0
                        width: Math.min(task.parent.minimumWidth, tasks.height) - adjustMargin(true, task.width, taskFrame.margins.left)
                                            - adjustMargin(true, task.width, taskFrame.margins.right)
                    }
                }
            ]

            Loader {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                active: model.IsStartup
                sourceComponent: busyIndicator
            }
        }
    // }

    PlasmaComponents3.Label {
        id: label

        visible: Plasmoid.configuration.showAppLabels == false ? false : model.IsLauncher == true ? false : true

        anchors {
            fill: parent
            leftMargin: taskFrame.margins.left + iconBox.width + LayoutMetrics.labelMargin
            topMargin: taskFrame.margins.top
            rightMargin: taskFrame.margins.right + (audioStreamIcon !== null && audioStreamIcon.visible ? (audioStreamIcon.width + LayoutMetrics.labelMargin) : 0)
            bottomMargin: taskFrame.margins.bottom
        }

        elide: Text.ElideRight
        textFormat: Text.PlainText
        verticalAlignment: Text.AlignVCenter
        maximumLineCount: Plasmoid.configuration.maxTextLines || undefined
        width: 10

        Accessible.ignored: true

        // use State to avoid unnecessary re-evaluation when the label is invisible
        states: State {
            name: "labelVisible"
            when: label.visible

            PropertyChanges {
                target: label
                text: model.display
            }
        }
    }

    states: [
        /*State {
            name: "launcher"
            when: model.IsLauncher

            PropertyChanges {
                target: frame
                imagePath: Qt.resolvedUrl("svgs/tabbar.svgz")
                basePrefix: "active"
            }
        },*/
        State {
            name: "attention"
            when: model.IsDemandingAttention || (task.smartLauncherItem && task.smartLauncherItem.urgent)

            PropertyChanges {
                target: frame
                basePrefix: "attention"
            }
        },
        State {
            name: "minimized"
            when: model.IsMinimized

            PropertyChanges {
                target: frame
                basePrefix: "minimized"
            }
        },
        State {
            name: "active"
            when: model.IsActive

            PropertyChanges {
                target: frame
                basePrefix: "focus"
            }
        }
    ]

    Component.onCompleted: {
        if (!inPopup && model.IsWindow) {
            // var component = Qt.createComponent("GroupExpanderOverlay.qml");
            // component.createObject(task);
            // component.destroy();
            updateAudioStreams({delay: false});
        }

        if (!inPopup && !model.IsWindow) {
            taskInitComponent.createObject(task);
        }
        completed = true;
    }
    Component.onDestruction: {
        if (moveAnim.running) {
            task.parent.animationsRunning -= 1;
        }
    }
}
