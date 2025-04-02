import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.plasmoid 2.0


import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami


PlasmaExtras.Representation {
    id: full

    required property PlasmaNM.Handler nmHandler
    required property PlasmaNM.NetworkStatus nmStatus
    property alias appletProxyModel: appletProxyModel

    collapseMarginsHint: true

    Component {
        id: networkModelComponent
        PlasmaNM.NetworkModel {}
    }

    property var connectionModel: mainWindow.connectionModel

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel

        sourceModel: full.connectionModel
    }

    Connections {
        target: full.nmHandler
        function onWifiCodeReceived(data, ssid) {
            if (data.length === 0) {
                console.error("Cannot create QR code component: Unsupported connection");
                return;
            }

            const showQRComponent = Qt.createComponent("ShareNetworkQrCodePage.qml");
            if (showQRComponent.status === Component.Error) {
                console.warn("Cannot create QR code component:", showQRComponent.errorString());
                return;
            }

            mainWindow.expanded = true; // just in case.
            stack.push(showQRComponent, {
                content: data,
                ssid
            });
        }
    }

    Keys.forwardTo: [stack.currentItem]
    Keys.onPressed: event => {
        if (event.modifiers & Qt.ControlModifier && event.key == Qt.Key_F) {
            toolbar.searchTextField.forceActiveFocus();
            toolbar.searchTextField.selectAll();
            event.accepted = true;
        } else if (event.key === Qt.Key_Back || (event.modifiers & Qt.AltModifier && event.key == Qt.Key_Left)) {
            if (stack.depth > 1) {
                stack.pop();
                event.accepted = true;
            }
        } else {
            event.accepted = false;
        }
    }

    Rectangle {
        id: toolsbars

        anchors {
            right: parent.right
            rightMargin: connectionListPage.scrollbarWidth - (Kirigami.Units.smallSpacing + 3)
            left: parent.left
            leftMargin: -Kirigami.Units.smallSpacing
            top: parent.top
            topMargin: -Kirigami.Units.smallSpacing * 2
        }

        height: 25
        color: "white"

        visible: stack.depth === 1

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Layout.fillWidth: true

                Toolbar {
                    id: toolbar
                    Layout.fillWidth: true
                    hasConnections: connectionListPage.count > 0
                }

                Loader {
                    sourceComponent: stack.currentItem?.headerItems
                    visible: !!item
                }

                Item {
                    Layout.fillWidth: true
                }

                MouseArea {
                    id: cfgBtn

                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24

                    hoverEnabled: true
                    onClicked: nmHandler.requestScan();
                    enabled: false // TODO: reenable it once refreshing on command is figured out

                    opacity: enabled ? 1.0 : 0.5

                    KSvg.FrameSvgItem {
                        anchors.fill: parent

                        imagePath: "widgets/button"
                        prefix: parent.containsPress ? "pressed" : "hover"

                        visible: parent.containsMouse
                    }

                    Kirigami.Icon {
                        width: 16
                        height: width

                        anchors.centerIn: parent

                        source: "view-refresh"
                    }
                }
            }
        }
    }

    contentItem: Item {

        QQC2.StackView {
            id: stack
            anchors.top: parent.top
            anchors.topMargin: toolsbars.visible ? -Kirigami.Units.smallSpacing * 2 : Kirigami.Units.smallSpacing
            anchors.left: parent.left
            anchors.leftMargin: toolsbars.visible ? -Kirigami.Units.smallSpacing * 2 : 0
            anchors.right: parent.right
            anchors.rightMargin: toolsbars.visible ? -Kirigami.Units.smallSpacing * 2 : 0
            anchors.bottom: backButton.visible ? backButton.top : parent.bottom
            anchors.bottomMargin: toolsbars.visible ? -Kirigami.Units.smallSpacing / 2 : 0
            initialItem: ConnectionListPage {
                id: connectionListPage
                model: appletProxyModel
                nmStatus: full.nmStatus
            }

            popEnter: Transition {}
            popExit: Transition {}
            pushEnter: Transition {}
            pushExit: Transition {}
            replaceEnter: Transition {}
            replaceExit: Transition {}
        }

        QQC2.Button {
            id: backButton
            //anchors.top: stack.bottom

            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            //Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            text: "Back"
            visible: stack.depth > 1
            onClicked: {
                stack.pop()
            }
        }
    }

    Connections {
        target: mainWindow
        function onExpandedChanged(expanded) {
            handler.requestScan();
            if(!full.connectionModel) full.connectionModel = networkModelComponent.createObject(full);
        }
    }
}
