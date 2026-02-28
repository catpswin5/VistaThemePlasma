import QtQuick 2.4
import QtQuick.Controls
//import QtQuick.Controls.Styles
import QtQuick.Layouts 1.1
import QtQuick.Dialogs
import QtQuick.Window 2.1
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.ksvg as KSvg

Control {
    id: genericButton
    signal clicked

    property string text: "";
    property var iconSource: "";
    property int iconSize: Kirigami.Units.iconSizes.smallMedium;
    property alias label: btnLabel

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => {
        if(event.key == Qt.Key_Return) {
            genericButton.clicked();
        }
    }

    BorderImage {
        border {
            top: 3
            bottom: 3
            left: 3
            right: 3
        }
        source: {
            if(buttonMA.containsPress) return "../Assets/switchuser/pressed.png"
            if(buttonMA.containsMouse && genericButton.focus) return "../Assets/switchuser/hover-focus.png"
            if(buttonMA.containsMouse && !genericButton.focus) return "../Assets/switchuser/hover.png"
            if(!buttonMA.containsMouse && genericButton.focus) return "../Assets/switchuser/normal-focus.png"
            return "../Assets/switchuser/normal.png"
        }
    }
    MouseArea {
        id: buttonMA
        z: 99
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton;
        onClicked: (mouse) => {
            genericButton.clicked();
        }
    }
    Kirigami.Icon{
        id: btnIcon
        z: 0
        anchors.centerIn: genericButton
        width: genericButton.iconSize
        height: width
        animated: false
        //usesPlasmaTheme: false
        source: genericButton.iconSource
        visible: genericButton.iconSource !== ""
    }
    PlasmaComponents.Label {
        id: btnLabel
        z: 0
        anchors.fill: parent
        anchors.margins: 3
        text: genericButton.text
        visible: genericButton.text !== ""
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: "white"
    }
}
