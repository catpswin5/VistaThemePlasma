/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.networkmanager as NMQt
import QtQuick.Layouts 1.1
import org.kde.kcmutils as KCMUtils
import org.kde.config as KConfig

PlasmoidItem {
    id: mainWindow

    property alias windowManager: wm
    property alias networkStatus: networkStatus
    Item {
        id: wm
        property var windowObjects: {}
        function getWindow(name) {
            if(typeof windowObjects === "undefined")
                windowObjects = {};
            return windowObjects[name];
        }
        function addWindow(uuid, state, type, name, model, devicePath, index) {
            if(typeof windowObjects === "undefined")
                windowObjects = {};

            var winComponent = Qt.createComponent("DetailsWindow.qml", mainWindow);
            if(winComponent.status === Component.Error) {
                console.log("Error loading component:", winComponent.errorString());
                return null;
            }
            var winObj = winComponent.createObject(winComponent, { uuid: uuid, connectionState: state, type: type, networkName: name, connectionModel: model, devicePath: devicePath});
            if(winObj == null) {
                console.log("Error loading object");
                return null;
            }
            winObj.tabBar.currentIndex = index;
            //winObj.transientParent = null;

            windowObjects[name+uuid] = winObj;
            Qt.callLater(() => { windowObjects[name+uuid].show(); });
            return windowObjects[name+uuid];
        }
        function removeWindow(name) {
            delete windowObjects[name];
        }
    }

    property PlasmaNM.NetworkModel connectionModel: null
    readonly property string kcm: "kcm_networkmanagement"
    readonly property bool kcmAuthorized: KConfig.KAuthorized.authorizeControlModule("kcm_networkmanagement")
    readonly property bool delayModelUpdates: fullRepresentationItem !== null
        && fullRepresentationItem.connectionModel !== null
        && fullRepresentationItem.connectionModel.delayModelUpdates
    readonly property bool airplaneModeAvailable: availableDevices.modemDeviceAvailable || availableDevices.wirelessDeviceAvailable
    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)
    property alias planeModeSwitchAction: planeAction

    property real txSpeed: 0
    property real rxSpeed: 0

    Plasmoid.title: i18n("Open Network and Sharing Center")

    toolTipItem: Tooltip {  }

    toolTipMainText: i18n("Networks")
    toolTipSubText: {
        const activeConnections = networkStatus.activeConnections;

        if (!airplaneModeAvailable) {
            return activeConnections;
        }

        if (PlasmaNM.Configuration.airplaneModeEnabled) {
            return i18nc("@info:tooltip", "Middle-click to turn off Airplane Mode");
        } else {
            const hint = i18nc("@info:tooltip", "Middle-click to turn on Airplane Mode");
            return activeConnections ? `${activeConnections}\n${hint}` : hint;
        }
    }

    property bool uploading: txSpeed > 500
    property bool downloading: rxSpeed > 500

    property string activityIcon: uploading && downloading ? "connected-activity" :
                                  uploading ? "connected-uploading" :
                                  downloading ? "connected-downloading" : "connected-noactivity"
    property string state: networkStatus.connectivity === NMQt.NetworkManager.Portal ? "-limited" : ""
    property string defaultIcon: Plasmoid.configuration.connectionState == PlasmaNM.Enums.Deactivated || !enabledConnections.wirelessEnabled ?
                                 "network-wired-disconnected" : activityIcon + state
    property string alternateIcon: inPanel ? connectionIconProvider.connectionIcon + "-symbolic" : connectionIconProvider.connectionTooltipIcon

    Plasmoid.busy: connectionIconProvider.connecting
    Plasmoid.icon: Plasmoid.configuration.useAlternateIcon || PlasmaNM.Configuration.airplaneModeEnabled ? alternateIcon : defaultIcon
    switchWidth: Kirigami.Units.iconSizes.small * 10
    switchHeight: Kirigami.Units.iconSizes.small * 10

    expanded: true

    // Only exists because the default CompactRepresentation doesn't expose
    // a middle-click action.
    // TODO remove once it gains that feature.
    compactRepresentation: CompactRepresentation {
        airplaneModeAvailable: mainWindow.airplaneModeAvailable
        iconName: Plasmoid.icon
    }
    fullRepresentation: PopupDialog {
        id: dialogItem
        nmHandler: handler
        nmStatus: networkStatus
        readonly property int flyoutIntendedWidth: 16 * 17
        Layout.minimumWidth: 16 * 10
        Layout.minimumHeight: 131
        Layout.preferredHeight: dialogItem.implicitHeight
        anchors.fill: parent
        focus: true

        function overrideFunction() {
            KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement");
        }
    }

    Connections {
        target: handler
        function onHotspotCreated() {
            hotspotAction.checked = true
        }

        function onHotspotDisabled() {
            hotspotAction.checked = false
        }
    }
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Enable Wi-Fi")
            icon.name: "network-wireless-on"
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: enabledConnections.wirelessEnabled
            visible: enabledConnections.wirelessHwEnabled
                        && availableDevices.wirelessDeviceAvailable
                        && !PlasmaNM.Configuration.airplaneModeEnabled
            onTriggered: checked => {handler.enableWireless(checked)}
        },
        PlasmaCore.Action {
            text: i18n("Enable Mobile Network")
            icon.name: "network-mobile-on"
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: enabledConnections.wwanEnabled
            visible: enabledConnections.wwanHwEnabled
                        && availableDevices.modemDeviceAvailable
                        && !PlasmaNM.Configuration.airplaneModeEnabled
            onTriggered: checked => {handler.enableWwan(checked)}
        },
        PlasmaCore.Action {
            id: planeAction
            text: i18n("Enable Airplane Mode")
            icon.name: "network-flightmode-on"
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: PlasmaNM.Configuration.airplaneModeEnabled
            visible: mainWindow.airplaneModeAvailable
            onTriggered: checked => {
                handler.enableAirplaneMode(checked)
                PlasmaNM.Configuration.airplaneModeEnabled = checked
            }
        },
        PlasmaCore.Action {
            id: hotspotAction
            text: PlasmaNM.Configuration.hotspotConnectionPath ? i18n("Disable Hotspot") : i18n("Create Hotspot")
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            //checked: PlasmaNM.Configuration.airplaneModeEnabled
            visible: handler.hotspotSupported

            onTriggered: checked => {
                if (PlasmaNM.Configuration.hotspotConnectionPath) {
                    checked = false;
                    handler.stopHotspot();
                } else {
                    checked = true;
                    handler.createHotspot();
                }
            }

            Component.onCompleted: {
                checked = PlasmaNM.Configuration.hotspotConnectionPath
            }

        },
        PlasmaCore.Action {
            text: i18n("Open Network Login Page…")
            icon.name: "network-flightmode-on"
            priority: PlasmaCore.Action.LowPriority
            visible: networkStatus.connectivity === NMQt.NetworkManager.Portal
            onTriggered: Qt.openUrlExternally("http://networkcheck.kde.org")
        },
        PlasmaCore.Action {
            id: configureAction
            text: i18n("&Configure Network Connections…")
            icon.name: "configure"
            visible: kcmAuthorized
            shortcut: "alt+d, s"
            onTriggered: KCMUtils.KCMLauncher.openSystemSettings(kcm)
        }
    ]

    Component.onCompleted: {
        handler.requestScan();
        mainWindow.expanded = true;
        mainWindow.expanded = false;
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaNM.AvailableDevices {
        id: availableDevices
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIconProvider
        connectivity: networkStatus.connectivity
    }

    PlasmaNM.Handler {
        id: handler
    }

    Timer {
        id: scanTimer
        interval: 10200
        triggeredOnStart: true
        repeat: true
        running: !PlasmaNM.Configuration.airplaneModeEnabled && !mainWindow.delayModelUpdates

        onTriggered: handler.requestScan()
    }
}
