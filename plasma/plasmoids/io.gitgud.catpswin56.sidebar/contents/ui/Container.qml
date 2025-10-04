import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import "controls/"

Item {
    id: containerRect

    property int toolboxSpace: sidebar_toolbox.anchors.topMargin + sidebar_toolbox.height + Kirigami.Units.smallSpacing * 5

    HoverHandler { id: sidebarMa }

    Image {
        id: bg_normal

        anchors.fill: parent

        source: "pngs/backgrounds/" + (root.sidebarLocation ? "left" : "right") + ".png"

        visible: !root.sidebarDock

        BorderImage {
            anchors.fill: parent

            border {
                left: root.sidebarLocation ? 0 : 2
                right: root.sidebarLocation ? 2 : 0
                top: 126
                bottom: 56
            }
            source: "pngs/backgrounds/" + (root.sidebarLocation ? "left" : "right") + "-overlay.png"

            opacity: sidebarMa.hovered ? 1.0 : 0
            Behavior on opacity {
                NumberAnimation { duration: 1700 }
            }
        }
    }

    BorderImage {
        id: bg_keepabove

        anchors.fill: parent

        border {
            left: root.sidebarLocation ? 0 : 2
            right: root.sidebarLocation ? 2 : 0
            top: 124
            bottom: 56
        }
        source: "pngs/backgrounds/" + (root.sidebarLocation ? "left" : "right") + "-keepabove.png"

        visible: root.sidebarDock
    }

    RowLayout {
        id: sidebar_toolbox

        anchors {
            top: parent.top
            topMargin: Kirigami.Units.smallSpacing*2
            right: parent.right
            rightMargin: Kirigami.Units.smallSpacing*2
        }

        spacing: -13
        layoutDirection: root.sidebarLocation

        Image {
            id: gadget_text

            source: "pngs/sidebar-toolbox/text-" + (root.sidebarLocation ? "left" : "right") + ".png"

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.sidebarLocation ? 6 : -6

                text: "Gadgets"
                color: "white"
            }

            opacity: add.containsMouse
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        Image {
            id: actions

            source: "pngs/sidebar-toolbox/background.png"

            RowLayout {
                spacing: 0

                SegmentedControl {
                    id: add

                    pixmap: Qt.resolvedUrl("pngs/sidebar-toolbox/add.png")
                    count: 4
                    onClicked: root.showGadgetExplorer();
                }

                Image { source: "pngs/sidebar-toolbox/separator.png" }

                SegmentedControl {
                    id: left

                    pixmap: Qt.resolvedUrl("pngs/sidebar-toolbox/left.png")
                    count: 4
                    enabled: mainStack.can_scrollLeft
                    onClicked: mainStack.scrollLeft()
                }
                SegmentedControl {
                    id: right

                    pixmap: Qt.resolvedUrl("pngs/sidebar-toolbox/right.png")
                    count: 4
                    enabled: mainStack.can_scrollRight
                    onClicked: mainStack.scrollRight()
                }
            }
        }
    }
}
