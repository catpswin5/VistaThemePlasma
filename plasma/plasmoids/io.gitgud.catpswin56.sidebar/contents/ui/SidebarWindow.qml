import QtQuick

import org.kde.plasma.plasmoid

Window {
    id: window

    required property ContainmentItem root

    width: root.sidebarWidth
    height: Plasmoid.availableScreenRect.height

    title: "Windows Sidebar"
    flags: Qt.FramelessWindowHint
    color: "transparent"

    // TODO: move this to a kwin effect instead
    SequentialAnimation {
        id: slide_animation_root

        NumberAnimation {
            id: slide_animation

            target: window
            property: "y"
            duration: 125
        }
        ScriptAction { script: { window.visible = !root.sidebarCollapsed; } }
    }

    function openClose() {
        var availableScreenSpace = Plasmoid.availableScreenRect;

        if(root.sidebarDock) {
            slide_animation.target = window;

            if(!root.sidebarCollapsed) {
                if(root.is_panel_bottom() && !root.is_panel_top()) {
                    slide_animation.from = window.y;
                    slide_animation.to = Screen.height;

                }
                else if(!root.is_panel_bottom() && root.is_panel_top()) {
                    slide_animation.from = window.y;
                    slide_animation.to = -Screen.height;

                }
                else {
                    slide_animation.from = window.y;
                    slide_animation.to = Screen.height;

                }

                Plasmoid.configuration.collapsed = true;

            } else {
                if(root.is_panel_bottom() && !root.is_panel_top()) {
                    slide_animation.from = window.y;
                    slide_animation.to = availableScreenSpace.y;

                }
                else if(!root.is_panel_bottom() && root.is_panel_top()) {
                    slide_animation.from = window.y;
                    slide_animation.to = availableScreenSpace.y;

                }
                else {
                    slide_animation.from = window.y;
                    slide_animation.to = availableScreenSpace.y;

                }

                window.visible = true;
                Plasmoid.configuration.collapsed = false;
            }
        }
        else {
            slide_animation.target = sidebarContainer;

            if(!root.sidebarCollapsed) {
                if(root.is_panel_bottom() && !root.is_panel_top()) {
                    slide_animation.from = sidebarContainer.y;
                    slide_animation.to = windowRoot.height;

                }
                else if(!root.is_panel_bottom() && root.is_panel_top()) {
                    slide_animation.from = sidebarContainer.y;
                    slide_animation.to = -windowRoot.height;

                }
                else {
                    slide_animation.from = sidebarContainer.y;
                    slide_animation.to = windowRoot.height;

                }

                Plasmoid.configuration.collapsed = true;

            } else {
                if(root.is_panel_bottom() && !root.is_panel_top()) {
                    slide_animation.from = sidebarContainer.y;
                    slide_animation.to = windowRoot.y;

                }
                else if(!root.is_panel_bottom() && root.is_panel_top()) {
                    slide_animation.from = sidebarContainer.y;
                    slide_animation.to = windowRoot.y;

                }
                else {
                    slide_animation.from = sidebarContainer.y;
                    slide_animation.to = windowRoot.y;

                }

                window.visible = true;
                Plasmoid.configuration.collapsed = false;
            }
        }

        slide_animation_root.start();
    }
}
