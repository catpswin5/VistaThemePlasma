/*
    SPDX-FileCopyrightText: 2014-2015 Harald Sitter <sitter@kde.org>
    SPDX-FileCopyrightText: 2019 Sefa Eyeoglu <contact@scrumplex.net>
    SPDX-FileCopyrightText: 2022 ivan (@ratijas) tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.volume
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import org.kde.ksvg as KSvg

Item {
    id: item

    required property var model
    property string type
    property bool isStream: false

    property string name: "unknown"
    property string iconName: model.IconName

    property bool isMixer: {
        let item = this;
        while (item.parent) {
            item = item.parent;
            if (item.mixer !== undefined) {
                return item.mixer
            }
        }
    }

    opacity: (main.draggedStream && main.draggedStream.deviceIndex === item.model.Index) ? 0.3 : 1.0

    Keys.forwardTo: [slider]

    ColumnLayout {
        id: controlsRow

        anchors.fill: parent

        spacing: 17

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            source: type == "sink-output" ? "audio-speakers" : (type == "sink-input" ? "audio-input-microphone" : item.iconName)

            MouseArea {
                id: iconMa

                anchors.fill: parent
                anchors.margins: -Kirigami.Units.smallSpacing

                hoverEnabled: true
                onClicked: contextMenu.openRelative();

                visible: type == "sink-output" || type == "sink-input"
            }

            KSvg.FrameSvgItem {
                anchors.fill: iconMa

                imagePath: "widgets/button"
                prefix: iconMa.containsPress || contextMenu.visible ? "toolbutton-pressed" : "toolbutton-hover"

                visible: iconMa.containsMouse || contextMenu.visible

                z: -1
            }
        }

        Text {
            id: label

            property bool showDropdown: {
                if(type == "sink-output") return paSinkFilterModel.count > 1
                if(type == "sink-input") return paSourceFilterModel.count > 1
                else return false
            }

            Layout.topMargin: -parent.spacing / 2
            Layout.preferredHeight: 32
            Layout.fillWidth: true

            text: type == "sink-output" ? "Speaker" : (type == "sink-input" ? "Microphone" : item.name)
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
            rightPadding: showDropdown ? (dropdownArrow.width + Kirigami.Units.smallSpacing) : 0

            visible: isMixer

            TextMetrics {
                id: textMetrics
                text: label.showDropdown ? label.text : ""
            }

            MouseArea {
                id: labelMa

                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }

                height: textMetrics.height + Kirigami.Units.smallSpacing - 1
                width: textMetrics.advanceWidth + dropdownArrow.width + Kirigami.Units.smallSpacing * 2

                hoverEnabled: true
                onClicked: deviceListMenu.openRelative();

                visible: parent.showDropdown
            }

            KSvg.FrameSvgItem {
                anchors.fill: labelMa

                imagePath: "widgets/button"
                prefix: labelMa.containsPress || deviceListMenu.status == 1 ? "toolbutton-pressed" : "toolbutton-hover"

                visible: (labelMa.containsMouse && parent.showDropdown) || deviceListMenu.status == 1

                z: -1
            }

            KSvg.SvgItem {
                id: dropdownArrow

                anchors {
                    verticalCenter: labelMa.verticalCenter
                    verticalCenterOffset: 0
                    right: labelMa.right
                    rightMargin: 3
                }

                width: 6
                height: 5

                imagePath: Qt.resolvedUrl("svgs/control.svg")
                elementId: "dropdown"

                visible: parent.showDropdown
            }
        }

        VolumeSlider {
            id: slider

            property real myStepSize: PulseAudio.NormalVolume / 100.0 * config.volumeStep

            readonly property bool forceRaiseMaxVolume: (config.raiseMaximumVolume && (item.type === "sink-output" || item.type === "sink-input"))
            onForceRaiseMaxVolumeChanged: {
                if (forceRaiseMaxVolume) {
                    toAnimation.from = PulseAudio.NormalVolume;
                    toAnimation.to = PulseAudio.MaximalVolume;
                } else {
                    toAnimation.from = PulseAudio.MaximalVolume;
                    toAnimation.to = PulseAudio.NormalVolume;
                }
                seqAnimation.restart();
            }

            function increase() { value = value + myStepSize }
            function decrease() { value = value - myStepSize }

            function updateVolume() {
                if (!forceRaiseMaxVolume && item.model.Volume > PulseAudio.NormalVolume) {
                    item.model.Volume = PulseAudio.NormalVolume;
                }
            }

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.maximumHeight: 115

            from: PulseAudio.MinimalVolume
            to: forceRaiseMaxVolume || item.model.Volume >= PulseAudio.NormalVolume * 1.01 ? PulseAudio.MaximalVolume : PulseAudio.NormalVolume
            stepSize: PulseAudio.NormalVolume / 100.0
            enabled: item.model.VolumeWritable
            muted: item.model.Muted
            volumeObject: item.model.PulseObject
            value: to, item.model.Volume

            onMoved: {
                item.model.Volume = value;
                item.model.Muted = value === 0;
            }
            onPressedChanged: {
                if (!pressed) {
                    // Make sure to sync the volume once the button was
                    // released.
                    // Otherwise it might be that the slider is at v10
                    // whereas PA rejected the volume change and is
                    // still at v15 (e.g.).
                    value = Qt.binding(() => item.model.Volume);
                    if (type === "sink") {
                        playFeedback(item.model.Index);
                    }
                }
            }

            type: item.type

            visible: item.model.HasVolume !== false // Devices always have volume but Streams don't necessarily

            SequentialAnimation {
                id: seqAnimation
                NumberAnimation {
                    id: toAnimation
                    target: slider
                    property: "to"
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: slider.updateVolume()
                }
            }
        }
        MouseArea {
            id: muteButton

            Layout.preferredWidth: isMixer ? 28 : 24
            Layout.preferredHeight: isMixer ? 26 : 22
            Layout.alignment: Qt.AlignHCenter

            hoverEnabled: true
            onClicked: item.model.Muted = !item.model.Muted

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1

                color: "#efefef"
            }
            KSvg.FrameSvgItem {
                anchors.fill: parent

                imagePath: "widgets/button"
                prefix: parent.containsMouse ? (parent.containsPress ? "pressed" : "hover") : "normal"
            }
            KSvg.SvgItem {
                anchors.centerIn: parent

                width: elementId == "unmute" ? 14 : 16
                height: 16

                imagePath: Qt.resolvedUrl("svgs/control.svg")
                elementId: item.model.Muted ? "unmute" : "mute"
            }
        }
    }

    Instantiator {
        model: {
            if(type === "sink-output") return paSinkFilterModel;
            if(type === "sink-input") return paSourceFilterModel;
        }
        delegate: PlasmaExtras.MenuItem {
            required property int index
            required property var model

            text: model.Description + "      "
            checkable: true
            checked: model.PulseObject.default
            onClicked: {
                if (type === "sink-output" || type === "sink-input") {
                    model.PulseObject.default = true;
                }
            }
        }
        onObjectAdded: (index, object) => deviceListMenu.addMenuItem(object);
        onObjectRemoved: (index, object) => deviceListMenu.removeMenuItem(object)
    }

    PlasmaExtras.Menu {
        id: deviceListMenu
        visualParent: labelMa
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
    }

    ListItemMenu {
        id: contextMenu
        pulseObject: item.model.PulseObject
        cardModel: main.paCardModel
        itemType: {
            switch (item.type) {
            case "sink-input":
                return ListItemMenu.Sink;
            case "sink-output":
                return ListItemMenu.SinkInput;
            case "source":
                return ListItemMenu.Source;
            case "source-output":
                return ListItemMenu.SourceOutput;
            }
        }
        sourceModel: {
            if (item.type == "sink-output") return main.paSinkFilterModel
            else if (item.type == "sink-input") return main.paSourceFilterModel
        }
        visualParent: iconMa
    }

    function setVolumeByPercent(targetPercent) {
        item.model.PulseObject.volume = Math.round(PulseAudio.NormalVolume * (targetPercent/100));
    }

    function setAsDefault(): void {
        if (type === "sink" || type === "source") {
            model.PulseObject.default = true;
        }
    }

    Keys.onPressed: event => {
        const k = event.key;

        if (k === Qt.Key_M) {
            muteButton.clicked();
        } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
            setVolumeByPercent((k - Qt.Key_0) * 10);
        } else if (k === Qt.Key_Return) {
            setAsDefault();
        } else if (k === Qt.Key_Menu && contextMenu.hasContent) {
            contextMenu.visualParent = contextMenuButton;
            contextMenu.openRelative();
        } else {
            return; // don't accept the key press
        }
        event.accepted = true;
    }
}
