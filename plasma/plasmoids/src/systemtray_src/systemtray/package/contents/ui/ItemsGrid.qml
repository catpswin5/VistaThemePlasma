import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Flow {
    id: tasksGrid

    required property ContainmentItem root

    property alias repeater: repeater
    property alias model: repeater.model
    property alias delegate: repeater.delegate

    spacing: Kirigami.Settings.tabletMode ? Kirigami.Units.mediumSpacing : Kirigami.Units.smallSpacing / 2
    flow: root.vertical ? Flow.LeftToRight : Flow.TopToBottom

    Repeater { id: repeater }
}
