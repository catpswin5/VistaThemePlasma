import QtQuick

import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: iconContainer

    property alias iconSource: imgAuthorIcon.source
    property alias fallbackIcon: imgAuthorIcon.fallback

    anchors.horizontalCenter: parent.horizontalCenter

    width: height
    height: Kirigami.Units.iconSizes.huge

    BorderImage {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        border {
            left: 11
            right: 11
            top: 11
            bottom: 11
        }
        source: "pngs/user-frame.png"
        smooth: true

        z: 1
        opacity: imgAuthorIcon.source === ""
        Behavior on opacity {
            NumberAnimation { duration: 350 }
        }
    }

    LinearGradient {
        id: gradient

        anchors.fill: imgAuthor

        start: Qt.point(0,0)
        end: Qt.point(gradient.width, gradient.height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#eeecee" }
            GradientStop { position: 1.0; color: "#a39ea3" }
        }
    }

    Kirigami.Icon {
        anchors.fill: imgAuthor
        anchors.margins: Kirigami.Units.largeSpacing

        source: "preferences-desktop-user"

        visible: imgAuthor.status === Image.Null || imgAuthor.status === Image.Error
    }

    Image {
        id: imgAuthor

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom

            leftMargin: Kirigami.Units.smallSpacing*2
            rightMargin: Kirigami.Units.smallSpacing*2
            topMargin: Kirigami.Units.smallSpacing*2
            bottomMargin: Kirigami.Units.smallSpacing*2
        }

        source: kuser.faceIconUrl.toString()
        cache: false
        smooth: true
        mipmap: true

        visible: false
        opacity: imgAuthorIcon.source === ""
        Behavior on opacity {
            NumberAnimation { duration: 350 }
        }
    }

    Kirigami.Icon {
        id: imgAuthorIcon

        width: height
        height: parent.height

        source: ""
        CrossFadeBehavior on source {
            fadeDuration: 350
        }

        smooth: true
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton
        onPressed: {
            KCM.KCMLauncher.openSystemSettings("kcm_users")
            root.visible = false;
        }
        cursorShape: Qt.PointingHandCursor
    }
}
