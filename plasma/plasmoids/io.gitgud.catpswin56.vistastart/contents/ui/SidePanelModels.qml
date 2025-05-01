
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons // kuser
import org.kde.kitemmodels as KItemModels


Item {
    id: models
    KCoreAddons.KUser {   id: kuser  }  // Used for getting the username and icon.
    Kicker.RecentUsageModel {
        id: fileUsageModel
        ordering: 0
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }

    property var firstCategory:
    [
        {
            name: "Home directory",
            itemText: Plasmoid.configuration.useFullName ? kuser.fullName : kuser.loginName,
            itemIcon: "user-home",
            itemIconFallback: "unknown",
            executableString: StandardPaths.writableLocation(StandardPaths.HomeLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Documents",
            itemText: i18n("Documents"),
            itemIcon: "folder-documents",
            itemIconFallback: "folder-documents",
            executableString: StandardPaths.writableLocation(StandardPaths.DocumentsLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Pictures",
            itemText: i18n("Pictures"),
            itemIcon: "folder-image",
            itemIconFallback: "folder-image",
            executableString: StandardPaths.writableLocation(StandardPaths.PicturesLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Music",
            itemText: i18n("Music"),
            itemIcon: "folder-music",
            itemIconFallback: "folder-music",
            executableString: StandardPaths.writableLocation(StandardPaths.MusicLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Videos",
            itemText: i18n("Videos"),
            itemIcon: "folder-videos",
            itemIconFallback: "folder-videos",
            executableString: StandardPaths.writableLocation(StandardPaths.MoviesLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Downloads",
            itemText: i18n("Downloads"),
            itemIcon: "folder-download",
            itemIconFallback: "folder-download",
            executableString: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Downloads",
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Games",
            itemText: i18n("Games"),
            itemIcon: "applications-games",
            itemIconFallback: "folder-games",
            executableString: "applications:///Games/",
            menuModel: null,
            executeProgram: false
        },

    ]
    property var secondCategory:
    [
        {
            name: "Recent Items",
            itemText: i18n("Recent Items"),
            itemIcon: "document-open-recent",
            itemIconFallback: "folder-documents",
            executableString: "recentlyused:/",
            menuModel: fileUsageModel,
            executeProgram: false
        },
        {
            name: "Computer",
            itemText: i18n("Computer"),
            itemIcon: "computer",
            itemIconFallback: "unknown",
            executableString: "file:///.",
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Network",
            itemText: i18n("Network"),
            itemIcon: "folder-network",
            itemIconFallback: "network-server",
            executableString: "remote:/",
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Connect To",
            itemText: i18n("Connect To"),
            itemIcon: "connectto",
            itemIconFallback: "network-server",
            executableString: "remote:/",
            menuModel: null,
            executeProgram: false
        }
    ]
    property var thirdCategory:
    [
        {
            name: "Control Panel",
			itemText: i18n("Control Panel"),
			itemIcon: "preferences-system",
			itemIconFallback: "preferences-desktop",
			executableString: "systemsettings",
			executeProgram: true,
            menuModel: null,
        },
        {
            name: "Devices and Printers",
			itemText: i18n("Devices and Printers"),
			itemIcon: "input_devices_settings",
			itemIconFallback: "printer",
			executableString: "systemsettings kcm_printer_manager",
			executeProgram: true,
            menuModel: null,
        },
        {
            name: "Default Programs",
			itemText: i18n("Default Programs"),
			itemIcon: "preferences-desktop-default-applications",
			itemIconFallback: "application-x-executable",
			executableString: "systemsettings kcm_componentchooser",
			executeProgram: true,
            menuModel: null,
        },
        {
            name: "Help and Support",
			itemText: i18n("Help and Support"),
			itemIcon: "help-browser",
			itemIconFallback: "system-help",
			executableString: "https://develop.kde.org/docs/",
			executeProgram: false,
            menuModel: null,
        },
        {
            name: "Run",
			itemText: i18n("Run..."),
			itemIcon: "krunner",
			itemIconFallback: "system-run",
			executableString: "krunner --replace",
			executeProgram: true,
            menuModel: null,
        },
        /*{
            name: "Donate",
			itemText: "Donate",
			itemIcon: "favorites",
			itemIconFallback: "emblem-favorite",
			executableString: "https://ko-fi.com/M4M2NJ9PJ",
			executeProgram: false,
            menuModel: null,
        },*/
    ]

}
