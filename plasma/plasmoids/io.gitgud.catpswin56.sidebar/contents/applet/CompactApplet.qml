/*
 *  SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import org.kde.plasma.plasmoid

PlasmaCore.ToolTipArea {
    id: root
    objectName: "org.kde.desktop-CompactApplet"

    // icon: plasmoidItem.icon
    mainText: plasmoidItem ? plasmoidItem.toolTipSubText : ""
    location: PlasmaCore.Types.Desktop
    active: plasmoidItem ? !plasmoidItem.expanded : false
    textFormat: plasmoidItem ? plasmoidItem.toolTipTextFormat : 0
    mainItem: plasmoidItem && plasmoidItem.toolTipItem ? plasmoidItem.toolTipItem : null
    property PlasmoidItem plasmoidItem

    z: 1

    property Item fullRepresentation
    property Item compactRepresentation

    onCompactRepresentationChanged: {
        if (compactRepresentation) {
            compactRepresentation.parent = root;
            compactRepresentation.anchors.fill = root;
            compactRepresentation.visible = true;
        }
        root.visible = true;
    }

    onFullRepresentationChanged: {

        if (!fullRepresentation) {
            return;
        }
        //if the fullRepresentation size was restored to a stored size, or if is dragged from the desktop, restore popup size
        if (fullRepresentation.width > 0) {
            popupWindow.mainItem.width = Qt.binding(function() {
                return fullRepresentation.width
            })
        } else if (fullRepresentation.Layout && fullRepresentation.Layout.preferredWidth > 0) {
            popupWindow.mainItem.width = Qt.binding(function() {
                return fullRepresentation.Layout.preferredWidth
            })
        } else if (fullRepresentation.implicitWidth > 0) {
            popupWindow.mainItem.width = Qt.binding(function() {
                return fullRepresentation.implicitWidth
            })
        } else {
            popupWindow.mainItem.width = Qt.binding(function() {
                return Kirigami.Theme.gridUnit * 35
            })
        }

        if (fullRepresentation.height > 0) {
            popupWindow.mainItem.height = Qt.binding(function() {
                return fullRepresentation.height
            })
        } else if (fullRepresentation.Layout && fullRepresentation.Layout.preferredHeight > 0) {
            popupWindow.mainItem.height = Qt.binding(function() {
                return fullRepresentation.Layout.preferredHeight
            })
        } else if (fullRepresentation.implicitHeight > 0) {
            popupWindow.mainItem.height = Qt.binding(function() {
                return fullRepresentation.implicitHeight
            })
        } else {
            popupWindow.mainItem.height = Qt.binding(function() {
                return Kirigami.Theme.gridUnit * 25
            })
        }

        fullRepresentation.parent = appletParent;
        fullRepresentation.anchors.fill = fullRepresentation.parent;
    }

    Timer {
        id: expandedSync
        interval: 100
        onTriggered: plasmoidItem.expanded = popupWindow.visible;
    }

    Connections {
        target: Plasmoid.internalAction("configure")
        function onTriggered() {
            plasmoidItem.expanded = false
        }
    }

    Connections {
        target: Plasmoid
        function onContextualActionsAboutToShow() {
            root.hideToolTip()
        }
    }

    Connections {
        target: Plasmoid
        function onContextualActionsAboutToShow() {
            root.hideToolTip()
        }
    }

    PlasmaCore.Dialog {
        id: popupWindow

        objectName: "popupWindow"

        property var oldStatus: PlasmaCore.Types.UnknownStatus

        flags: Qt.WindowStaysOnTopHint
        visualParent: compactRepresentation ? compactRepresentation : null
        location: Plasmoid.location
        hideOnWindowDeactivate: true
        appletInterface: plasmoidItem
        backgroundHints: PlasmaCore.Dialog.SolidBackground

        //It's a MouseEventListener to get all the events, so the eventfilter will be able to catch them
        mainItem: MouseEventListener {
            id: appletParent

            Keys.onEscapePressed: plasmoidItem.expanded = false;

            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
            LayoutMirroring.childrenInherit: true

            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false

            Layout.minimumWidth: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.minimumWidth : 0
            Layout.minimumHeight: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.minimumHeight: 0
            Layout.maximumWidth: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.maximumWidth : Infinity
            Layout.maximumHeight: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.maximumHeight: Infinity

            onActiveFocusChanged: {
                if(activeFocus && fullRepresentation) {
                    fullRepresentation.forceActiveFocus()
                }
            }
        }

        visible: plasmoidItem.expanded && fullRepresentation
        onVisibleChanged: {
            if (!visible) {
                expandedSync.restart();
                plasmoid.status = oldStatus;
            } else {
                oldStatus = plasmoid.status;
                plasmoid.status = PlasmaCore.Types.RequiresAttentionStatus;
                // This call currently fails and complains at runtime:
                // QWindow::setWindowState: QWindow::setWindowState does not accept Qt::WindowActive
                popupWindow.requestActivate();
            }
        }
    }
}
