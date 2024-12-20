import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    type: PlasmaCore.Dialog.PopupMenu
    flags: Qt.WindowStaysOnTopHint
    hideOnWindowDeactivate: true
    backgroundHints: PlasmaCore.Types.NoBackground
    location: "RightEdge"

    property int itemIndex // to identify which item should have the selected state
    property string title: "undefined"
    property string creator: "undefined"
    property string content: "undefined"
}
