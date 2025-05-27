import QtQuick

import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid

QtObject {
    id: stylesModel

    property var currentStyle: styles[Plasmoid.configuration.startStyle]
    property var styles:
    [
        {
            styleName: "Vista",

            cellWidth: 254,
            cellWidthSide: 139,
            panelSpacing: Kirigami.Units.mediumSpacing*2,

            allProgramsBtn: {
                reverseLayout: false,
                centerText: false,

                padding: Kirigami.Units.largeSpacing - 1,
                spacing: Kirigami.Units.largeSpacing * 2,

                indicatorHover: false,
                indicatorWidth: 16,
                indicatorHeight: 16
            },
            leaveButtons: {
                showLabel: false,
                isFramed: true,

                spacing: 0,

                shutdownWidth: 54,
                shutdownHeight: 24,
                lockWidth: 53,
                lockHeight: 24,

                moreWidth: 24,
                moreHeight: 24
            },
            rightPanel: {
                textureVisible: false,

                topMargin: (kicker.compositingEnabled && !kicker.dashWindow.isTouchingTopEdge() ? Kirigami.Units.iconSizes.huge / 2 + Kirigami.Units.smallSpacing : 0) + (Kirigami.Units.smallSpacing - 1),
                rightMargin: 5,

                itemTextColor: "white",
                hideUserPFP: false
            },
            leftPanel: {
                textureVisible: true,

                topMargin: 5 + Kirigami.Units.mediumSpacing,
                leftMargin: 1 + Kirigami.Units.mediumSpacing,

                itemTextColor: "black",
                separatorColor: "#e2e2e2",
                separatorOpacity: 1.0
            },
            searchView: {
                sectionColor: "#003693",
                sectionSeparatorColor: "#ccd9ec",
                sectionSeparatorOpacity: 0.5,

                itemTextColor: "black",
                linksColor: "#003963"
            },
            searchBar: {
                rightMargin: 0,
                leftMargin: Kirigami.Units.smallSpacing + 2,
                rightPadding: 0,

                placeholderText: i18n("Start search..."),
                textColor: "#707070",
                inactiveTextColor: "#707070",
                bgOnlyOnFocus: false,
                icon: "gtk-search"
            }
        },

        {
            styleName: "Longhorn-like",

            cellWidth: 225,
            cellWidthSide: 200,
            panelSpacing: 2,

            allProgramsBtn: {
                reverseLayout: true,
                centerText: true,

                padding: Kirigami.Units.largeSpacing,
                spacing: 8,

                indicatorHover: true,
                indicatorWidth: 21,
                indicatorHeight: 21
            },
            leaveButtons: {
                showLabel: true,
                isFramed: false,

                spacing: 12,

                shutdownWidth: 20,
                shutdownHeight: 20,
                lockWidth: 20,
                lockHeight: 20,

                moreWidth: 16,
                moreHeight: 16
            },
            rightPanel: {
                textureVisible: true,

                topMargin: Kirigami.Units.smallSpacing+4,
                rightMargin: 6,

                itemTextColor: "black",
                hideUserPFP: true
            },
            leftPanel: {
                textureVisible: false,

                topMargin: 5,
                leftMargin: 0,

                itemTextColor: "white",
                separatorColor: "white",
                separatorOpacity: 0.2
            },
            searchView: {
                sectionColor: "#7bd0e3",
                sectionSeparatorColor: "#7bd0e3",
                sectionSeparatorOpacity: 1.0,

                itemTextColor: "white",
                linksColor: "#7bd0e3"
            },
            searchBar: {
                rightMargin: 10,
                leftMargin: 15,
                rightPadding: 36,

                placeholderText: "Search My Stuff...",
                textColor: "black",
                inactiveTextColor: "white",
                bgOnlyOnFocus: true,
                icon: "edit-find"
            }
        }
    ]
}
