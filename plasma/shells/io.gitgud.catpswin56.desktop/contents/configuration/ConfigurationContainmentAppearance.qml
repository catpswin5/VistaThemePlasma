/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import org.kde.plasma.configuration 2.0
import QtQuick.Controls 2.3 as QQC2
import QtQuick.Layouts
import QtQml 2.15

import org.kde.newstuff 1.62 as NewStuff
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.configuration 2.0
import org.kde.plasma.plasma5support as Plasma5Support


Item {
    id: appearanceRoot
    signal configurationChanged

    property int formAlignment: wallpaperComboBox.Kirigami.ScenePosition.x - appearanceRoot.Kirigami.ScenePosition.x + Kirigami.Units.smallSpacing
    property string currentWallpaper: ""
    property string containmentPlugin: ""
    property alias parentLayout: parentLayout

    Plasma5Support.DataSource {
        id: menu_executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(sourceName, exitCode, exitStatus, stdout, stderr)
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            if (cmd) {
                connectSource(cmd)
            }
        }
        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }


    function saveConfig() {
        if (main.currentItem.saveConfig) {
            main.currentItem.saveConfig()
        }
        configDialog.currentWallpaper = appearanceRoot.currentWallpaper;
        for (var key in configDialog.wallpaperConfiguration) {
            if (main.currentItem["cfg_"+key] !== undefined) {
                configDialog.wallpaperConfiguration[key] = main.currentItem["cfg_"+key]
            }
        }
        configDialog.applyWallpaper()
        configDialog.containmentPlugin = appearanceRoot.containmentPlugin
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0 // unless it's 0 there will be an additional gap between two FormLayouts

        Component.onCompleted: {
            for (var i = 0; i < configDialog.containmentPluginsConfigModel.count; ++i) {
                var pluginName = configDialog.containmentPluginsConfigModel.data(configDialog.containmentPluginsConfigModel.index(i, 0), ConfigModel.PluginNameRole);
                if (configDialog.containmentPlugin === pluginName) {
                    pluginComboBox.currentIndex = i
                    pluginComboBox.activated(i);
                    break;
                }
            }

            for (var i = 0; i < configDialog.wallpaperConfigModel.count; ++i) {
                var pluginName = configDialog.wallpaperConfigModel.data(configDialog.wallpaperConfigModel.index(i, 0), ConfigModel.PluginNameRole);
                if (configDialog.currentWallpaper === pluginName) {
                    wallpaperComboBox.currentIndex = i
                    wallpaperComboBox.activated(i);
                    break;
                }
            }
        }

        Kirigami.InlineMessage {
            visible: Plasmoid.immutable || animating
            text: i18nd("plasma_shell_org.kde.plasma.desktop", "Layout changes have been restricted by the system administrator")
            showCloseButton: true
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing * 2 // we need this because ColumnLayout's spacing is 0
        }

        Flow {
            Layout.topMargin: Kirigami.Units.smallSpacing*3
            Layout.bottomMargin: Kirigami.Units.smallSpacing*3
            Layout.leftMargin: Kirigami.Units.smallSpacing*3
            Layout.rightMargin: Kirigami.Units.smallSpacing*3
            Layout.fillWidth: true
            Layout.maximumHeight: 100

            spacing: 16
            flow: Flow.TopToBottom

            RowLayout {
                id: layouttt
                width: appearanceRoot.width/2

                spacing: 8

                function execute() {
                    pluginComboBox.popup.visible = !pluginComboBox.popup.visible;
                }

                Kirigami.Icon {
                    id: layoutIcon
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignTop
                    source: "shell-desktop-layout"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: layouttt.execute();
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                ColumnLayout {
                    width: parent.width
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        id: layoutText
                        color: Kirigami.Theme.linkColor
                        font.underline: layoutMA.containsMouse
                        text: i18nd("plasma_shell_org.kde.plasma.desktop", "Layout:") + " " + pluginComboBox.displayText
                        MouseArea {
                            id: layoutMA
                            anchors.fill: parent
                            onClicked: layouttt.execute();
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.rightMargin: layoutIcon.width
                        text: "Change the layout of your desktop"
                        wrapMode: Text.WordWrap
                    }
                    QQC2.ComboBox {
                        id: pluginComboBox
                        background: Item {}
                        contentItem: Item { implicitWidth: layoutText.width; implicitHeight: layoutText.height-Kirigami.Units.mediumSpacing }
                        enabled: !Plasmoid.immutable
                        model: configDialog.containmentPluginsConfigModel
                        textRole: "name"
                        onActivated: {
                            var model = configDialog.containmentPluginsConfigModel.get(currentIndex)
                            appearanceRoot.containmentPlugin = model.pluginName
                            appearanceRoot.configurationChanged()
                        }
                        visible: false
                    }
                }
            }

            FooterItem {
                width: appearanceRoot.width/2
                bottomMargin: pluginComboBox.height + parent.spacing
                iconSource: "shell-aero-color"
                text: "Window Color"
                description: "Fine tune the color of your windows"
                command: "kstart aerothemeplasma-kcmloader kwin/effects/configs/kwin_aeroglassblur_config.so " + iconSource
                execHelper: menu_executable
            }
            FooterItem {
                width: appearanceRoot.width/2
                bottomMargin: pluginComboBox.height + parent.spacing
                iconSource: "shell-decoration-themes"
                text: "Window Decorations"
                description: "Change the way your window frames look"
                command: "kstart aerothemeplasma-kcmloader org.kde.kdecoration3.kcm/kcm_smoddecoration.so " + iconSource
                execHelper: menu_executable
            }
            FooterItem {
                width: appearanceRoot.width/2
                bottomMargin: pluginComboBox.height + parent.spacing
                iconSource: "shell-sound-themes"
                text: "Sounds"
                description: "Change which sounds are heard"
                command: "kstart systemsettings kcm_soundtheme"
                execHelper: menu_executable
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Kirigami.FormLayout {
            id: parentLayout // needed for twinFormLayouts to work in wallpaper plugins
            twinFormLayouts: main.currentItem.formLayout || []
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                enabled: main.currentItem.objectName !== "switchContainmentWarningItem"
                Kirigami.FormData.label: i18nd("plasma_shell_org.kde.plasma.desktop", "Wallpaper type:")

                QQC2.ComboBox {
                    id: wallpaperComboBox
                    Layout.preferredWidth: Math.max(implicitWidth, pluginComboBox.implicitWidth)
                    model: configDialog.wallpaperConfigModel
                    textRole: "name"
                    onActivated: {
                        var idx = configDialog.wallpaperConfigModel.index(currentIndex, 0)
                        var pluginName = configDialog.wallpaperConfigModel.data(idx, ConfigModel.PluginNameRole)
                        if (appearanceRoot.currentWallpaper === pluginName) {
                            return;
                        }
                        appearanceRoot.currentWallpaper = pluginName
                        configDialog.currentWallpaper = pluginName
                        main.sourceFile = configDialog.wallpaperConfigModel.data(idx, ConfigModel.SourceRole)
                        appearanceRoot.configurationChanged()
                    }
                }
                NewStuff.Button {
                    id: newStuff
                    configFile: "wallpaperplugin.knsrc"
                    text: i18nd("plasma_shell_org.kde.plasma.desktop", "Get New Plugins…")
                    visibleWhenDisabled: true // don't hide on disabled
                    Layout.preferredHeight: wallpaperComboBox.height
                }
            }
        }

        Item {
            id: emptyConfig
        }

        QQC2.StackView {
            id: main

            implicitHeight: main.empty ? 0 : currentItem.implicitHeight

            Layout.fillHeight: true;
            Layout.fillWidth: true;

            // Bug 360862: if wallpaper has no config, sourceFile will be ""
            // so we wouldn't load emptyConfig and break all over the place
            // hence set it to some random value initially
            property string sourceFile: "tbd"

            onSourceFileChanged: loadSourceFile()

            function loadSourceFile() {
                const wallpaperConfig = configDialog.wallpaperConfiguration
                // BUG 407619: wallpaperConfig can be null before calling `ContainmentItem::loadWallpaper()`
                if (wallpaperConfig && sourceFile) {
                    var props = {
                        "configDialog": configDialog
                    }

                    for (var key in wallpaperConfig) {
                        props["cfg_" + key] = wallpaperConfig[key]
                    }

                    var newItem = replace(Qt.resolvedUrl(sourceFile), props)

                    for (var key in wallpaperConfig) {
                        var changedSignal = newItem["cfg_" + key + "Changed"]
                        if (changedSignal) {
                            changedSignal.connect(appearanceRoot.configurationChanged)
                        }
                    }

                    const configurationChangedSignal = newItem.configurationChanged
                    if (configurationChangedSignal) {
                        configurationChangedSignal.connect(appearanceRoot.configurationChanged)
                    }
                } else {
                    replace(emptyConfig)
                }
            }
        }
    }

    Component {
        id: switchContainmentWarning

        Item {
            objectName: "switchContainmentWarningItem"

            Kirigami.PlaceholderMessage {
                id: message
                width: parent.width - Kirigami.Units.largeSpacing * 8
                anchors.centerIn: parent

                icon.name: "documentinfo"
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Layout changes must be applied before other changes can be made")

                helpfulAction: QQC2.Action {
                    icon.name: "dialog-ok-apply"
                    text: i18nd("plasma_shell_org.kde.plasma.desktop", "Apply Now")
                    onTriggered: saveConfig()
                }
            }
        }
    }

    onContainmentPluginChanged: {
        if (configDialog.containmentPlugin !== appearanceRoot.containmentPlugin) {
            main.push(switchContainmentWarning);
            categoriesScroll.enabled = false;
        } else if (main.currentItem.objectName === "switchContainmentWarningItem") {
            main.pop();
            categoriesScroll.enabled = true;
        }
    }
}
