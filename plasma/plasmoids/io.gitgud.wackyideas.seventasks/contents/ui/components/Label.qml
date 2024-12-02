import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color foreground: "black"
    property alias wrapping: text.wrapMode
    property alias size: text.font.pointSize
    property alias text: text.text
    property alias bold: text.font.bold
    property alias underlined: text.font.underline
    property alias alignmentH: text.horizontalAlignment
    property alias alignmentV: text.verticalAlignment

    property alias shadow: shadow
    property bool enableShadow: false
    property color background: "transparent"

    implicitWidth: text.implicitWidth
    implicitHeight: text.implicitHeight

    Rectangle {
        id: bg

        anchors.fill: text

        visible: parent.background != "transparent"

        color: parent.background
    }

    DropShadow {
        id: shadow
        visible: parent.enableShadow
        anchors.fill: text
        source: text
        horizontalOffset: 0
        verticalOffset: 2
        radius: 2
        samples: 6
        spread: 0.0001
        color: "#bf000000"
    }

    Text {
        id: text

        anchors.fill: parent

        styleColor: "transparent"
        style: Text.Sunken
        color: parent.foreground
        elide: Text.ElideRight

        Text {
            id: highlight

            anchors.fill: parent

            text: parent.text
            color: parent.color
            styleColor: "transparent"
            style: Text.Sunken
            elide: Text.ElideRight
            font.pointSize: parent.font.pointSize
            wrapMode: parent.wrapMode
            horizontalAlignment: parent.horizontalAlignment
            verticalAlignment: parent.verticalAlignment
            font.bold: parent.font.bold

            opacity: 0.66
        }
    }
}
