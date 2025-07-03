import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

import org.kde.plasma.private.volume
import org.kde.kwindowsystem
import org.kde.kwin.private.kdecoration as KDecoration

Window {
    id: mixer

    property bool mixer: true

    width: 473
    height: 331

    KDecoration.Bridge {
        id: bridgeItem
        plugin: KWindowSystem.isPlatformWayland ? Plasmoid.getDecorationPluginName() : "";
        theme:  KWindowSystem.isPlatformWayland ? Plasmoid.getDecorationThemeName() : "";
    }
    KDecoration.Settings {
        id: settingsItem
        bridge: bridgeItem.bridge
    }
    KDecoration.Decoration {
        id: decorationMetrics
        bridge: bridgeItem.bridge
        settings: settingsItem
        anchors.fill: parent
        visible: false
    }

    onVisibleChanged: {
        if(visible) {

            var pos = main.mapToGlobal(main.x, main.y);
            var availScreen = Plasmoid.containment.availableScreenRect;
            if(Plasmoid.location === PlasmaCore.Types.BottomEdge) {
                x = pos.x - mixer.width / 2;
                y = pos.y - mixer.height;
            } else if(Plasmoid.location === PlasmaCore.Types.TopEdge) {
                x = pos.x - mixer.width / 2;
                y = availScreen.y;
            } else if(Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                x = pos.x;
                y = pos.y - mixer.height / 2;
            } else if(Plasmoid.location === PlasmaCore.Types.RightEdge) {
                x = pos.x - mixer.width;
                y = pos.y - mixer.height / 2;
            }
            if(KWindowSystem.isPlatformWayland) {
                var wl_width = mixer.width + decorationMetrics.decoration.borderLeft + decorationMetrics.decoration.borderRight
                var wl_height = mixer.height + decorationMetrics.decoration.borderTop + decorationMetrics.decoration.borderBottom
                var wl_x = Math.max(availScreen.x, Math.min(x, availScreen.width-wl_width));
                var wl_y = Math.max(availScreen.y, Math.min(y, availScreen.height-wl_height));
                Plasmoid.setPopupPosition(mixer, wl_x, wl_y);
            }
        }
    }

    onClosing: mixer.destroy();

    title: i18n("Volume Mixer")

    component CustomGroupBox: QQC2.GroupBox {
        id: gbox
        label: QQC2.Label {
            id: lbl
            x: gbox.leftPadding + 2
            y: lbl.implicitHeight/2-gbox.bottomPadding-1
            color: "black"
            width: lbl.implicitWidth
            text: gbox.title
            elide: Text.ElideRight
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -2
                anchors.rightMargin: -2
                color: "white"
                z: -1
            }
        }
        background: Rectangle {
            y: gbox.topPadding - gbox.bottomPadding*2
            width: parent.width
            height: parent.height - gbox.topPadding + gbox.bottomPadding*2
            color: "transparent"
            border.color: "#d5dfe5"
            radius: 3
        }
    }

    PlasmaExtras.Menu {
        id: optionsMenu
        visualParent: optionsItem
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;

        PlasmaExtras.MenuItem {
            id: raiseMaximumVolumeItem

            text: i18n("Raise maximum volume")
            checkable: true
            checked: config.raiseMaximumVolume
            onClicked: {
                config.raiseMaximumVolume = checked;
                config.save();
            }
        }
        PlasmaExtras.MenuItem {
            id: hideDefaultInputItem

            text: i18n("Hide default input device from flyout")
            checkable: true
            checked: Plasmoid.configuration.hideDefaultInput
            onClicked: Plasmoid.configuration.hideDefaultInput = checked;
        }
    }

    ColumnLayout {
        anchors.fill: parent

        spacing: 0

        KSvg.FrameSvgItem {
            imagePath: Qt.resolvedUrl("svgs/button.svg")
            prefix: "toolbutton-hover"
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            RowLayout {
                anchors.fill: parent

                MouseArea {
                    id: optionsItem

                    Layout.preferredWidth: deviceItem.implicitWidth + Kirigami.Units.smallSpacing * 2
                    Layout.margins: 1
                    Layout.bottomMargin: 2
                    Layout.fillHeight: true
                    hoverEnabled: true

                    onClicked: optionsMenu.openRelative();

                    KSvg.FrameSvgItem {
                        anchors.fill: parent

                        imagePath: "widgets/button"
                        prefix: parent.containsPress || optionsMenu.state == 1 ? "toolbutton-pressed" : "toolbutton-hover"

                        visible: parent.containsMouse || optionsMenu.state == 1
                    }

                    Text {
                        id: deviceItem
                        text: i18n("Options")
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing * 3

            spacing: 1

            CustomGroupBox {
                id: speaker

                title: i18n("Device")

                Layout.fillHeight: true
                Layout.preferredWidth: sinkList.width +
                                       (sourceList.visible ? (sourceList.width + (Kirigami.Units.smallSpacing * 4)) : Kirigami.Units.smallSpacing) +
                                       (Kirigami.Units.smallSpacing * 2)

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: Kirigami.Units.smallSpacing * 4

                    spacing: Kirigami.Units.smallSpacing * 2

                    ListView {
                        id: sinkList

                        Layout.bottomMargin: Kirigami.Units.smallSpacing * 3
                        Layout.preferredWidth: 96
                        Layout.fillHeight: true

                        interactive: false
                        model: paSinkFilterModelDefault
                        delegate: DeviceListItem { type: "sink-output"; width: 96; height: parent.height-16; isMixer: true; }
                        orientation: ListView.Horizontal
                        spacing: 0

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: -1
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom

                            width: 1

                            color: "#d6e1dd"

                            visible: sourceList.visible
                        }
                    }
                    ListView {
                        id: sourceList

                        Layout.bottomMargin: Kirigami.Units.smallSpacing * 3
                        Layout.preferredWidth: 96
                        Layout.fillHeight: true

                        interactive: false
                        model: paSourceFilterModelDefault
                        delegate: DeviceListItem { type: "sink-input"; width: 96; height: parent.height-16; isMixer: true }
                        orientation: ListView.Horizontal
                        focus: visible
                        visible: count != 0
                        spacing: 0
                    }

                    z: 999
                }
            }
            CustomGroupBox {
                id: apps

                Layout.fillHeight: true
                Layout.fillWidth: true

                title: i18n("Applications")

                QQC2.ScrollView {
                    anchors.fill: parent

                    ListView {
                        id: sinkInputList

                        anchors.fill: parent
                        anchors.bottomMargin: Kirigami.Units.smallSpacing * 3

                        interactive: false
                        model: paSinkInputFilterModel
                        delegate: StreamListItem { type: "source-output"; width: 96; height: parent.height-16; isMixer: true }
                        orientation: ListView.Horizontal
                        focus: visible
                        clip: true
                        spacing: Kirigami.Units.smallSpacing
                    }
                }
            }
        }
    }
}
