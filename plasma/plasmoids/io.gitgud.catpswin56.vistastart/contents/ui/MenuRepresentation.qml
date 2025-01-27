/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import QtCore

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons // kuser
import org.kde.kitemmodels as KItemModels

import org.kde.kwindowsystem 1.0
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import Qt5Compat.GraphicalEffects

PlasmaCore.Dialog {
    id: root
    objectName: "popupWindow"
    location: "Floating" // To make the panel display all 4 borders, the panel will be positioned at a corner.
    flags: Qt.WindowStaysOnTopHint //| Qt.Popup // Set to popup so that it is still considered a plasmoid popup, despite being a floating dialog window.
	hideOnWindowDeactivate: true
    
    backgroundHints: PlasmaCore.Types.NoBackground

    property int iconSize: Kirigami.Units.iconSizes.medium
    property int iconSizeSide: Kirigami.Units.iconSizes.smallMedium
    property int cellWidth: 254 // Width for all standard menu items.
    property int cellWidthSide: 139 // Width for sidebar menu items.
    property int cellHeight: iconSize + Kirigami.Units.smallSpacing + (Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                    				   highlightItemSvg.margins.left + highlightItemSvg.margins.right)) - Kirigami.Units.smallSpacing/2
	property int cellCount: Plasmoid.configuration.numberRows + faves.getFavoritesCount()
    property bool searching: (searchField.text != "")
    property bool showingAllPrograms: false
    property bool firstTimePopup: false // To make sure the user icon is displayed properly.
    property bool firstTimeShadowSetup: false

    property int animationDuration: Plasmoid.configuration.enableAnimations ? Kirigami.Units.longDuration*1.5 : 0

	property color leftPanelBackgroundColor: "white"
	property color leftPanelBorderColor: "#44000000"
	property color leftPanelSeparatorColor: "#e2e2e2"
	property color searchPanelSeparatorColor: "#cddbea"
	property color searchPanelBackgroundColor: "#f1f5fb"

	property color searchFieldBackgroundColor: "white"
	property color searchFieldTextColor: "black"
	property color searchFieldPlaceholderColor: "#707070"

	property color shutdownTextColor: "#202020"

	// A bunch of references for easier access by child QML elements
	property alias m_mainPanel: leftSidebar
	property alias m_bottomControls: bottomControls
	property alias m_allApps: appsView
	property alias m_recents: recents
	property alias m_faves: faves
	property alias m_showAllButton: allButtonsArea
	property alias m_shutDownButton: shutdown
	property alias m_lockButton: lockma
	property alias m_searchField: searchField
	property alias m_delayTimer: delayTimer
	property alias dialogBackgroundTexture: dialogBackground

	function setFloatingAvatarPosition()  {
		// It's at this point where everything actually gets properly initialized and we don't have to worry about
		// random unpredictable values, so we can safely allow the popup icon to show up.
		iconUser.x = root.x + sidePanel.x+sidePanel.width/2-Kirigami.Units.iconSizes.huge/2 + Kirigami.Units.smallSpacing/2 - 1;
		iconUser.y = root.y-Kirigami.Units.iconSizes.huge/2 + Kirigami.Units.smallSpacing;
		firstTimePopup = true;
	}

	onXChanged: {
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
	}
	onYChanged: {
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
	}

    onVisibleChanged: {
		popupPosition();
        if (!visible) {
            reset();
        } else {
            requestActivate();
			searchField.forceActiveFocus();
			rootModel.refresh();
			setFloatingAvatarPosition();
			Plasmoid.setDialogAppearance(root, dialogBackground.mask);
			Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);

			if(!firstTimeShadowSetup) {
				shadow_fix.start()
			}
        }
		resetRecents(); // Resets the recents model to prevent errors and crashes.
    }
    onHeightChanged: {
		popupPosition();
		setFloatingAvatarPosition();
		Plasmoid.setDialogAppearance(root, dialogBackground.mask);
    }

    onWidthChanged: {
		popupPosition();
		setFloatingAvatarPosition();
		Plasmoid.setDialogAppearance(root, dialogBackground.mask);
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
    }

    onSearchingChanged: {
        if (!searching) {
			reset();
        }
    }
    
    function resetRecents() {
        recents.currentIndex = -1;
    }
    function reset() {
        searchField.text = "";
		compositingIcon.iconSource = "";
		nonCompositingIcon.iconSource = "";
		searchField.forceActiveFocus();
    }
	
	//The position calculated is always at a corner.
	function popupPosition() {
		var pos = kicker.mapToGlobal(kicker.x, kicker.y);
		var availScreen = Plasmoid.containment.availableScreenRect;
		var screen = kicker.screenGeometry;

		x = pos.x;
		y = pos.y - root.height;

		if(x <= 0) x = availScreen.x;
		if(x + root.width - screen.x >= availScreen.width) {
			x = screen.x + availScreen.width - root.width;
		}
		if(y <= 0) y = availScreen.y;
		if(y + root.height - screen.y >= availScreen.height) {
			y = screen.y + availScreen.height - root.height;
		}
    }
    function raiseOrb() {
		orb.raise();
	}

    FocusScope {
		id: mainFocusScope
		objectName: "MainFocusScope"
        Layout.minimumWidth: Math.max(397, root.cellWidth + Kirigami.Units.mediumSpacing + columnItems.width) + Kirigami.Units.mediumSpacing*2
		Layout.maximumWidth: Math.max(397, root.cellWidth + Kirigami.Units.mediumSpacing + columnItems.width) + Kirigami.Units.mediumSpacing*2

		property int extraPadding: (compositingEnabled
		? (Plasmoid.location != PlasmaCore.Types.TopEdge ? Kirigami.Units.iconSizes.huge / 2 - Kirigami.Units.smallSpacing*4
		: nonCompositingIcon.height) // top panel
		: nonCompositingIcon.height); // no compositing

		property int mainPanelHeight: leftSidebar.height + bottomControls.height
		property int sidePanelHeight: backgroundBorderLine.height + searchBackground.height + columnItems.height + extraPadding

        Layout.minimumHeight: Math.max(Math.max(mainPanelHeight, sidePanelHeight), 377) + Kirigami.Units.smallSpacing/2 + Kirigami.Units.mediumSpacing*2
        Layout.maximumHeight: Math.max(Math.max(mainPanelHeight, sidePanelHeight), 377) + Kirigami.Units.smallSpacing/2 + Kirigami.Units.mediumSpacing*2
        
        focus: true
		clip: false

		Timer {
			id: shadow_fix
			interval: 25
			onTriggered: {
				Plasmoid.enableShadow(Plasmoid.configuration.enableShadow);
				Plasmoid.syncBorders(Qt.rect(dashWindow.x, dashWindow.y, dashWindow.width, dashWindow.height), Plasmoid.location);
				firstTimeShadowSetup = true;
			}
		}
		Timer { // Janky wayland problems require janky solutions
			id: wayland_fix
			interval: 25
			onTriggered: root.hideOnWindowDeactivate = true;
		}


        KCoreAddons.KUser {   id: kuser  }  // Used for getting the username and icon.
        
        /*
		 * The user icon is supposed to stick out of the start menu, so a separate dialog window
		 * is required to pull that effect off. Inspiration taken from SnoutBug's MMcK launcher,
		 * however with some minor adjustments and improvements.
		 *
		 * The flag Qt.X11BypassWindowManagerHint is used to prevent the dialog from animating its
		 * opacity when its visibility is changed directly, and Qt.Popup is used to ensure that it's
		 * above the parent dialog window.
		 *
		 * Setting the location to "Floating" means that we can use manual positioning for the dialog
		 * which is important as positioning a dialog like this is tricky at best and unpredictable
		 * at worst. Positioning of this dialog window can only be done reliably when:
		 *
		 * 1. The parent dialog window is visible, this ensures that the positioning of the window
		 * 	  is actually initialized and not simply declared.
		 * 2. The width and height of the parent dialog window are properly initialized as well.
		 *
		 * This is why the position of this window is determined on the onHeightChanged slot of the
		 * parent window, as by then both the position and size of the parent are well defined.
		 * It should be noted that the position values for any dialog window are gonna become
		 * properly initialized once the visibility of the window is enabled, at least from what
		 * I could figure out. Anything before that and the properties won't behave well.
		 *
		 * To comment on MMcK's implementation, this is likely why positioning of the floating
		 * avatar is so weird and unreliable. Using uninitialized values always leads to
		 * unpredictable behavior, which leads to positioning being all over the place.
		 *
		 * The firstTimePopup is used to make sure that the dialog window has its correct position
		 * values before it is made visible to the user.
		 */
		Item {
			PlasmaCore.Dialog {
        		id: iconUser
				location: "Floating"

				type: "Notification"
				title: "seventasks-floatingavatar"
				x: 0
				y: 0
				backgroundHints: PlasmaCore.Types.NoBackground // To prevent the dialog background SVG from being rendered, we want a fully transparent window.
				visible: root.visible && compositingEnabled && Plasmoid.location != PlasmaCore.Types.TopEdge
				opacity: iconUser.visible && firstTimePopup // To prevent even more NP-hard unpredictable behavior
				mainItem: FloatingIcon {
					id: compositingIcon
					visible: compositingEnabled
				}
        	}
		}
		Connections { 
			target: root 
			function onActiveFocusItemChanged() {
				if(root.activeFocusItem === null) {
					root.requestActivate();
				}
			}
		}
		Connections {
			target: kicker

			function onScreenGeometryChanged() {
				firstTimePopup = false;
			}
			function onScreenChanged() {
				firstTimePopup = false;
			}
		}
        Connections {
        target: Plasmoid.configuration
            function onNumberRowsChanged() {
                recents.model.sourceModel.refresh();
            }
        }
        Plasma5Support.DataSource {
            id: pmEngine
            engine: "powermanagement"
            connectedSources: ["PowerDevil", "Sleep States"]
            function performOperation(what) {
                var service = serviceForSource("PowerDevil")
                var operation = service.operationDescription(what)
                service.startOperationCall(operation)
            }
        }

        Plasma5Support.DataSource {
            id: executable
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => {
                disconnectSource(sourceName)
            }
            function exec(cmd) {
                if (cmd) {
                    connectSource(cmd)
                }
            }
        }

        Kicker.SystemModel {
			id: systemModel
			favoritesModel: globalFavorites
		}
        component FilteredModel : KItemModels.KSortFilterProxyModel {
			sourceModel: systemModel

			function systemFavoritesContainsRow(sourceRow, sourceParent) {
				const FavoriteIdRole = sourceModel.KItemModels.KRoleNames.role("favoriteId");
				const favoriteId = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), FavoriteIdRole);
				return String(Plasmoid.configuration.systemFavorites).includes(favoriteId);
			}

			function trigger(index) {
				const sourceIndex = mapToSource(this.index(index, 0));
				systemModel.trigger(sourceIndex.row, "", null);
			}

			Component.onCompleted: {
				Plasmoid.configuration.valueChanged.connect((key, value) => {
					if (key === "systemFavorites") {
						invalidateFilter();
					}
				});
			}
		}

		FilteredModel {
			id: filteredMenuItemsModel
			filterRowCallback: root.shouldCollapseButtons
			? null /*i.e. keep all rows*/
			: (sourceRow, sourceParent) => !systemFavoritesContainsRow(sourceRow, sourceParent)
		}

		Instantiator {
			model: filteredMenuItemsModel
			delegate: PlasmaExtras.MenuItem {
				required property int index
				required property var model

				text: "       " + model.display + "      "
				onClicked: filteredMenuItemsModel.trigger(index)
			}
			onObjectAdded: (index, object) => {
				if(object.model.decoration != "system-shutdown") {
					if(index == 3 || index == 5)
						var separator = Qt.createQmlObject(`
						import org.kde.plasma.extras as PlasmaExtras

						PlasmaExtras.MenuItem { separator: true }
						`, contextMenu);
					contextMenu.addMenuItem(object);
				}
			}
			onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object)
		}

		Instantiator {
			model: fileUsageModel
			delegate: PlasmaExtras.MenuItem {
				required property int index
				required property var model

				text: model.display + "      "
				icon: model.decoration
				onClicked: fileUsageModel.trigger(index, "", null)
			}
			onObjectAdded: (index, object) => fileUsageMenu.addMenuItem(object);
			onObjectRemoved: (index, object) => fileUsageMenu.removeMenuItem(object)
		}

        PlasmaExtras.Menu {
			id: contextMenu
			visualParent: lockScreenDelegate
			placement: {
				switch (Plasmoid.location) {
					case PlasmaCore.Types.LeftEdge:
					case PlasmaCore.Types.RightEdge:
					case PlasmaCore.Types.TopEdge:
						return PlasmaExtras.Menu.BottomPosedRightAlignedPopup;
					case PlasmaCore.Types.BottomEdge:
					default:
						return PlasmaExtras.Menu.RightPosedBottomAlignedPopup;
				}
			}
		}

		PlasmaExtras.Menu {
			id: fileUsageMenu
			visualParent: recentsItem
			placement: {
				switch (Plasmoid.location) {
					case PlasmaCore.Types.LeftEdge:
					case PlasmaCore.Types.RightEdge:
					case PlasmaCore.Types.TopEdge:
						return PlasmaExtras.Menu.BottomPosedRightAlignedPopup;
					case PlasmaCore.Types.BottomEdge:
					default:
						return PlasmaExtras.Menu.RightPosedBottomAlignedPopup;
				}
			}
		}

		KSvg.FrameSvgItem {
			id: dialogBackground
			anchors.fill: parent
			imagePath: Qt.resolvedUrl("svgs/dialog.svgz");
			//opacity: 0
		}

        Rectangle {
			id: backgroundGradient
			anchors.fill: parent
			anchors.topMargin: 2
			anchors.leftMargin: 2
			anchors.rightMargin: 2
			anchors.bottomMargin: 2
			gradient: Gradient {
				GradientStop { position: 0.0; color: "white" }
				GradientStop { position: 0.11; color: "white" }
				GradientStop { position: 0.2775; color: "transparent" }
				GradientStop { position: 0.445; color: "transparent" }
				GradientStop { position: 0.51; color: "transparent" }
				GradientStop { position: 0.84; color: "transparent" }
				GradientStop { position: 1.0; color: "transparent" }
			}
			topLeftRadius: 8
			topRightRadius: 8
			opacity: 0
		}

		/*
		 * This rectangle acts as a background for the left panel of the start menu.
		 * The rectangle backgroundBorderLine is the border separating the search field
		 * and the rest of the panel, while the searchBackground rectangle is the background
		 * for the search field.
		 */
        KSvg.FrameSvgItem {
        	id: backgroundRect
        	anchors.top: leftSidebar.top
        	anchors.topMargin: -Kirigami.Units.smallSpacing// + Kirigami.Units.mediumSpacing
        	anchors.left: leftSidebar.left
        	anchors.bottom: bottomControls.bottom
        	anchors.bottomMargin: searchField.height + Kirigami.Units.mediumSpacing * 2 - 1
        	imagePath: Qt.resolvedUrl("svgs/background.svg")

			width:  searching ? searchView.width : root.cellWidth

        	CrossFadeBehavior on width {
				fadeDuration: 200
				easingType: "Linear"
			}
        	Rectangle {
        		id: backgroundBorderLine

        		height: Kirigami.Units.smallSpacing

        		gradient: Gradient {
					GradientStop { position: 0.0; color: "#ccd9ea" }
					GradientStop { position: 1.0; color: "#f0f4fa" }
				}

        	 	anchors {
        	   		top: searchBackground.top
        	   		left: parent.left
        	   		right: parent.right
        	   		leftMargin: 2
        	   		rightMargin: 2
        		}
        		z: 4
        		opacity: 0
        	}
        	Rectangle {
                id: searchBackground

                height: 45
                color: searchPanelBackgroundColor
                radius: 3

                anchors {
                    bottom: parent.bottom
                    bottomMargin: 2
                    left: parent.left
                    right: parent.right
                    leftMargin: 2
                    rightMargin: 2
                }
                opacity: 0
            }
        }

        ColumnLayout {
			id: leftSidebar
			anchors {
				top: parent.top
				left: parent.left
				topMargin: 5 + Kirigami.Units.mediumSpacing
				leftMargin: 1 + Kirigami.Units.mediumSpacing
			}
			z: 3
			width: root.cellWidth
			spacing: 0
		/* 
		 *  Displays bookmarked/favorite applications and is displayed at the top of the start menu.
		 *  The source code is taken directly from Kickoff without additional changes.
		 */
        FavoritesView {
            id: faves
            Layout.fillWidth: true
            Layout.preferredHeight: faves.height
            opacity: !showingAllPrograms && !searching
            Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}

        }
		/* 
			This is the separator between favorite applications and recently used applications.
		*/
        Rectangle {
       		id: tabBarSeparator
			Layout.leftMargin: 11
			Layout.rightMargin: 7
			Layout.topMargin: 2
			Layout.fillWidth: true
       		Layout.preferredHeight: 1
       		color: leftPanelSeparatorColor
       		opacity: Plasmoid.configuration.numberRows && faves.count && (!showingAllPrograms && !searching)
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}
        }
		/*
			This is the view showing recently used applications. As soon as a program is executed and has a start menu
			entry (appears in KMenuEdit), it will be pushed at the beginning of the list. The source code is forked from
			Kickoff, featuring very minor changes. 
		*/
        OftenUsedView {
            id: recents
			Layout.topMargin: 2 * (faves.count > 0 ? 1 : -1)
			Layout.preferredHeight: recents.height
			Layout.fillHeight: true
			Layout.fillWidth: true
            opacity: Plasmoid.configuration.numberRows && (!showingAllPrograms && !searching)
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}
        }
		}
		ColumnLayout {
			id: bottomControls
			anchors {
				left: parent.left
				leftMargin: 1 + Kirigami.Units.mediumSpacing
				bottom: parent.bottom
				bottomMargin: Kirigami.Units.smallSpacing-1

			}
			spacing: 0
			width: root.cellWidth
			z: 4
			/*
			 * Another separator between the button to show all programs and recently used applications
			 */
			Rectangle {
				id: allProgramsSeparator

				Layout.topMargin: 2
				Layout.leftMargin: 13
				Layout.rightMargin: Kirigami.Units.largeSpacing+1
				Layout.fillWidth: true
				Layout.preferredHeight: 1
				opacity: !searching
				color: leftPanelSeparatorColor
				Behavior on opacity {
					NumberAnimation { easing.type: Easing.Linear; duration: animationDuration }
				}
			}
			/*
			 * Shows/hides the main view of the panel. Clicking on it in the default state will show the
			 * application menu. If the start menu is showing the application menu element or is in a searching
			 * state, clicking on this button will bring the start menu back to its default state.
			 */
			MouseArea {
				id: allButtonsArea
				hoverEnabled: true

				property alias textLabel: showingAllProgramsText.text
				property alias svgArrow: arrowDirection.elementId

				Behavior on opacity {
					NumberAnimation { easing.type: Easing.Linear; duration: animationDuration }
				}
				opacity: !searching
				CrossFadeBehavior on textLabel {
					fadeDuration: Plasmoid.configuration.enableAnimations ? 200 : 0
					easingType: "Linear"
				}
				CrossFadeBehavior on svgArrow {
					fadeDuration: Plasmoid.configuration.enableAnimations ? 200 : 0
					easingType: "Linear"
				}
				Layout.fillWidth: true
				Layout.leftMargin: Kirigami.Units.smallSpacing
				Layout.rightMargin: Kirigami.Units.smallSpacing
				Layout.topMargin: 3

				KeyNavigation.tab: searchField;
				KeyNavigation.backtab: returnPreviousView();
				function returnPreviousView() {
					if(searching) {
						return searchView.itemGrid;
					} else if(showingAllPrograms) {
						return appsView;
					} else if(Plasmoid.configuration.numberRows) {
						return recents;
					} else {
						return faves;
					}
				}
				Keys.onPressed: event => {
					if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
						click(true);
					} else if(event.key == Qt.Key_Up) {
						var view = returnPreviousView();
						view.focus = true;
						if(typeof view.currentIndex !== "undefined") {
							view.currentIndex = returnPreviousView().count-1;
						}
					} else if(event.key == Qt.Key_Down) {
						searchField.focus = true;
					}
				}
				onClicked: {
					click(false);
				}
				function click(focusAppsView) {
					if(searching)
					{
						searchField.text = "";
					}
					else if(showingAllPrograms)
					{
						showingAllPrograms = false;
						appsView.reset();
					}
					else if(!searching && !showingAllPrograms)
					{
						showingAllPrograms = true;
						if(focusAppsView) appsView.focus = true;
					}
				}
				Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium+1

				KSvg.FrameSvgItem {
					id: allProgramsButton
					anchors.fill: parent
					imagePath: Qt.resolvedUrl("svgs/menuitem.svg")

					prefix: "hover"
					opacity: {
						if(allButtonsArea.containsMouse) return 1.0;
						else if(allButtonsArea.focus) return 0.5;
						else return 0;
					}
				}
				KSvg.SvgItem {
					id: arrowDirection
					svg: arrowsSvg
					elementId: (showingAllPrograms) ? "all-applications-left" : "all-applications-right"

					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: -1
					anchors.leftMargin: Kirigami.Units.smallSpacing

					width: Kirigami.Units.iconSizes.small
					height: Kirigami.Units.iconSizes.small
				}
				Text {
					id: showingAllProgramsText
					text: showingAllPrograms ? "    Back" : "    All Programs"
					font.pixelSize: 12
					font.bold: true
					anchors.left: arrowDirection.right
					anchors.leftMargin: Kirigami.Units.mediumSpacing
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: -1
					style: Text.Sunken
					styleColor: "transparent"
				}
			}
			PlasmaExtras.ActionTextField {
				id: searchField

				focus: true
				Layout.topMargin: Kirigami.Units.mediumSpacing + Kirigami.Units.smallSpacing
				Layout.bottomMargin: Kirigami.Units.mediumSpacing-1
				Layout.leftMargin: Kirigami.Units.smallSpacing + 2
				Layout.alignment: Qt.AlignHCenter
				Layout.fillWidth: true
				Layout.preferredHeight: Kirigami.Units.smallSpacing * 7 - Kirigami.Units.smallSpacing

				background: null

				KSvg.FrameSvgItem {
					anchors.fill: parent
					anchors.leftMargin: -Kirigami.Units.smallSpacing - 2
					imagePath: Qt.resolvedUrl("svgs/lineedit.svg")
					prefix: "base"

					Text {
						anchors.fill: parent
						anchors.leftMargin: Kirigami.Units.smallSpacing*2-1
						anchors.bottomMargin: 2
						font.italic: true
						color: searchFieldPlaceholderColor
						text: i18n("Start search")
						verticalAlignment: Text.AlignVCenter
						visible: !searching
						style: Text.Outline
						styleColor: "transparent"
						opacity: 0.55
					}
					Kirigami.Icon {
						source: "gtk-search"
						smooth: true
						visible: !searching
						width: Kirigami.Units.iconSizes.small;
						height: width
						anchors {
							top: parent.top
							bottom: parent.bottom
							bottomMargin: 1
							right: parent.right
							rightMargin: Kirigami.Units.smallSpacing+1
						}
					}

					z: -1
				}

				inputMethodHints: Qt.ImhNoPredictiveText
				clearButtonShown: false
				text: ""
				color: "black"
				verticalAlignment: TextInput.AlignVCenter
				leftInset: Kirigami.Units.smallSpacing*2
				bottomInset: leftInset
				clip: false

				onTextChanged: {
					searchView.onQueryChanged();
				}

				KeyNavigation.tab: {
					if(columnItems.visibleChildren.length === 2) return shutdown;
					return columnItems.visibleChildren[0];
				}
				Keys.priority: Keys.AfterItem
				Keys.onPressed: function(event){
					if (event.key == Qt.Key_Escape) {
						event.accepted = true;
						if (searching) {
							root.reset();
						} else if(showingAllPrograms) {
							showingAllPrograms = false;
							appsView.reset();
						} else {
							root.visible = false;
						}
						focus = true;
						return;
					}
					if (event.key == Qt.Key_Tab) {
						faves.forceActiveFocus();
						event.accepted = true;
						return;
					}
					if ((event.key == Qt.Key_Up) && searching) {
						searchView.decrementCurrentIndex();
						event.accepted = true;
						return;
					}
					if ((event.key == Qt.Key_Down) && searching) {
						searchView.incrementCurrentIndex();
						event.accepted = true;
						return;
					}
					if((event.key == Qt.Key_Return) && searching) {
						searchView.activateCurrentIndex();
						event.accepted = true;
						return;
					}
					event.accepted = false;
				}

				function backspace() {
					if (!root.visible) {
						return;
					}
					focus = true;
					text = text.slice(0, -1);
				}

				function appendText(newText) {
					if (!root.visible) {
						return;
					}
					focus = true;
					text = text + newText;
				}
			}

		}

        states: [

            State {
                name: "AllPrograms"; when: !searching && showingAllPrograms
                StateChangeScript {
                    script: appsView.resetIndex();
                }
            },
            State {
                name: "Searching"; when: searching

                PropertyChanges {
					target: searchView; opacity: (backgroundRect.width === searchView.width ? 1 : 0);
				}
				PropertyChanges {
					target: searchViewBottom; opacity: (backgroundRect.width === searchView.width ? 1 : 0);
				}
                PropertyChanges {
					target: searchBackground; anchors.rightMargin: 3
				}
				PropertyChanges {
					target: backgroundBorderLine; anchors.rightMargin: 3
				}
                PropertyChanges {
                    target: faves; opacity: 0;
                }
                PropertyChanges {
                    target: recents; opacity: 0;
                }
                PropertyChanges {
                    target: tabBarSeparator; opacity: 0;
                }
                PropertyChanges {
                    target: allProgramsButton; opacity: 0;
                }
                PropertyChanges {
					target: allProgramsButton; enabled: false;
				}
                PropertyChanges {
                    target: allProgramsSeparator; opacity: 0;
                }
                PropertyChanges {
                    target: allButtonsArea; opacity: 0;
                }
                PropertyChanges {
					target: allButtonsArea; enabled: false;
				}
		}
        ]
        transitions: [
       		Transition {
				id: transition
       		    PropertyAnimation { properties: "opacity"; easing.type: Easing.Linear; duration: animationDuration }
       		    onRunningChanged: {
					if(!searching && !running) {
						// fixes another inexplicable bug, makes it look just a tad bit nicer
						backgroundBorderLine.anchors.rightMargin = Qt.binding(() => 2);
						searchBackground.anchors.rightMargin = Qt.binding(() => 2);
					}
				}
       		}
        ]

        /*
		 * Shows a list of all applications organized by categories. The source code is forked from Kickoff
		 * and features mostly aesthetic changes.
		 */
		ApplicationsView {
			id: appsView

			anchors {
				top: leftSidebar.top
				left: leftSidebar.left
				right: leftSidebar.right
				bottom: bottomControls.top
				topMargin: -Kirigami.Units.smallSpacing-2
			}

			opacity: showingAllPrograms && !searching
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}

			function resetIndex() {
				appsView.listView.currentIndex = -1;
			}

			z: showingAllPrograms ? 4 : 1
		}

		/*
		 * Shows search results when the user types something into the textbox. This view will only
		 * appear if that textbox is not empty, and it will extend the left panel to the entire
		 * width of the plasmoid. The source code is forked from Kickoff and features aesthetic
		 * changes.
		 */
		SearchView {
			id: searchView

			clip: true
			anchors {
				top: backgroundRect.top
				left: parent.left
				right: sidePanel.left
				bottom: backgroundRect.bottom

				topMargin: Kirigami.Units.smallSpacing*2 -2
				bottomMargin: searchBackground.height + Kirigami.Units.smallSpacing/2
				leftMargin: 2 + Kirigami.Units.mediumSpacing
				rightMargin: Kirigami.Units.mediumSpacing - 2
			}

			opacity: 0
			visible: opacity
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.InOutQuart; duration: animationDuration }
			}

			z: searching ? 4 : 1
		}
		ColumnLayout {
			id: searchViewBottom

			opacity: 0
			visible: opacity
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.InOutQuart; duration: 150 }
			}

			anchors {
				right: searchView.right
				left: searchView.left
				bottom: backgroundRect.bottom

				rightMargin: Kirigami.Units.mediumSpacing - 1
				leftMargin: -Kirigami.Units.smallSpacing - 1
				bottomMargin: Kirigami.Units.smallSpacing
			}

			spacing: 0

			EvenGenericItem {
				text: i18n("Search Everywhere")
				icon: "edit-find"
				Layout.fillWidth: true
			}
			EvenGenericItem {
				text: i18n("Search the Internet")
				icon: "edit-find"
				Layout.fillWidth: true
			}

			z: searching ? 4 : 1
		}


        Column {
            id: sidePanel
            z: 7

            anchors{
                left: leftSidebar.right
                top: parent.top
                bottom: bottomControls.top
                leftMargin: 5
                topMargin: ((compositingEnabled && Plasmoid.location !== PlasmaCore.Types.TopEdge) ? Kirigami.Units.iconSizes.huge / 2 + Kirigami.Units.smallSpacing : 0) + Kirigami.Units.mediumSpacing

			}
			spacing: Kirigami.Units.smallSpacing

			FloatingIcon {
				id: nonCompositingIcon
				Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
				visible: !compositingEnabled || Plasmoid.location === PlasmaCore.Types.TopEdge
			}
            FileDialog {
                id: folderDialog
                visible: false
                currentFolder: ""

                function getPath(val){
					switch(val) {
						case 1:
							return StandardPaths.writableLocation(StandardPaths.HomeLocation);
						case 2:
							return StandardPaths.writableLocation(StandardPaths.DocumentsLocation);
						case 3:
							return StandardPaths.writableLocation(StandardPaths.PicturesLocation);
						case 4:
							return StandardPaths.writableLocation(StandardPaths.MusicLocation);
						case 5:
							return StandardPaths.writableLocation(StandardPaths.MoviesLocation);
						case 6:
							return StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Downloads";
						case 7:
							return "file:///.";
						case 8:
							return "remote:/";
						case 9:
							return "applications:///Games/";
						case 10:
							return "https://develop.kde.org/docs/"
						case 11:
							return "recentlyused:/";
						default:
							return "";
					}
                }
            }
			Timer {
				id: delayTimer
				interval: 250
				repeat: false
				onTriggered: {
					if(root.activeFocusItem) {
						if(root.activeFocusItem.objectName === "SidePanelItemDelegate") {
							compositingIcon.iconSource = root.activeFocusItem.itemIcon;
							nonCompositingIcon.iconSource = root.activeFocusItem.itemIcon;
						} else {
							compositingIcon.iconSource = "";
							nonCompositingIcon.iconSource = "";
						}
					}
				}
			}

			//Side panel items
            ColumnLayout {
                id: columnItems
                spacing: 2
				Layout.alignment: Qt.AlignTop
				width: Math.max(cellWidthSide, columnItems.implicitWidth)

				property int currentIndex: -1
                Component.onCompleted: {
					separator1.updateVisibility();
					separator2.updateVisibility();
				}
				SidePanelItemDelegate {
					itemText: Plasmoid.configuration.useFullName ? kuser.fullName : kuser.loginName
					itemIcon: "user-home"
					executableString: folderDialog.getPath(1)
					visible: Plasmoid.configuration.showHomeSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Documents")
					itemIcon: "folder-documents"
					executableString: folderDialog.getPath(2)
					visible: Plasmoid.configuration.showDocumentsSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Pictures")
					itemIcon: "folder-pictures"
					executableString: folderDialog.getPath(3)
					visible: Plasmoid.configuration.showPicturesSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Music")
					itemIcon: "folder-music"
					executableString: folderDialog.getPath(4)
					visible: Plasmoid.configuration.showMusicSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Videos")
					itemIcon: "folder-video"
					executableString: folderDialog.getPath(5)
					visible: Plasmoid.configuration.showVideosSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Downloads")
					itemIcon: "folder-download"
					executableString: folderDialog.getPath(6)
					visible: Plasmoid.configuration.showDownloadsSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Games")
					itemIcon: "applications-games"
					executableString: folderDialog.getPath(9)
					visible: Plasmoid.configuration.showGamesSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemSeparator {
					id: separator1
					Layout.minimumWidth: 124
					Layout.maximumWidth: 124
					Layout.alignment: Qt.AlignHCenter
				}
				SidePanelItemDelegate {
					id: recentsItem
					itemText: i18n("Recent Items")
					itemIcon: "document-open-recent"
					visible: Plasmoid.configuration.showRecentItemsSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
					KSvg.SvgItem {
						anchors.right: parent.right
						anchors.rightMargin: Kirigami.Units.smallSpacing*2
						anchors.verticalCenter: parent.verticalCenter

						implicitWidth: 6
						implicitHeight: 10

						imagePath: Qt.resolvedUrl("svgs/arrows.svgz")
						elementId: "group-expander-left"
					}
				}
				SidePanelItemDelegate {
					itemText: i18n("Computer")
					itemIcon: "computer"
					executableString: folderDialog.getPath(7)
					visible: Plasmoid.configuration.showRootSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Network")
					itemIcon: "network"
					executableString: folderDialog.getPath(8)
					visible: Plasmoid.configuration.showNetworkSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Connect To")
					itemIcon: "connectto"
					executableString: folderDialog.getPath(8)
					visible: Plasmoid.configuration.showConnectToSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemSeparator {
					id: separator2
					Layout.minimumWidth: 124
					Layout.maximumWidth: 124
					Layout.alignment: Qt.AlignHCenter
				}
				SidePanelItemDelegate {
					itemText: i18n("Control Panel")
					itemIcon: "preferences-system"
					executableString: "systemsettings"
					executeProgram: true
					visible: Plasmoid.configuration.showSettingsSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Devices and Printers")
					itemIcon: "input_devices_settings"
					executableString: "systemsettings kcm_printer_manager"
					executeProgram: true
					visible: Plasmoid.configuration.showDevicesSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Default Programs")
					itemIcon: "preferences-desktop-default-applications"
					executableString: "systemsettings kcm_componentchooser"
					executeProgram: true
					visible: Plasmoid.configuration.showDefaultsSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Help and Support")
					itemIcon: "help-browser"
					executableString: folderDialog.getPath(10);
					visible: Plasmoid.configuration.showHelpSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}
				SidePanelItemDelegate {
					itemText: i18n("Run...")
					itemIcon: "krunner"
					executableString: "krunner --replace";
					executeProgram: true
					visible: Plasmoid.configuration.showRunSidepanel
					onVisibleChanged: {
						separator1.updateVisibility();
						separator2.updateVisibility();
					}
					Layout.fillWidth: true
				}

				//Used to space out the rest of the side panel, so that the shutdown button is at the bottom of the plasmoid
                Item {
                    Layout.minimumWidth: cellWidthSide
                    Layout.fillWidth: true
                    height: 1
                    visible: true
                }
            }
        }
        
        RowLayout {
			id: leaveButtons
			anchors{
				bottom: bottomControls.bottom
				bottomMargin: Kirigami.Units.smallSpacing+1
				left: bottomControls.right
				leftMargin: 6
			}
			spacing: 0
			z: 7
			function findUpItem() {
				if(searching) {
					return allButtonsArea;
				} else {
					if(columnItems.visibleChildren.length === 2) {
						return searchField;
					}
					return columnItems.visibleChildren[columnItems.visibleChildren.length-2];
				}
			}
			ListDelegate {
				id: shutdown
				objectName: "ShutdownButton"
				width: 54
				height: Kirigami.Units.smallSpacing * 6
				size: iconSizeSide

				KeyNavigation.tab: lock
				KeyNavigation.backtab: leaveButtons.findUpItem();

				Keys.onPressed: event => {
					if(event.key == Qt.Key_Return) {
						ma.clicked(null);
					} else if(event.key == Qt.Key_Right) {
						lockScreenDelegate.focus = true;
					} else if(event.key == Qt.Key_Left) {
						searchField.focus = true;
					} else if(event.key == Qt.Key_Up) {
						leaveButtons.findUpItem().focus = true;
					}
				}

                KSvg.FrameSvgItem {
					id: shutdownButton

					anchors.fill:parent
					anchors.left: parent.left
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					prefix: {
						if(!Plasmoid.configuration.disableSleep) {
							if(ma.containsPress) return "sleep-pressed";
							else if(ma.containsMouse) return "sleep-hover";
							else return "sleep";
						}
						else {
							if(ma.containsPress) return "shutdown-pressed";
							else if(ma.containsMouse) return "shutdown-hover";
							else return "shutdown";
						}
					}
				}

				KSvg.SvgItem {
					id: lsSvg1
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					anchors.centerIn: shutdownButton
					anchors.horizontalCenterOffset: ma.containsPress ? 1 : 0
					anchors.verticalCenterOffset: ma.containsPress ? 1 : 0
					width: 16
					height: 17
					elementId: Plasmoid.configuration.disableSleep ? "shutdown" : "sleep"
					z: 1
				}

				MouseArea {
					id: ma

					enabled: !root.hoverDisabled
					acceptedButtons: Qt.LeftButton
					hoverEnabled: true
					anchors.fill: parent
					onExited: {
						shutdown.focus = false;
					}
					onClicked: {
						root.visible = false;
						pmEngine.performOperation(Plasmoid.configuration.disableSleep ? "requestShutDown" : "suspend");
					}
				}
			}

			ListDelegate {
				id: lock
				objectName: "ShutdownButton"
				width: 53
				height: Kirigami.Units.smallSpacing * 6
				size: iconSizeSide

				KeyNavigation.tab: lockScreenDelegate
				KeyNavigation.backtab: leaveButtons.findUpItem();

				Keys.onPressed: event => {
					if(event.key == Qt.Key_Return) {
						ma.clicked(null);
					} else if(event.key == Qt.Key_Right) {
						lockScreenDelegate.focus = true;
					} else if(event.key == Qt.Key_Left) {
						searchField.focus = true;
					} else if(event.key == Qt.Key_Up) {
						leaveButtons.findUpItem().focus = true;
					}
				}

				KSvg.FrameSvgItem {
					id: trueLockButton

					anchors.fill: parent
					anchors.left: parent.left
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					prefix: {
						if(trueLockma.containsPress) return "lock-pressed";
						else if(trueLockma.containsMouse) return "lock-hover";
						else return "lock";
					}
				}

				KSvg.SvgItem {
					id: lsSvg2
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					anchors.centerIn: trueLockButton
					anchors.horizontalCenterOffset: trueLockma.containsPress ? 1 : 0
					anchors.verticalCenterOffset: trueLockma.containsPress ? 1 : 0
					width: 15
					height: 16
					elementId: "lock"
				}

				MouseArea {
					id: trueLockma

					enabled: !root.hoverDisabled
					acceptedButtons: Qt.LeftButton
					hoverEnabled: true
					anchors.fill: parent
					onExited: {
						lock.focus = false;
					}
					onClicked: {
						root.visible = false;
						pmEngine.performOperation("lockScreen");
					}
				}
			}

			ListDelegate {
				id: lockScreenDelegate
				width: height
				height: shutdown.height 
				KeyNavigation.tab: faves
				KeyNavigation.backtab: shutdown

				Keys.onPressed: event => {
					if(event.key == Qt.Key_Return) {
						lockma.clicked(null);
					} else if(event.key == Qt.Key_Left) {
						shutdown.focus = true;
					} else if(event.key == Qt.Key_Up) {
						leaveButtons.findUpItem().focus = true;
					}
				}
                KSvg.FrameSvgItem {
					id: lockButton

					anchors.fill: parent
					anchors.left: parent.left
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					prefix: {
						if(contextMenu.status == 1 || lockma.containsPress) return "more-pressed";
						else if(lockma.containsMouse) return "more-hover";
						else return "more";
					}
				}
				onFocusChanged: {
					if(lockScreenDelegate.focus)
						contextMenu.openRelative();
				}
				MouseArea {
					id: lockma
					enabled: !root.hoverDisabled
					acceptedButtons: Qt.LeftButton
					onClicked: {
						contextMenu.openRelative();
					}
					hoverEnabled: true
					anchors.fill: lockButton
				}

                KSvg.SvgItem {
					id: lsSvg
					svg: arrowsSvg

					anchors.centerIn: lockButton
					anchors.horizontalCenterOffset: -1
					width: Kirigami.Units.iconSizes.smallMedium - Kirigami.Units.smallSpacing / 2
					height: Kirigami.Units.iconSizes.smallMedium - Kirigami.Units.smallSpacing / 2 +1
					elementId: "more-ltr-light";
				}
				enabled: pmEngine.data["Sleep States"]["LockScreen"]
				size: iconSizeSide
			}
		}
		
		KeyNavigation.tab: faves;
		Keys.forwardTo: searchField
	}

	Component.onCompleted: {
		kicker.reset.connect(reset);
		reset();
		faves.listView.currentIndex = -1;
		
		popupPosition();
		Plasmoid.setDialogAppearance(root, dialogBackground.mask);
	}
}
