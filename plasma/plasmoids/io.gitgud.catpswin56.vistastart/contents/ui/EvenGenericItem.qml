/*****************************************************************************
 *   Copyright (C) 2022 by Friedrich Schriewer <friedrich.schriewer@gmx.net> *
 *                                                                           *
 *   This program is free software; you can redistribute it and/or modify    *
 *   it under the terms of the GNU General Public License as published by    *
 *   the Free Software Foundation; either version 2 of the License, or       *
 *   (at your option) any later version.                                     *
 *                                                                           *
 *   This program is distributed in the hope that it will be useful,         *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *   GNU General Public License for more details.                            *
 *                                                                           *
 *   You should have received a copy of the GNU General Public License       *
 *   along with this program; if not, write to the                           *
 *   Free Software Foundation, Inc.,                                         *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .          *
 ****************************************************************************/
import QtQuick 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import QtQuick.Window 2.2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.kirigami 2.13 as Kirigami
import QtQuick.Controls 2.15

import "code/tools.js" as Tools

Item {
  id: allItem

  width: parent.width - Kirigami.Units.mediumSpacing
  height: Kirigami.Units.iconSizes.smallMedium

  property string text: ""
  property string icon: ""

  Kirigami.Icon {
    id: appicon
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Kirigami.Units.smallSpacing*3
    width: Kirigami.Units.iconSizes.small
    height: width
    source: parent.icon
  }
  PlasmaComponents.Label {
    id: appname
    anchors.left: appicon.right
    anchors.right: parent.right
    anchors.rightMargin: Kirigami.Units.smallSpacing
    anchors.leftMargin: Kirigami.Units.smallSpacing
    anchors.verticalCenter: appicon.verticalCenter
    text: parent.text
    font.underline: ma.containsMouse
    elide: Text.ElideRight
    color: startStyles.currentStyle.searchView.linksColor
  }
  
  KickoffHighlight {
    id: rectFill
    anchors.fill: parent
    anchors.leftMargin: Kirigami.Units.smallSpacing
    anchors.rightMargin: -Kirigami.Units.smallSpacing
    opacity: (ma.containsMouse) * 0.7 + ma.containsMouse * 0.3
    z: -1
  }

  MouseArea {
      id: ma
      anchors.fill: parent
      anchors.leftMargin: Kirigami.Units.iconSizes.small
      z: parent.z + 1
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
  }
}
