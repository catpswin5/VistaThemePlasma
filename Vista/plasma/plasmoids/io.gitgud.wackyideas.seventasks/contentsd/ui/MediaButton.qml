import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQml.Models

import org.kde.plasma.core 2.0 as PlasmaCore


// I am going to kirigami myself
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

// import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons


MouseArea {
    id: mediaButton

    Layout.maximumWidth: Kirigami.Units.gridUnit*1.5;
    Layout.maximumHeight: Kirigami.Units.gridUnit*1.5 - Kirigami.Units.smallSpacing;
    Layout.preferredWidth: Kirigami.Units.gridUnit*1.5;
    Layout.preferredHeight: Kirigami.Units.gridUnit*1.5 - Kirigami.Units.smallSpacing;

    //signal clicked
    property string orientation: ""
    property string mediaIcon: ""
    property bool enableButton: false
    enabled: enableButton
    property bool togglePlayPause: true
    property string fallbackMediaIcon: ""


    hoverEnabled: true
    KSvg.FrameSvgItem {
        id: normalButton
        imagePath: Qt.resolvedUrl("svgs/button-media.svg")
        anchors.fill: parent
        prefix: orientation + "-normal"
        opacity: !(parent.containsMouse && enableButton)
        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }
    KSvg.FrameSvgItem {
        id: internalButtons
        imagePath: Qt.resolvedUrl("svgs/button-media.svg")
        anchors.fill: parent
        prefix: parent.containsPress ? orientation + "-pressed" : orientation + "-hover";
        opacity: parent.containsMouse && enableButton
        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }

    KSvg.SvgItem {
        id: mediaIconSvg
        svg: mediaIcons
        elementId: mediaIcon
        width: Kirigami.Units.iconSizes.small;
        height:  Kirigami.Units.iconSizes.small;
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: parent.containsPress ? 1 : 0
        anchors.verticalCenterOffset: parent.containsPress ? 1 : 0
        opacity: (enableButton ? 1.0 : 0.35) * togglePlayPause
        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }
    KSvg.SvgItem {
        id: mediaIconSvgSecond
        svg: mediaIcons
        elementId: fallbackMediaIcon
        width: Kirigami.Units.iconSizes.small;
        height:  Kirigami.Units.iconSizes.small;
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: parent.containsPress ? 1 : 0
        anchors.verticalCenterOffset: parent.containsPress ? 1 : 0
        opacity: (enableButton ? 1.0 : 0.35) * !togglePlayPause
        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }

}

