/*
    SPDX-FileCopyrightText: 2012-2016 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15

import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.taskmanager as TaskManager
import org.kde.plasma.private.mpris as Mpris

import "code/layoutmetrics.js" as LayoutMetrics

PlasmaExtras.Menu {
    id: menu

    property QtObject backend
    property QtObject mpris2Source
    property var modelIndex
    readonly property var atm: TaskManager.AbstractTasksModel

    property bool showAllPlaces: false

    placement: {
        if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
            return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        } else if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
            return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        } else if (Plasmoid.location === PlasmaCore.Types.RightEdge) {
            return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        } else {
            return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }

    minimumWidth: visualParent.width

    onStatusChanged: {
        if (visualParent && get(atm.LauncherUrlWithoutIcon) != "" && status == PlasmaExtras.Menu.Open) {
            activitiesDesktopsMenu.refresh();

        } else if (status == PlasmaExtras.Menu.Closed) {
            menu.destroy();
        }
    }

    Component.onCompleted: {
        // Cannot have "Connections" as child of PlasmaExtras.Menu.
        backend.showAllPlaces.connect(showContextMenuWithAllPlaces);
    }

    Component.onDestruction: {
        backend.showAllPlaces.disconnect(showContextMenuWithAllPlaces);
    }

    function showContextMenuWithAllPlaces() {
        visualParent.showContextMenu({showAllPlaces: true});
    }

    function get(modelProp) {
        return tasksModel.data(modelIndex, modelProp)
    }

    function show() {
        Plasmoid.contextualActionsAboutToShow();

        loadDynamicLaunchActions(get(atm.LauncherUrlWithoutIcon));
        openRelative();
    }

    function newMenuItem(parent) {
        return Qt.createQmlObject(`
            import org.kde.plasma.extras 2.0 as PlasmaExtras

            PlasmaExtras.MenuItem {}
        `, parent);
    }

    function newSeparator(parent) {
        return Qt.createQmlObject(`
            import org.kde.plasma.extras 2.0 as PlasmaExtras

            PlasmaExtras.MenuItem { separator: true }
            `, parent);
    }

    function loadDynamicLaunchActions(launcherUrl) {
        if(Plasmoid.configuration.showMore) {
            let sections = [];

            const placesActions = backend.placesActions(launcherUrl, showAllPlaces, menu);

            if (placesActions.length > 0) {
                sections.push({
                    title: i18n("Places"),
                              group: "places",
                              actions: placesActions
                });
            } else {
                sections.push({
                    title:   i18n("Recent Files"),
                              group:   "recents",
                              actions: backend.recentDocumentActions(launcherUrl, menu)
                });
            }

            sections.push({
                title: i18n("Actions"),
                          group: "actions",
                          actions: backend.jumpListActions(launcherUrl, menu)
            });

            // C++ can override section heading by returning a QString as first action
            sections.forEach((section) => {
                if (typeof section.actions[0] === "string") {
                    section.title = section.actions.shift(); // take first
                }
            });

            // QMenu does not limit its width automatically. Even if we set a maximumWidth
            // it would just cut off text rather than eliding. So we do this manually.
            var textMetrics = Qt.createQmlObject("import QtQuick 2.4; TextMetrics {}", menu);
            var maximumWidth = LayoutMetrics.maximumContextMenuTextWidth();

            sections.forEach(function (section) {
                if (section["actions"].length > 0 || section["group"] == "actions") {
                    // Don't add the "Actions" header if the menu has nothing but actions
                    // in it, because then it's redundant (all menus have actions)
                    if (
                        (section["group"] != "actions") ||
                        (section["group"] == "actions" && (sections[0]["actions"].length > 0 || sections[1]["actions"].length > 0))
                    ) {
                        var sectionHeader = newMenuItem(menu);
                        sectionHeader.text = section["title"];
                        sectionHeader.section = true;
                        menu.addMenuItem(sectionHeader, startNewInstanceItem);
                    }
                }

                for (var i = 0; i < section["actions"].length; ++i) {
                    var item = newMenuItem(menu);
                    item.action = section["actions"][i];

                    // Crude way of manually eliding...
                    var elided = false;
                    textMetrics.text = Qt.binding(function() {
                        return item.action.text;
                    });

                    while (textMetrics.width > maximumWidth) {
                        item.action.text = item.action.text.slice(0, -1);
                        elided = true;
                    }

                    if (elided) {
                        item.action.text += "…";
                    }

                    menu.addMenuItem(item, startNewInstanceItem);
                }
            });

            // Add Media Player control actions
            const playerData = mpris2Source.playerForLauncherUrl(launcherUrl, get(atm.AppPid));

            if (playerData && playerData.canControl && !(get(atm.WinIdList) !== undefined && get(atm.WinIdList).length > 1)) {
                const playing = playerData.playbackStatus === Mpris.PlaybackStatus.Playing;
                var menuItem = menu.newMenuItem(menu);
                menuItem.text = i18nc("Play previous track", "Previous Track");
                menuItem.icon = "media-skip-backward";
                menuItem.enabled = Qt.binding(function() {
                    return playerData.canGoPrevious;
                });
                menuItem.clicked.connect(function() {
                    playerData.Previous();
                });
                menu.addMenuItem(menuItem, startNewInstanceItem);

                menuItem = menu.newMenuItem(menu);
                // PlasmaCore Menu doesn't actually handle icons or labels changing at runtime...
                menuItem.text = Qt.binding(function() {
                    // if CanPause, toggle the menu entry between Play & Pause, otherwise always use Play
                    return playing && playerData.canPause ? i18nc("Pause playback", "Pause") : i18nc("Start playback", "Play");
                });
                menuItem.icon = Qt.binding(function() {
                    return playing && playerData.canPause ? "media-playback-pause" : "media-playback-start";
                });
                menuItem.enabled = Qt.binding(function() {
                    return playing ? playerData.canPause : playerData.canPlay;
                });
                menuItem.clicked.connect(function() {
                    if (playing) {
                        playerData.Pause();
                    } else {
                        playerData.Play();
                    }
                });
                menu.addMenuItem(menuItem, startNewInstanceItem);

                menuItem = menu.newMenuItem(menu);
                menuItem.text = i18nc("Play next track", "Next Track");
                menuItem.icon = "media-skip-forward";
                menuItem.enabled = Qt.binding(function() {
                    return playerData.canGoNext;
                });
                menuItem.clicked.connect(function() {
                    playerData.Next();
                });
                menu.addMenuItem(menuItem, startNewInstanceItem);

                menuItem = menu.newMenuItem(menu);
                menuItem.text = i18nc("Stop playback", "Stop");
                menuItem.icon = "media-playback-stop";
                menuItem.enabled = Qt.binding(function() {
                    return playerData.canStop;
                });
                menuItem.clicked.connect(function() {
                    playerData.Stop();
                });
                menu.addMenuItem(menuItem, startNewInstanceItem);

                // Technically media controls and audio streams are separate but for the user they're
                // semantically related, don't add a separator inbetween.
                if (!menu.visualParent.hasAudioStream) {
                    menu.addMenuItem(newSeparator(menu), startNewInstanceItem);
                }

                // If we don't have a window associated with the player but we can quit
                // it through MPRIS we'll offer a "Quit" option instead of "Close"
                if (!closeWindowItem.visible && playerData.canQuit) {
                    menuItem = menu.newMenuItem(menu);
                    menuItem.text = i18nc("Quit media player app", "Quit");
                    menuItem.icon = "application-exit";
                    menuItem.visible = Qt.binding(function() {
                        return !closeWindowItem.visible;
                    });
                    menuItem.clicked.connect(function() {
                        playerData.Quit();
                    });
                    menu.addMenuItem(menuItem);
                }

                // If we don't have a window associated with the player but we can raise
                // it through MPRIS we'll offer a "Restore" option
                if (get(atm.IsLauncher) && !startNewInstanceItem.visible && playerData.canRaise) {
                    menuItem = menu.newMenuItem(menu);
                    menuItem.text = i18nc("Open or bring to the front window of media player app", "Restore");
                    menuItem.icon = playerData.iconName;
                    menuItem.visible = Qt.binding(function() {
                        return !startNewInstanceItem.visible;
                    });
                    menuItem.clicked.connect(function() {
                        playerData.Raise();
                    });
                    menu.addMenuItem(menuItem, startNewInstanceItem);
                }
            }

            // We allow mute/unmute whenever an application has a stream, regardless of whether it
            // is actually playing sound.
            // This way you can unmute, e.g. a telephony app, even after the conversation has ended,
            // so you still have it ringing later on.
            if (menu.visualParent.hasAudioStream) {
                var muteItem = menu.newMenuItem(menu);
                muteItem.checkable = true;
                muteItem.checked = Qt.binding(function() {
                    return menu.visualParent && menu.visualParent.muted;
                });
                muteItem.clicked.connect(function() {
                    menu.visualParent.toggleMuted();
                });
                muteItem.text = i18n("Mute");
                muteItem.icon = "audio-volume-muted";
                menu.addMenuItem(muteItem, startNewInstanceItem);

                menu.addMenuItem(newSeparator(menu), startNewInstanceItem);
            }
        } else return 0;
    }

    PlasmaExtras.MenuItem {
        id: startNewInstanceItem
        visible: get(atm.CanLaunchNewInstance) && Plasmoid.configuration.showMore
        text: i18n("Open New Window")

        onClicked: tasksModel.requestNewInstance(modelIndex)
    }

    PlasmaExtras.MenuItem { separator: true }

    PlasmaExtras.MenuItem {
        id: moreActionsMenuItem

        visible: (visualParent && !get(atm.IsLauncher) && !get(atm.IsStartup)) && Plasmoid.configuration.showMore

        enabled: visible

        text: i18n("More")

        property PlasmaExtras.Menu moreMenu: PlasmaExtras.Menu {
            visualParent: moreActionsMenuItem.action

            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.visualParent && menu.get(atm.IsKeepAbove)

                text: i18n("Keep &Above Others")
                icon: "window-keep-above"

                onClicked: tasksModel.requestToggleKeepAbove(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                checkable: true
                checked: menu.visualParent && menu.get(atm.IsKeepBelow)

                text: i18n("Keep &Below Others")
                icon: "window-keep-below"

                onClicked: tasksModel.requestToggleKeepBelow(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(atm.IsFullScreenable)

                checkable: true
                checked: menu.visualParent && menu.get(atm.IsFullScreen)

                text: i18n("&Fullscreen")
                icon: "view-fullscreen"

                onClicked: tasksModel.requestToggleFullScreen(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                enabled: menu.visualParent && menu.get(atm.IsShadeable)

                checkable: true
                checked: menu.visualParent && menu.get(atm.IsShaded)

                text: i18n("&Shade")
                icon: "window-shade"

                onClicked: tasksModel.requestToggleShaded(menu.modelIndex)
            }

            PlasmaExtras.MenuItem {
                separator: true
            }

            PlasmaExtras.MenuItem {
                visible: (Plasmoid.configuration.groupingStrategy !== 0) && menu.get(atm.IsWindow)

                checkable: true
                checked: menu.visualParent && menu.get(atm.IsGroupable)

                text: i18n("Allow this program to be grouped")
                icon: "view-group"

                onClicked: tasksModel.requestToggleGrouping(menu.modelIndex)
            }
        }
    }

    PlasmaExtras.MenuItem {
        enabled: menu.visualParent && menu.get(atm.IsMovable)

        text: i18n("&Move")

        onClicked: tasksModel.requestMove(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        enabled: menu.visualParent && menu.get(atm.IsResizable)

        text: i18n("Size")

        onClicked: tasksModel.requestResize(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: (menu.visualParent && !get(atm.IsLauncher) && !get(atm.IsStartup))

        enabled: menu.visualParent && get(atm.IsMinimizable)

        text: i18n("Mi&nimize")
        icon: "marlett-minimize"

        onClicked: tasksModel.requestToggleMinimized(modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: (menu.visualParent && !get(atm.IsLauncher) && !get(atm.IsStartup))

        enabled: menu.visualParent && get(atm.IsMaximizable)

        text: i18n("Ma&ximize")
        icon: "marlett-maximize"

        onClicked: tasksModel.requestToggleMaximized(modelIndex)
    }

    PlasmaExtras.MenuItem { separator: true }

    PlasmaExtras.MenuItem {
        id: closeWindowItem
        visible: (visualParent && !get(atm.IsLauncher) && !get(atm.IsStartup))

        enabled: visualParent && get(atm.IsClosable)

        text: get(atm.IsGroupParent) ? i18nc("@item:inmenu", "&Close All") : i18n("&Close")
        icon: "marlett-close"

        onClicked: tasksModel.requestClose(modelIndex);
    }
}
