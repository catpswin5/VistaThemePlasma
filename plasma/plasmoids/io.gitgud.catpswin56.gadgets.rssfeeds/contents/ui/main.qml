import QtQuick
import QtQml.XmlListModel
import QtQuick.Controls
import QtQuick.Layouts

import Qt5Compat.GraphicalEffects

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: window
    width: 130
    height: 173

    property var url: Plasmoid.configuration.url

    Plasmoid.backgroundHints: "NoBackground"

    KSvg.FrameSvgItem {
        anchors.fill: bg
        anchors.margins: -Kirigami.Units.smallSpacing

        imagePath: "dialogs/background"

        visible: moreFlyout.visible
    }

    function stripString (str) {
        var regex = /(<img.*?>)/gi;
        str = str.replace(regex, "");
        regex = /&#228;/gi;
        str = str.replace(regex, "ä");
        regex = /&#246;/gi;
        str = str.replace(regex, "ö");
        regex = /&#252;/gi;
        str = str.replace(regex, "ü");
        regex = /&#196;/gi;
        str = str.replace(regex, "Ä");
        regex = /&#214;/gi;
        str = str.replace(regex, "Ö");
        regex = /&#220;/gi;
        str = str.replace(regex, "Ü");
        regex = /&#223;/gi;
        str = str.replace(regex, "ß");

        return str;
    }

    XmlListModel {
        id: xmlModel
        source: url
        query: "/rss/channel/item"

        XmlListModelRole { name: "title"; elementName: "title" }
        XmlListModelRole { name: "pubDate"; elementName: "pubDate" }
        XmlListModelRole { name: "content"; elementName: "encoded" }
        XmlListModelRole { name: "description"; elementName: "description" }
        XmlListModelRole { name: "creator"; elementName: "creator" }

        onStatusChanged: {
            list.visible = false
            busyIndicator.visible = true
        }
    }

    Image {
        id: bg

        anchors.centerIn: parent

        source: "resources/unexpanded/background.png"
    }

    Component {
        id: feedDelegate

        Item {
            width: 123
            height: 35

            Component.onCompleted: {
                list.visible = true
                busyIndicator.visible = false
            }

            Image {
                id: delegateSelected
                source: "resources/unexpanded/selected.png"
                visible: moreFlyout.visible && moreFlyout.itemIndex == index ? true : false
            }

            ColumnLayout {
                id: layout

                anchors {
                    fill: parent
                    rightMargin: Kirigami.Units.smallSpacing*2
                    leftMargin: Kirigami.Units.smallSpacing*2
                }

                spacing: -Kirigami.Units.smallSpacing

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    id: titleText

                    Layout.fillWidth: true

                    wrapMode: Text.NoWrap
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    color: "white"
                    text: title
                    renderType: Text.NativeRendering
                    font.hintingPreference: Font.PreferFullHinting
                    font.kerning: false
                    font.bold: true
                }

                Item {
                    Layout.preferredHeight: Kirigami.Units.smallSpacing*2
                }

                RowLayout {
                    Text {
                        id: linkText

                        Layout.fillWidth: true

                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        color: "white"
                        text: creator
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                        font.pointSize: 8

                        opacity: 0.3
                    }
                    Text {
                        id: dateText

                        Layout.fillWidth: true

                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        color: "white"
                        text: pubDate
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: false
                        font.pointSize: 8

                        opacity: 0.3
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            Rectangle {
                anchors {
                    right: parent.right
                    left: parent.left
                    leftMargin: -Kirigami.Units.smallSpacing*3
                    bottom: parent.bottom
                }

                height: 1

                color: "white"

                opacity: 0.2
            }

            MouseArea {
                acceptedButtons: Qt.LeftButton
                anchors.fill: parent
                onClicked: {
                    moreFlyout.itemIndex = index // comment about this is in Flyout.qml
                    moreFlyout.title = title
                    moreFlyout.creator = creator

                    if(content == "") {
                        moreFlyout.content = description
                    } else moreFlyout.content = content

                    if(moreFlyout.visible) {
                        moreFlyout.visible = false
                    } else {
                        moreFlyout.visible = true
                    }
                }
            }
        }
    }

    Item {
        id: bottomControls

        anchors {
            bottom: parent.bottom
            bottomMargin: Kirigami.Units.smallSpacing

            horizontalCenter: bg.horizontalCenter
        }

        width: 121
        height: 26

        Rectangle {
            id: bCBg

            anchors.centerIn: parent

            width: 78
            height: 20

            color: "black"

            border.width: 1
            border.color: "white"
            radius: 12

            opacity: 0.2
        }

        RowLayout {
            anchors.fill: bCBg
            anchors.rightMargin: Kirigami.Units.smallSpacing/2
            anchors.leftMargin: Kirigami.Units.smallSpacing/2

            Image {
                id: downButton

                property string suffix: downButtonMa.containsMouse ? "-hover.png" : ".png"

                source: "resources/controls/down" + suffix

                opacity: list.count > 3 && list.currentIndex < list.count ? 1 : 0.5

                MouseArea {
                    id: downButtonMa

                    anchors.fill: parent

                    visible: list.count > 3 && list.currentIndex < list.count

                    hoverEnabled: true

                    onClicked: {
                        if(list.currentIndex == list.count) {
                            return;
                        } else {
                            list.currentIndex += 3;
                            list.positionViewAtIndex(list.currentIndex, ListView.SnapPosition);
                        }

                    }
                }
            }

            Text {
                id: itemCount

                Layout.fillWidth: true

                renderType: Text.NativeRendering
                color: "white"
                text: list.currentIndex + " - " + list.count
                font.hintingPreference: Font.PreferFullHinting
                font.kerning: false

                horizontalAlignment: Text.AlignHCenter
            }

            Image {
                id: upButton

                property string suffix: upButtonMa.containsMouse ? "-hover.png" : ".png"

                source: "resources/controls/up" + suffix

                opacity: list.count > 3 && list.currentIndex > 0 ? 1 : 0.5

                MouseArea {
                    id: upButtonMa

                    anchors.fill: parent

                    visible: list.count > 3 && list.currentIndex > 0

                    hoverEnabled: true

                    onClicked: {
                        if(list.currentIndex == 0) {
                            return;
                        } else {
                            list.currentIndex -= 3;
                            list.positionViewAtIndex(list.currentIndex, ListView.SnapPosition);
                        }
                    }
                }
            }
        }
    }

    ListView {
        id: list
        clip: true
        width: parent.width
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: bottomControls.height + Kirigami.Units.smallSpacing*4
        anchors.rightMargin: Kirigami.Units.smallSpacing*2
        anchors.leftMargin: Kirigami.Units.smallSpacing*3 + Kirigami.Units.smallSpacing/4
        interactive: false
        spacing: 0
        model: xmlModel
        delegate: feedDelegate
        snapMode: ListView.SnapToItem
    }

    Rectangle {
        id: fadeGradient

        anchors.right: list.right
        anchors.rightMargin: 8
        anchors.left: list.left
        anchors.leftMargin: 1
        anchors.bottom: bottomControls.top
        anchors.bottomMargin: Kirigami.Units.smallSpacing/2

        height: 35

        gradient: Gradient {
            GradientStop { position: 1.0; color: "black" }
            GradientStop { position: 0.0; color: "transparent" }
        }

        opacity: 0.6

        visible: list.currentIndex < list.count
    }

    Image  {
        id: busyIndicator

        property int frameNumber: 0

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Kirigami.Units.smallSpacing*2

        source: "resources/loading-circle/" + frameNumber

        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            NumberAnimation { target: busyIndicator; property: "frameNumber"; to: 17; duration: 900 }
            NumberAnimation { target: busyIndicator; property: "frameNumber"; to: 0; duration: 0 }
        }
    }

    Flyout {
        id: moreFlyout

        visualParent: bg

        mainItem: KSvg.FrameSvgItem {
            width: flyoutBg.width + Kirigami.Units.smallSpacing*2
            height: flyoutBg.height + Kirigami.Units.smallSpacing*2

            imagePath: "dialogs/background"

            Image {
                id: flyoutBg

                anchors.centerIn: parent

                source: "resources/flyoutBg.png"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.leftMargin: Kirigami.Units.smallSpacing*2
                        Layout.preferredHeight: 31

                        spacing: -4

                        Text {
                            Layout.preferredWidth: 280

                            text: moreFlyout.title
                            color: "white"
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: 10
                            font.bold: true
                        }
                        Text {
                            Layout.preferredWidth: 280

                            text: moreFlyout.creator
                            color: "white"
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: 8
                        }
                    }
                    PlasmaComponents.ScrollView {
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.preferredHeight: 181
                        Layout.preferredWidth: 292

                        ColumnLayout {
                            width: 286

                            Text {
                                Layout.preferredWidth: 286

                                text: moreFlyout.content
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 300000
        running: true
        repeat: true
        onTriggered: { xmlModel.reload() }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: xmlModel.reload()
        }
    ]
}
