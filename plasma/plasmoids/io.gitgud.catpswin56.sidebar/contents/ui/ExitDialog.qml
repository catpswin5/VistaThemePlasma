import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

Window {
    id: exitDialog

    minimumWidth: width
    minimumHeight: height
    width: 418
    height: 147
    maximumWidth: width
    maximumHeight: height

    title: window.title

    Column {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 106

            color: "white"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12

                spacing: 8

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignTop

                    implicitWidth: 32
                    implicitHeight: 32

                    source: "gadgets-sidebar"
                }

                ColumnLayout {
                    Text {
                        Layout.fillWidth: true

                        text: i18n("Do you want to exit Windows Sidebar?")
                        color: "#003399"
                        font.pointSize: 11
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: i18n("Exiting the Sidebar will remove the plasmoid from the desktop. To restore the Sidebar, place the Windows Sidebar plasmoid back on the desktop.")
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#dfdfdf" }

        Rectangle {
            width: parent.width
            height: 40

            color: "#f0f0f0"

            RowLayout {
                anchors.fill: parent
                anchors.rightMargin: 11

                spacing: 8

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    text: i18n("Exit Sidebar")
                    onClicked: {
                        window.close();
                        Plasmoid.internalAction("remove").trigger();
                    }
                }
                QQC2.Button {
                    text: i18n("Cancel")
                    onClicked: exitDialog.close();
                }
            }
        }
    }
}
