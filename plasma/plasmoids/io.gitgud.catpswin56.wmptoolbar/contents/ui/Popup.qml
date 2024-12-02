import QtQuick

import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: popup

    type: PlasmaCore.Dialog.PopupMenu
    flags: Qt.WindowStaysOnTopHint
    hideOnWindowDeactivate: true
    backgroundHints: PlasmaCore.Types.NoBackground
    location: "Floating"

    Image {
        anchors.fill: parent
        source: "png/frame.png"
    }
}
