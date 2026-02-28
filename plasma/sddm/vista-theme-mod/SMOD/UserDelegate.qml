import QtQuick

import Qt5Compat.GraphicalEffects

Item {
    id: delegate

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    Item {
        id: avatarparent

        anchors.centerIn: parent

        width: 80
        height: width

        Item {
            width: 48
            height: width

            anchors.centerIn: parent

            Rectangle {
                id: maskmini

                anchors.fill: parent
                anchors.centerIn: parent

                radius: 2
                visible: false
            }

            LinearGradient {
                id: gradient

                anchors.fill: parent
                anchors.centerIn: parent

                start: Qt.point(0,0)
                end: Qt.point(gradient.width, gradient.height)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#eeecee" }
                    GradientStop { position: 1.0; color: "#a39ea3" }
                }
            }

            Image {
                id: avatarmini

                anchors.fill: parent
                anchors.centerIn: parent

                source: model.icon
                fillMode: Image.PreserveAspectCrop

                onStatusChanged: if (avatarmini.status == Image.Error) avatarmini.source = "../Assets/user/fallback.png";

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: maskmini
                }
            }
        }

        Image {
            id: avatarminiframe

            anchors.fill: parent

            source: {
                if (userMa.containsMouse && delegate.focus)   return "../Assets/user/small-hover-focus.png"
                else if (userMa.containsMouse && !delegate.focus)  return "../Assets/user/small-hover.png"
                else if (!userMa.containsMouse && delegate.focus)  return "../Assets/user/small-focus.png"
                else if (!userMa.containsMouse && !delegate.focus) return "../Assets/user/small.png"
            }
        }
    }

    Text {
        anchors.top: avatarparent.bottom
        anchors.horizontalCenter: avatarparent.horizontalCenter

        text: (model.realName === "") ? model.name : model.realName
        color: "white"
        font.pixelSize: 12
        renderType: Text.NativeRendering
        font.hintingPreference: Font.PreferFullHinting
        font.kerning: false
    }

    MouseArea {
        id: userMa
        anchors.fill: delegate
        anchors.margins: Math.round(delegate.width / 4.5)
        hoverEnabled: true
    }
}
