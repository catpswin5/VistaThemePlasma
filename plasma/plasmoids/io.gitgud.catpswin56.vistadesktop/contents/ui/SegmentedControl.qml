import QtQuick

MouseArea {
    id: root

    property alias pixmap: image.source
    property int count: 4
    property int _y_multiplier: 0
    readonly property int _controlHeight: dummy_img.implicitHeight / count

    implicitWidth: image.implicitWidth
    implicitHeight: image.implicitHeight

    hoverEnabled: true
    onEnabledChanged: {
        if(!enabled) _y_multiplier = 3;
        else _y_multiplier = 0;
    }
    onContainsMouseChanged: {
        if(!containsPress && enabled) {
            if(containsMouse) _y_multiplier = 1;
            else _y_multiplier = 0;
        }
    }
    onPressed: if(enabled) _y_multiplier = 2;
    onReleased: {
        if(containsMouse && enabled) _y_multiplier = 1;
        else _y_multiplier = 0;
    }

    // there's no property to access the size of the image before
    // any modification is done to it, unless there actually is
    // and I'm just dumb.
    Image {
        id: dummy_img
        source: image.source
        visible: false
    }

    Image {
        id: image
        Connections {
            target: root
            function onEnabledChanged() {
                image.visible = false;
                image.visible = true;
            }
        }
        sourceClipRect: Qt.rect(0, root._controlHeight * root._y_multiplier, implicitWidth, root._controlHeight);
    }
}
