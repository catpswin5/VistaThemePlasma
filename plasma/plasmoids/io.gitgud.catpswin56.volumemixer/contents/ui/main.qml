/*
    SPDX-FileCopyrightText: 2014-2015 Harald Sitter <sitter@kde.org>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

import org.kde.kcmutils as KCMUtils
import org.kde.config as KConfig

import org.kde.plasma.private.volume

import "model/" as Model // Custom PulseObjectFilterModel

PlasmoidItem {
    id: main

    GlobalConfig {
        id: config
    }

    property bool volumeFeedback: config.audioFeedback
    property bool globalMute: config.globalMute
    property string displayName: i18n("Audio Volume")
    property QtObject draggedStream: null
    property QtObject mixerWindow: null

    property bool showVirtualDevices: Plasmoid.configuration.showVirtualDevices

    // DEFAULT_SINK_NAME in module-always-sink.c
    readonly property string dummyOutputName: "auto_null"
    readonly property string noDevicePlaceholderMessage: i18n("No output or input devices found")

    switchHeight: Layout.minimumHeight
    switchWidth: Layout.minimumWidth

    Plasmoid.icon: PreferredDevice.sink && !isDummyOutput(PreferredDevice.sink) ? AudioIcon.forVolume(volumePercent(PreferredDevice.sink.volume), PreferredDevice.sink.muted, "") : AudioIcon.forVolume(0, true, "")
    Plasmoid.title: "‎ "

    toolTipItem: TrayToolTip {  }

    function nodeName(pulseObject) {
        const nodeNick = pulseObject.pulseProperties["node.nick"]
        if (nodeNick) {
            return nodeNick
        }

        if (pulseObject.description) {
            return pulseObject.description
        }

        if (pulseObject.name) {
            return pulseObject.name
        }

        return i18n("Device name not found")
    }

    function isDummyOutput(output) {
        return output && output.name === dummyOutputName;
    }

    function volumePercent(volume) {
        return Math.round(volume / PulseAudio.NormalVolume * 100.0);
    }

    function playFeedback(sinkIndex) {
        if (!volumeFeedback) {
            return;
        }
        if (sinkIndex == undefined) {
            sinkIndex = PreferredDevice.sink.index;
        }
        feedback.play(sinkIndex);
    }

    // Output devices
    readonly property SinkModel paSinkModel: SinkModel { id: paSinkModel }

    // Input devices
    readonly property SourceModel paSourceModel: SourceModel { id: paSourceModel }

    // Confusingly, Sink Input is what PulseAudio calls streams that send audio to an output device
    readonly property SinkInputModel paSinkInputModel: SinkInputModel { id: paSinkInputModel }

    // Confusingly, Source Output is what PulseAudio calls streams that take audio from an input device
    readonly property SourceOutputModel paSourceOutputModel: SourceOutputModel { id: paSourceOutputModel }

    // active output devices
    readonly property PulseObjectFilterModel paSinkFilterModel: PulseObjectFilterModel {
        id: paSinkFilterModel
        filterOutInactiveDevices: true
        filterVirtualDevices: !main.showVirtualDevices
        sourceModel: paSinkModel
    }

    // default acitve output device
    readonly property Model.PulseObjectFilterModel paSinkFilterModelDefault: Model.PulseObjectFilterModel {
        id: paSinkFilterModelDefault
        filterOutInactiveDevices: true
        filterVirtualDevices: !main.showVirtualDevices
        sourceModel: paSinkModel
    }

    // default acitve input device
    readonly property Model.PulseObjectFilterModel paSourceFilterModelDefault: Model.PulseObjectFilterModel {
        id: paSourceFilterModelDefault
        sourceModel: paSourceModel
    }

    // active input devices
    readonly property PulseObjectFilterModel paSourceFilterModel: PulseObjectFilterModel {
        id: paSourceFilterModel
        filterOutInactiveDevices: true
        filterVirtualDevices: !main.showVirtualDevices
        sourceModel: paSourceModel
    }

    // non-virtual streams going to output devices
    readonly property PulseObjectFilterModel paSinkInputFilterModel: PulseObjectFilterModel {
        id: paSinkInputFilterModel
        filters: [ { role: "VirtualStream", value: false } ]
        sourceModel: paSinkInputModel
    }

    // non-virtual streams coming from input devices
    readonly property PulseObjectFilterModel paSourceOutputFilterModel: PulseObjectFilterModel {
        id: paSourceOutputFilterModel
        filters: [ { role: "VirtualStream", value: false } ]
        sourceModel: paSourceOutputModel
    }

    readonly property CardModel paCardModel: CardModel {
        id: paCardModel

        function indexOfCardNumber(cardNumber) {
            const indexRole = KItemModels.KRoleNames.role("Index");
            for (let idx = 0; idx < count; ++idx) {
                if (data(index(idx, 0), indexRole) === cardNumber) {
                    return index(idx, 0);
                }
            }
            return index(-1, 0);
        }
    }

    // Only exists because the default CompactRepresentation doesn't expose:
    // - scroll actions
    // - a middle-click action
    // TODO remove once it gains those features.
    compactRepresentation: MouseArea {
        property int wheelDelta: 0
        property bool wasExpanded: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: mouse => {
            if (mouse.button == Qt.LeftButton) {
                wasExpanded = main.expanded;
            } else if (mouse.button == Qt.MiddleButton) {
                GlobalService.globalMute();
            }
        }
        onClicked: mouse => {
            if (mouse.button == Qt.LeftButton) {
                if(mixerWindow) {
                    mixerWindow.visibility = Window.AutomaticVisibility;
                    mixerWindow.raise();
                }
                else main.expanded = !wasExpanded;
            }
        }
        onEntered: {
            compactTooltip.showToolTip()
        }
        onExited: {
            compactTooltip.hideTooltip()
        }
        onWheel: wheel => {
            const delta = (wheel.inverted ? -1 : 1) * (wheel.angleDelta.y ? wheel.angleDelta.y : -wheel.angleDelta.x);
            wheelDelta += delta;
            // Magic number 120 for common "one click"
            // See: https://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                if (wheel.modifiers & Qt.ShiftModifier) {
                    GlobalService.volumeUpSmall();
                } else {
                    GlobalService.volumeUp();
                }
            }
            while (wheelDelta <= -120) {
                wheelDelta += 120;
                if (wheel.modifiers & Qt.ShiftModifier) {
                    GlobalService.volumeDownSmall();
                } else {
                    GlobalService.volumeDown();
                }
            }
        }
        Kirigami.Icon {
            anchors.fill: parent
            source: plasmoid.icon
            active: parent.containsMouse
        }
    }

    VolumeFeedback {
        id: feedback
    }

    fullRepresentation: Item {
        id: fullRep

        property int flyoutIntendedWidth: defaultOutput.count == 0 && defaultInput.count == 0 ? 128 : mainLayout.width

        implicitHeight: 181

        function overrideFunction() {
            if(!mixerWindow) {
                mixerWindow = Qt.createQmlObject("MixerWindow {}", main);
                mixerWindow.visible = true;
            } else {
                mixerWindow.visibility = Window.AutomaticVisibility;
                mixerWindow.raise();
            }
        }

        property list<string> hiddenTypes: []
        property int listWidth: 34

        Rectangle {
            anchors.fill: mainLayout
            anchors.topMargin: -Kirigami.Units.smallSpacing * 2
            anchors.bottomMargin: -Kirigami.Units.smallSpacing * 4
            anchors.rightMargin: 0
            anchors.leftMargin: 0

            color: "white"

            z: -1
        }

        Text {
            anchors.centerIn: mainLayout

            text: i18n("No devices to show.")

            visible: defaultOutput.count == 0 && defaultInput.count == 0
        }

        RowLayout {
            id: mainLayout

            property int defaultInputWidth: {
                if(defaultInput.visible) return (separator.width + separator.anchors.leftMargin)
                    + (defaultInput.width + defaultInput.anchors.leftMargin)
                    else return 0
            }

            anchors.top: parent.top
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            ListView {
                id: defaultOutput

                property bool mixer: false

                Layout.fillHeight: true
                Layout.preferredWidth: fullRep.listWidth
                Layout.leftMargin: fullRep.listWidth / 2
                Layout.rightMargin: defaultInput.visible ? 0 : 17

                interactive: false
                model: paSinkFilterModelDefault
                delegate: DeviceListItem { type: "sink-output"; width: fullRep.listWidth; height: parent.height }
                orientation: ListView.Horizontal
                focus: visible
                spacing: 0

                visible: count && !fullRep.hiddenTypes.includes("sink-output")

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: -Kirigami.Units.smallSpacing * 3
                        top: parent.top
                        topMargin: Kirigami.Units.smallSpacing / 2
                    }

                    width: 1
                    height: 195

                    color: "#d6e1dd"

                    visible: defaultInput.visible
                }
            }

            ListView {
                id: defaultInput

                property bool mixer: false

                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.smallSpacing * 4.5
                Layout.preferredWidth: fullRep.listWidth
                Layout.rightMargin: fullRep.listWidth / 2

                interactive: false
                model: paSourceFilterModelDefault
                delegate: DeviceListItem { type: "sink-input"; width: fullRep.listWidth; height: parent.height }
                orientation: ListView.Horizontal
                focus: visible
                spacing: 0

                visible: count != 0 && !Plasmoid.configuration.hideDefaultInput
            }
        }

        Text {
            anchors.fill: trayHeading

            color: "#3593ff"
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            text: i18n("Mixer")
            font.underline: ma.containsMouse
            wrapMode: Text.NoWrap
            elide: Text.ElideNone

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    mixerWindow = Qt.createQmlObject("MixerWindow {}", main);
                    mixerWindow.visible = true;
                }
            }

            z: 1
        }
        Rectangle {
            id: trayHeading

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right

                margins: -Kirigami.Units.smallSpacing*2
                bottomMargin: -40 - ((Kirigami.Units.smallSpacing * 2) - 2)
            }

            height: 30

            color: "#f0f0f0"

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                color: "#9f9f9f"
                height: 1
            }
            Rectangle {
                anchors {
                    top: parent.top
                    topMargin: 1
                    left: parent.left
                    right: parent.right
                }

                color: "white"
                height: 1
            }
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Force mute all playback devices")
            icon.name: "audio-volume-muted"
            checkable: true
            checked: globalMute
            onTriggered: {
                GlobalService.globalMute();
            }
        },
        PlasmaCore.Action {
            text: i18n("Show virtual devices")
            icon.name: "audio-card"
            checkable: true
            checked: plasmoid.configuration.showVirtualDevices
            onTriggered: Plasmoid.configuration.showVirtualDevices = !Plasmoid.configuration.showVirtualDevices
        },
        PlasmaCore.Action {
            text: i18n("Volume Mixer")
            icon.name: "menu_new"
            onTriggered: {
                mixerWindow = Qt.createQmlObject("MixerWindow {}", main);
                mixerWindow.visible = true;
            }
        }
    ]

    PlasmaCore.Action {
        id: configureAction
        text: i18n("&Configure Audio Devices…")
        icon.name: "configure"
        shortcut: "alt+d, s"
        visible: KConfig.KAuthorized.authorizeControlModule("kcm_pulseaudio")
        onTriggered: KCMUtils.KCMLauncher.openSystemSettings("kcm_pulseaudio")
    }

    Component.onCompleted: {
        MicrophoneIndicator.init();
        Plasmoid.setInternalAction("configure", configureAction);

        // migrate settings if they aren't default
        // this needs to be done per instance of the applet
        if (Plasmoid.configuration.migrated) {
            return;
        }
        if (Plasmoid.configuration.volumeFeedback === false && config.audioFeedback) {
            config.audioFeedback = false;
            config.save();
        }
        if (Plasmoid.configuration.volumeStep && Plasmoid.configuration.volumeStep !== 5 && config.volumeStep === 5) {
            config.volumeStep = Plasmoid.configuration.volumeStep;
            config.save();
        }
        if (Plasmoid.configuration.raiseMaximumVolume === true && !config.raiseMaximumVolume) {
            config.raiseMaximumVolume = true;
            config.save();
        }
        if (Plasmoid.configuration.volumeOsd === false && config.volumeOsd) {
            config.volumeOsd = false;
            config.save();
        }
        if (Plasmoid.configuration.muteOsd === false && config.muteOsd) {
            config.muteOsd = false;
            config.save();
        }
        if (Plasmoid.configuration.micOsd === false && config.microphoneSensitivityOsd) {
            config.microphoneSensitivityOsd = false;
            config.save();
        }
        if (Plasmoid.configuration.globalMute === true && !config.globalMute) {
            config.globalMute = true;
            config.save();
        }
        if (Plasmoid.configuration.globalMuteDevices.length !== 0) {
            for (const device in Plasmoid.configuration.globalMuteDevices) {
                if (!config.globalMuteDevices.includes(device)) {
                    config.globalMuteDevices.push(device);
                }
            }
            config.save();
        }
        Plasmoid.configuration.migrated = true;
    }
}
