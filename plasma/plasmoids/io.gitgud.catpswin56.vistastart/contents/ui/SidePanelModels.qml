import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons as KCoreAddons // kuser
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
            description: i18n("Opens your home folder, where you can find folders for Documents, Pictures, Music, and other files that belong to you."),
            itemIcon: "user-home",
            itemIconFallback: "unknown",
            executableString: StandardPaths.writableLocation(StandardPaths.HomeLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Documents",
            itemText: i18n("Documents"),
            description: i18n("Store letters, reports, notes and other kinds of documents."),
            itemIcon: "folder-documents",
            itemIconFallback: "folder-documents",
            executableString: StandardPaths.writableLocation(StandardPaths.DocumentsLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Pictures",
            itemText: i18n("Pictures"),
            description: i18n("Store pictures and other graphic files."),
            itemIcon: "folder-image",
            itemIconFallback: "folder-image",
            executableString: StandardPaths.writableLocation(StandardPaths.PicturesLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Music",
            itemText: i18n("Music"),
            description: i18n("Store and play music and other audio files."),
            itemIcon: "folder-music",
            itemIconFallback: "folder-music",
            executableString: StandardPaths.writableLocation(StandardPaths.MusicLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Videos",
            itemText: i18n("Videos"),
            description: i18n("Watch home movies and other digital videos."),
            itemIcon: "folder-videos",
            itemIconFallback: "folder-videos",
            executableString: StandardPaths.writableLocation(StandardPaths.MoviesLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Downloads",
            itemText: i18n("Downloads"),
            description: i18n("Find Internet downloads and links to favorite websites."),
            itemIcon: "folder-download",
            itemIconFallback: "folder-download",
            executableString: StandardPaths.writableLocation(StandardPaths.DownloadLocation),
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Games",
            itemText: i18n("Games"),
            description: i18n("Play and manage games on your computer."),
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
            description: "",
            itemIcon: "document-open-recent",
            itemIconFallback: "folder-documents",
            executableString: "recentlyused:/",
            menuModel: fileUsageModel,
            executeProgram: false
        },
        {
            name: "Computer",
            itemText: i18n("Computer"),
            description: i18n("See the disk drives and other hardware connected to your computer."),
            itemIcon: "computer",
            itemIconFallback: "unknown",
            executableString: "file:///.",
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Network",
            itemText: i18n("Network"),
            description: i18n("Provides access to the computers and devices that are on your network."),
            itemIcon: "folder-network",
            itemIconFallback: "network-server",
            executableString: "remote:/",
            menuModel: null,
            executeProgram: false
        },
        {
            name: "Connect To",
            itemText: i18n("Connect To"),
            description: i18n("See the available wireless networks, dial-up, and VPN connections that you can connect to."),
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
			description: i18n("Customize the appearance and functionality of your computer, add or remove programs, and set up network connections and user accounts."),
			itemIcon: "preferences-system",
			itemIconFallback: "preferences-desktop",
			executableString: "systemsettings",
			executeProgram: true,
            menuModel: null,
        },
        {
            name: "Default Programs",
			itemText: i18n("Default Programs"),
			description: i18n("Choose default programs for web browsing, e-mail, playing music, and other activities."),
			itemIcon: "preferences-desktop-default-applications",
			itemIconFallback: "application-x-executable",
			executableString: "systemsettings kcm_componentchooser",
			executeProgram: true,
            menuModel: null,
        },
        {
            name: "Printers",
            itemText: i18n("Printers"),
            description: i18n("See installed printers and add new ones."),
            itemIcon: "input_devices_settings",
            itemIconFallback: "printer",
            executableString: "systemsettings kcm_printer_manager",
            executeProgram: true,
            menuModel: null,
        },
        {
            name: "Help and Support",
			itemText: i18n("Help and Support"),
			description: i18n("Find Help topics, tutorials, troubleshooting, and other support services."),
			itemIcon: "help-browser",
			itemIconFallback: "system-help",
			executableString: "https://develop.kde.org/docs/",
			executeProgram: false,
            menuModel: null,
        },
        {
            name: "Run",
			itemText: i18n("Run..."),
			description: i18n("Opens a program, folder, document, or web site."),
			itemIcon: "krunner",
			itemIconFallback: "system-run",
			executableString: Plasmoid.configuration.defaultRunnerApp,
			executeProgram: true,
            menuModel: null,
        }
    ]

}
