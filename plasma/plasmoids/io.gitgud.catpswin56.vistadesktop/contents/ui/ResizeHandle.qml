import QtQuick

Rectangle {
    id: controlRoot

    property string position: "none"
    property bool canExtendX: true
    property bool canExtendY: true

    width: 15
    height: 15

    color: canExtendX && canExtendY ? "black" : "darkred"
    border.width: 1
    border.color: "white"
    radius: 999

    MouseArea {
        id: ma

        property Item parentObject: controlRoot.parent.parent
        property point pressPoint: Qt.point(0, 0)

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: {
            if(controlRoot.position == "topleft" || controlRoot.position == "bottomright")
                return Qt.SizeFDiagCursor;
            if(controlRoot.position == "topright" || controlRoot.position == "bottomleft")
                return Qt.SizeBDiagCursor;

            if(controlRoot.position == "left" || controlRoot.position == "right")
                return Qt.SizeHorCursor;
            if(controlRoot.position == "top" || controlRoot.position == "bottom")
                return Qt.SizeVerCursor;
        }
        onPressed: (event) => pressPoint = Qt.point(Math.round(event.x), Math.round(event.y));
        onPressedChanged: {
            if(!pressed) {
                pressPoint = Qt.point(0, 0);
                controlRoot.canExtendX = true;
                controlRoot.canExtendY = true;
            }
        }
        onMouseXChanged: {
            var widthToAdd = Math.round(mouseX) - pressPoint.x;

            if(pressed && (widthToAdd > pressPoint.x || widthToAdd < pressPoint.x)) {
                var remnant = 0;

                if(controlRoot.position.includes("left")) {
                    controlRoot.canExtendX = parentObject.x > parentObject.parent.x;

                    remnant = parentObject.x + widthToAdd;
                    if(remnant < 0) widthToAdd -= remnant;

                    if(controlRoot.canExtendX || (!controlRoot.canExtendX && widthToAdd > 0)) {
                        parentObject.x += widthToAdd;
                        parentObject.width -= widthToAdd;
                    }
                }
                else if(controlRoot.position.includes("right")) {
                    var targetDistance = parentObject.x + parentObject.width;
                    var targetParentDistance = parentObject.parent.x + parentObject.parent.width;

                    controlRoot.canExtendX = targetDistance < targetParentDistance;

                    remnant = targetDistance + widthToAdd;
                    if(remnant > targetParentDistance) widthToAdd += targetParentDistance - remnant;

                    if(controlRoot.canExtendX || (!controlRoot.canExtendX && widthToAdd < 0)) parentObject.width += widthToAdd;
                }
            }
        }
        onMouseYChanged: {
            var heightToAdd = Math.round(mouseY) - pressPoint.y;

            if(pressed && (heightToAdd > pressPoint.y || heightToAdd < pressPoint.y)) {
                var remnant = 0;

                if(controlRoot.position.includes("top")) {
                    controlRoot.canExtendY = parentObject.y > parentObject.parent.y;

                    remnant = parentObject.y + heightToAdd;
                    if(remnant < 0) heightToAdd -= remnant;

                    if(controlRoot.canExtendY || (!controlRoot.canExtendY && heightToAdd > 0)) {
                        parentObject.y += heightToAdd;
                        parentObject.height -= heightToAdd;
                    }
                }
                else if(controlRoot.position.includes("bottom")) {
                    var targetDistance = parentObject.y + parentObject.height;
                    var targetParentDistance = parentObject.parent.y + parentObject.parent.height;

                    controlRoot.canExtendY = targetDistance < targetParentDistance;

                    remnant = targetDistance + heightToAdd;
                    if(remnant > targetParentDistance) heightToAdd += targetParentDistance - remnant;

                    if(controlRoot.canExtendY || (!controlRoot.canExtendY && heightToAdd < 0)) parentObject.height += heightToAdd;
                }
            }
        }
    }
}
