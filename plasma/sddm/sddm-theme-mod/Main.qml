import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support

import SddmComponents
import QtMultimedia

import "SMOD" as SMOD

Item
{
    id: root

    LayoutMirroring.enabled : Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit : true

    property bool m_forceUserSelect: config.boolValue("forceUserSelect")

    enum LoginPage {
        Startup,
        SelectUser,
        Login,
        LoginFailed
    }

    // copied from sddm/src/greeter/UserModel.h because
    // it doesn't seem accessible via e.g. SDDM.UserModel.NameRole
    enum UserRoles {
        NameRole = 257,
        RealNameRole,
        HomeDirRole,
        IconRole,
        NeedsPasswordRole
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            password.text = ""
            pages.currentIndex = Main.LoginPage.LoginFailed
        }
    }

    Keys.onEscapePressed: {
        if(pages.currentIndex === Main.LoginPage.Login && switchuser.enabled) {
            password.text = ""
            pages.currentIndex = Main.LoginPage.SelectUser
        } else if(pages.currentIndex === Main.LoginPage.LoginFailed)
            pages.currentIndex = Main.LoginPage.Login
    }

    Background {
        id: background

        anchors.fill: parent

        fillMode: Image.Stretch
        source: Qt.resolvedUrl(config.stringValue("background"))
    }

    Timer {
        id: startupSoundDelay

        interval: config.boolValue("enableStartup") ? 250 : 20
        running: startupSound.playSound
        onTriggered: startupSound.play()
    }

    MediaPlayer {
        id: startupSound

        property bool playSound: !executable.fileExists && config.boolValue("playSound")

        audioOutput: AudioOutput {}
        source: "Assets/session-start.wav"
    }

    Component {
        id: userDelegate

        SMOD.UserDelegate {
            Keys.onReturnPressed: {
                if(focus) {
                    let username = model.name

                    if(username != null) {
                        let realname = model.realName
                        let pic = model.icon
                        let needspassword = model.needsPassword

                        if(needspassword) {
                            userNameLabel.text = realname
                            avatar.source = pic

                            listView.currentIndex = index
                            pages.currentIndex = Main.LoginPage.Login
                        }
                        else sddm.login(username, password.text, session.index)
                    }
                }
            }
        }
    }

    Loader {
        id: inputPanel

        property bool active: false
        readonly property bool keyboardActive: item?.active ?? false

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Kirigami.Units.gridUnit*12
            rightMargin: Kirigami.Units.gridUnit*12
        }

        state: "hidden"

        onKeyboardActiveChanged: {
            if (keyboardActive) {
                inputPanel.z = 99;
                Qt.inputMethod.show();
                active = true;
            } else {
                //inputPanel.item.activated = false;
                Qt.inputMethod.hide();
                active = false;
            }
        }

        function showHide() {
            active = !active;
            inputPanel.item.activated = Qt.binding(() => { return active });
        }

        Component.onCompleted: {
            inputPanel.source = Qt.platform.pluginName.includes("wayland") ? "SMOD/VirtualKeyboard_wayland.qml" : "SMOD/VirtualKeyboard.qml"

            if(inputPanel.status === Loader.Ready) {
                var menuitem = session.createMenuSeparator();

                session.addItem(menuitem);
                menuitem = session.createMenuItem();
                menuitem.text = "On-Screen Keyboard"
                menuitem.checkable = false;
                menuitem.icon.source = Qt.resolvedUrl("Assets/keyboard.png");
                menuitem.triggered.connect(() => {
                    password.forceActiveFocus();
                    inputPanel.showHide();
                });
                session.addAction(menuitem);
            }
        }
    }

    StackLayout {
        id: pages

        anchors.fill: parent
        anchors.bottomMargin: inputPanel.active ? inputPanel.height : 0

        onCurrentIndexChanged: {
            if (currentIndex == Main.LoginPage.SelectUser)
                listView.forceActiveFocus()
            else if (currentIndex == Main.LoginPage.Login)
                password.forceActiveFocus()
            else if (currentIndex == Main.LoginPage.LoginFailed)
                dismissButton.forceActiveFocus()
        }

        Plasma5Support.DataSource {
            id: executable
            engine: "executable"
            connectedSources: []
            property bool read: false
            property bool startupEnabled: !fileExists && config.boolValue("enableStartup");
            property bool fileExists: false
            onNewData: (sourceName, data) => {
                var stdout = data["stdout"]
                exited(stdout)
                disconnectSource(sourceName) // cmd finished
            }
            function exec(cmd, r) {
                executable.read = r;
                if (cmd) {
                    connectSource(cmd)
                }
            }
            signal exited(string stdout)
        }

        Connections {
            target: executable
            function onExited(stdout) {
                if(executable.read) {
                    if(stdout.trim() !== "") { // If the file exists, do not play Vista boot animation
                        executable.fileExists = true;
                    } else {
                        executable.exec("touch /tmp/sddm.startup", false); // Create it to prevent multiple boot animations from happening
                        if(startupSound.playSound) {
                            startupSoundDelay.start()
                        }
                        if(executable.startupEnabled) seqanimation.start();

                    }
                }
            }
        }

        // for testing failed login
        currentIndex: executable.startupEnabled ? Main.LoginPage.Startup : Main.LoginPage.SelectUser

        function startSingleUserMode() {
            let singleusermode = userModel.count < 2 && !m_forceUserSelect

            if (singleusermode) {
                let index = 0;
                let username = userModel.data(userModel.index(index, 0), Main.UserRoles.NameRole)

                if (username != null) {
                    let userDisplayName = userModel.data(userModel.index(index, 0), Main.UserRoles.RealNameRole)
                    let userPicture = userModel.data(userModel.index(index, 0), Main.UserRoles.IconRole)

                    userNameLabel.text = userDisplayName
                    avatar.source = userPicture

                    pages.currentIndex = Main.LoginPage.Login
                    return true;
                }
            }
            pages.currentIndex = Main.LoginPage.SelectUser;
            return false;
        }

        Component.onCompleted: {
            executable.exec("ls /tmp/sddm.startup", true); // Check if sddm.startup exists
            startSingleUserMode();
        }

        Item { id: startupPage }

        Item {
            id: userlistpage

            anchors.fill: parent

            GridView {
                id: listView

                anchors.centerIn: parent
                anchors.verticalCenterOffset: count < 5 ? 72 : 0

                width: count < 5 ? cellWidth * count : cellWidth * 5
                height: count > 5 ? cellHeight * 2 : cellHeight

                cellWidth: 200
                cellHeight: 200
                clip: true
                interactive: true
                keyNavigationEnabled: true
                keyNavigationWraps: false
                focus: true
                boundsBehavior: Flickable.StopAtBounds
                model: userModel
                delegate: userDelegate
                currentIndex: userModel.lastIndex

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                KeyNavigation.backtab: rebootButton
                KeyNavigation.tab: accessbutton

                MouseArea {
                    anchors.fill: parent

                    onClicked: (mouse) => {
                        let posInGridView = Qt.point(mouse.x, mouse.y)
                        let posInContentItem = mapToItem(listView.contentItem, posInGridView)
                        let index = listView.indexAt(posInContentItem.x, posInContentItem.y)

                        let username = userModel.data(userModel.index(index, 0), Main.UserRoles.NameRole)

                        if (username != null) {
                            let realname = userModel.data(userModel.index(index, 0), Main.UserRoles.RealNameRole)
                            let pic = userModel.data(userModel.index(index, 0), Main.UserRoles.IconRole)
                            let needspassword = userModel.data(userModel.index(index, 0), Main.UserRoles.NeedsPasswordRole)

                            if (needspassword) {
                                userNameLabel.text = realname == "" ? username : realname;
                                avatar.source = pic

                                listView.currentIndex = index
                                pages.currentIndex = Main.LoginPage.Login
                            }
                            else sddm.login(username, password.text, session.index)
                        }
                    }
                }
            }
        }

        Item {
            id: loginpage

            Column {
                id: mainColumn

                anchors.centerIn: parent

                Item {
                    id: userpic

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: -1
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: -56

                    width: 190
                    height: width

                    Item {
                        anchors.centerIn: parent

                        width: 126
                        height: width

                        Rectangle {
                            id: mask

                            anchors.fill: parent
                            anchors.centerIn: parent

                            radius: 2
                            visible: false
                        }

                        LinearGradient {
                            id: gradient

                            anchors.fill: parent
                            anchors.centerIn: parent

                            start: Qt.point(0,0)
                            end: Qt.point(gradient.width, gradient.height)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#eeecee" }
                                GradientStop { position: 1.0; color: "#a39ea3" }
                            }

                            z: -1
                        }

                        Image {
                            id: avatar

                            anchors.fill: parent
                            anchors.centerIn: parent

                            fillMode: Image.PreserveAspectCrop
                            source: ""

                            onStatusChanged: if (avatar.status == Image.Error) avatar.source = "Assets/user/normal.png";

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: mask
                            }
                        }
                    }

                    Image { anchors.fill: parent; source: "Assets/user/normal.png" }
                }


                Item
                {
                    id: loginbox

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: userpic.bottom
                    anchors.topMargin: 4

                    QQC2.Label {
                        id: userNameLabel

                        anchors.horizontalCenter: parent.horizontalCenter

                        text: ""
                        color: "white"
                        font.pixelSize: 23
                        font.kerning: false
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferVerticalHinting
                    }
                    QQC2.TextField {
                        id: password

                        anchors.top: userNameLabel.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 8

                        width: 225
                        height: 25

                        leftPadding: 7

                        font.pointSize: password.length > 0 ? 7 : 9
                        placeholderTextColor: "#555"
                        background: BorderImage {
                            border {
                                top: 3
                                bottom: 3
                                left: 3
                                right: 3
                            }
                            source: {
                                if (password.focus) return "Assets/input/focus.png"
                                if (password.hovered) return "Assets/input/hover.png"
                                return "Assets/input/normal.png"
                            }
                        }
                        placeholderText: "Password"
                        selectByMouse: true
                        echoMode : TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

                        KeyNavigation.backtab: switchLayoutButton
                        KeyNavigation.tab: loginButton
                        KeyNavigation.down: switchuser.enabled ? switchuser : accessbutton


                        Keys.onPressed : (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                let index = listView.currentIndex
                                let username = userModel.data(userModel.index(index, 0), Main.UserRoles.NameRole)

                                if (username != null) sddm.login(username, password.text, session.index)
                                event.accepted = true
                            }
                            else if (
                                event.matches(StandardKey.Undo) ||
                                event.matches(StandardKey.Redo) ||
                                event.matches(StandardKey.Cut) ||
                                event.matches(StandardKey.Copy) ||
                                event.matches(StandardKey.Paste)
                                )
                            {
                                // disable these events
                                event.accepted = true
                            }
                        }
                    }
                    RowLayout {
                        anchors.top: password.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 2

                        spacing: 2

                        visible: keyboard.capsLock && password.visible

                        Image {
                            id: iconSmall
                            width: Kirigami.Units.iconSizes.small;
                            height: Kirigami.Units.iconSizes.small;

                            source: "./Assets/dialog-warning.png"
                            sourceSize.width: iconSmall.width
                            sourceSize.height: iconSmall.height
                        }

                        QQC2.Label {
                            id: notificationsLabel
                            font.pointSize: 9
                            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Caps Lock is on");
                            width: implicitWidth
                            renderType: Text.NativeRendering
                            color: "white"
                        }
                    }

                    QQC2.Button {
                        id: loginButton

                        anchors.left: password.right
                        anchors.verticalCenter: password.verticalCenter
                        anchors.verticalCenterOffset: -1
                        anchors.leftMargin: 4

                        width: 30
                        height: 30

                        background: Image {
                            source: loginButton.pressed ? "Assets/go/pressed.png" : (loginButton.focus || loginButton.hovered ? "Assets/go/hover.png" : "Assets/go/normal.png")
                        }

                        onClicked: {
                            let index = listView.currentIndex
                            let username = userModel.data(userModel.index(index, 0), Main.UserRoles.NameRole)

                            if (username != null) sddm.login(username, password.text, session.index)
                        }

                        KeyNavigation.backtab: password
                        KeyNavigation.tab: switchuser.enabled ? switchuser : accessbutton
                        KeyNavigation.down: switchuser.enabled ? switchuser : accessbutton
                    }
                }
                QQC2.Button {
                    id: switchuser

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: userpic.bottom
                    anchors.topMargin: 124

                    width: contentItem.width < 108 ? 108 : contentItem.width
                    height: 28

                    onClicked: {
                        password.text = ""
                        pages.currentIndex = Main.LoginPage.SelectUser
                    }

                    background: BorderImage {
                        border {
                            top: 3
                            bottom: 3
                            left: 3
                            right: 3
                        }
                        source: {
                            if(switchuser.pressed) return "Assets/switchuser/pressed.png"
                            if(switchuser.hovered && switchuser.focus) return "Assets/switchuser/hover-focus.png"
                            if(switchuser.hovered && !switchuser.focus) return "Assets/switchuser/hover.png"
                            if(!switchuser.hovered && switchuser.focus) return "Assets/switchuser/normal-focus.png"
                            return "Assets/switchuser/normal.png"
                        }
                    }

                    contentItem: Text {
                        text: "Switch User"
                        color: "white"
                        font.pointSize: 11
                        font.kerning: false
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        horizontalAlignment : Text.AlignHCenter
                        verticalAlignment : Text.AlignVCenter
                        bottomPadding: 3
                        rightPadding: 6
                        leftPadding: 6
                    }

                    KeyNavigation.backtab: password
                    KeyNavigation.up: password
                    KeyNavigation.tab: accessbutton
                    KeyNavigation.down: accessbutton
                    Keys.onReturnPressed: {
                        clicked()
                        event.accepted = true
                    }
                }
            }


        }


        Item {
            id: loginfailedpage

            Keys.onEscapePressed: {
                pages.currentIndex = Main.LoginPage.Login
            }

            Image {
                id: currentMessageIcon

                anchors.right: currentMessage.left
                anchors.rightMargin: 11
                anchors.verticalCenter: currentMessage.verticalCenter
                anchors.verticalCenterOffset: -2

                width: 32
                height: 32

                source: "Assets/dialog-error.png"
                focus: false
                smooth: false
            }

            QQC2.Label {
                id: currentMessage

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 126
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 14

                width: implicitWidth

                text: "The user name or password is incorrect."
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: 9
                focus: false
                color: "white"
                horizontalAlignment: Text.AlignCenter
            }

            QQC2.Button {
                id: dismissButton

                anchors.top: currentMessage.bottom
                anchors.topMargin: 46
                anchors.horizontalCenter: parent.horizontalCenter

                width: contentItem.width < 93 ? 93 : contentItem.width
                height: 28

                onClicked: pages.currentIndex = Main.LoginPage.Login

                background: BorderImage {
                    border {
                        top: 3
                        bottom: 3
                        left: 3
                        right: 3
                    }
                    source: {
                        if(dismissButton.pressed) return "Assets/switchuser/pressed.png"
                        if(dismissButton.hovered && dismissButton.focus) return "Assets/switchuser/hover-focus.png"
                        if(dismissButton.hovered && !dismissButton.focus) return "Assets/switchuser/hover.png"
                        if(!dismissButton.hovered && dismissButton.focus) return "Assets/switchuser/normal-focus.png"
                        return "Assets/switchuser/normal.png"
                    }
                }

                contentItem: Text {
                    text: "OK"
                    color: "white"
                    font.pointSize: 11
                    horizontalAlignment : Text.AlignHCenter
                    verticalAlignment : Text.AlignVCenter
                    renderType: Text.NativeRendering
                    bottomPadding: 3
                    rightPadding: 6
                    leftPadding: 6
                }

                Keys.onReturnPressed: {
                    clicked()
                    event.accepted = true
                }
            }
        }
    }

    Image {
        id: branding

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 23
        anchors.horizontalCenter: parent.horizontalCenter

        source: config.stringValue("branding")
        visible: pages.currentIndex != Main.LoginPage.Startup
    }

    SMOD.GenericButton {
        id: switchLayoutButton

        property int currentIndex: keyboard.currentLayout
        onCurrentIndexChanged: keyboard.currentLayout = currentIndex

        anchors {
            top: parent.top
            topMargin: 5
            left: parent.left
            leftMargin: 7
        }
        implicitWidth: 35
        implicitHeight: 28
        label.font.pointSize: 9
        label.font.capitalization: Font.AllUppercase
        Accessible.description: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to change keyboard layout", "Switch layout")
        KeyNavigation.backtab: rebootButton
        KeyNavigation.tab: pages.currentIndex === Main.LoginPage.SelectUser ? listView : password
        KeyNavigation.down: pages.currentIndex === Main.LoginPage.SelectUser ? listView : password

        text: keyboard.layouts[currentIndex].shortName
        onClicked: currentIndex = (currentIndex + 1) % keyboard.layouts.length

        visible: keyboard.layouts.length > 1 && pages.currentIndex != Main.LoginPage.Startup
    }
    QQC2.CheckBox
    {
        id: accessbutton

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 34
        anchors.leftMargin: 34

        width: 38
        height: 28

        visible: pages.currentIndex != Main.LoginPage.LoginFailed && pages.currentIndex != Main.LoginPage.Startup

        indicator.width: 0
        indicator.height: 0

        background: BorderImage {
            border {
                top: 3
                bottom: 3
                left: 3
                right: 3
            }
            source: {
                if(accessbutton.pressed) return "Assets/switchuser/pressed.png"
                if(accessbutton.hovered && accessbutton.focus) return "Assets/switchuser/hover-focus.png"
                if(accessbutton.hovered && !accessbutton.focus) return "Assets/switchuser/hover.png"
                if(!accessbutton.hovered && accessbutton.focus) return "Assets/switchuser/normal-focus.png"
                return "Assets/switchuser/normal.png"
            }
        }

        contentItem: Item {
            anchors.centerIn: parent

            width: 24
            height: 24

            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: "Assets/access-glyph.png"
                smooth: false
            }
        }

        enabled: !session.visible
        onToggled: {
            if(session.visible) session.close();
            else session.open();
        }

        Keys.onReturnPressed: {
            clicked()
            event.accepted = true
        }

        KeyNavigation.backtab: {
            if (pages.currentIndex === Main.LoginPage.SelectUser)
                return listView
            else if (switchuser.enabled)
                return switchuser
            return password
        }

        KeyNavigation.up: {
            if (pages.currentIndex === Main.LoginPage.Login && switchuser.enabled)
                return switchuser
            return accessbutton
        }

        KeyNavigation.tab: shutdownButton
        KeyNavigation.right: shutdownButton

        Item {
            anchors.bottom: parent.top
            anchors.left: parent.left
            anchors.bottomMargin: -32

            width: 128
            height: 64

            visible: pages.currentIndex != Main.LoginPage.LoginFailed
            enabled: visible

            SMOD.Menu {
                id: session
                x: 0
                y: -session.height + accessbutton.height + session.verticalPadding
                index: sessionModel.lastIndex

                function changeVal() {
                    session.valueChanged(this.index);
                    session.index = this.index;
                }
                function isIndex() {
                    return session.index === this.index
                }
                Component.onCompleted: {
                    for(var i = 0; i < sessionModel.count; i++) {
                        const NameRole = sessionModel.KItemModels.KRoleNames.role("name");
                        const name = sessionModel.data(sessionModel.index(i, 0), NameRole);
                        var menuitem = createMenuItem();
                        menuitem.text = name;
                        menuitem.index = i;
                        var func = isIndex.bind({index: i});
                        menuitem.checkable = true;
                        menuitem.checked = Qt.binding(func);
                        menuitem.triggered.connect(changeVal.bind({index: i}));
                        session.addAction(menuitem);
                    }
                }

            }
        }
    }

    Item {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 34
        anchors.rightMargin: 30

        width: 62
        height: 28

        visible: pages.currentIndex != Main.LoginPage.LoginFailed && pages.currentIndex != Main.LoginPage.Startup
        enabled: pages.currentIndex != Main.LoginPage.Startup

        QQC2.Button {
            id: shutdownButton

            anchors.bottom: parent.bottom
            anchors.left: parent.left

            width: 38
            height: 28

            background: Image {
                source: {
                    if (shutdownButton.pressed) return "Assets/power/left-pressed.png"
                    if (shutdownButton.hovered && shutdownButton.focus) return "Assets/power/left-hover-focus.png"
                    if (shutdownButton.hovered && !shutdownButton.focus) return "Assets/power/left-hover.png"
                    if (!shutdownButton.hovered && shutdownButton.focus) return "Assets/power/left-normal-focus.png"
                    return "Assets/power/left-normal.png"
                }
            }

            contentItem: Item {
                anchors.centerIn: parent

                width: 24
                height: 24

                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: "Assets/power/power-glyph.png"
                    smooth: false
                }
            }

            onClicked : sddm.powerOff()

            Keys.onReturnPressed:
            {
                clicked()
                event.accepted = true
            }

            KeyNavigation.backtab: accessbutton
            KeyNavigation.left: accessbutton
            KeyNavigation.tab: rebootButton
            KeyNavigation.right: rebootButton
            KeyNavigation.up:
            {
                if (pages.currentIndex === Main.LoginPage.Login && switchuser.enabled)
                {
                    return switchuser
                }

                return shutdownButton
            }

            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            QQC2.ToolTip.text: qsTr("Shut down")
        }

        QQC2.Button
        {
            id: rebootButton

            anchors.bottom: parent.bottom
            anchors.left: shutdownButton.right

            visible: pages.currentIndex != Main.LoginPage.Startup

            width: 20
            height: 28

            background: Image {
                source: {
                    if (rebootButton.pressed) return "Assets/power/right-pressed.png"
                    if (rebootButton.hovered && rebootButton.focus) return "Assets/power/right-hover-focus.png"
                    if (rebootButton.hovered && !rebootButton.focus) return "Assets/power/right-hover.png"
                    if (!rebootButton.hovered && rebootButton.focus) return "Assets/power/right-normal-focus.png"
                    return "Assets/power/right-normal.png"
                }
            }

            contentItem: Item {
                anchors.centerIn: parent

                width: 9
                height: 6

                Image {
                    anchors.centerIn: parent

                    width: 9
                    height: 6

                    source: "Assets/power/power-glyph-arrow.png"
                    smooth: false
                }
            }

            enabled: !powerMenu.visible
            onClicked: {
                if(powerMenu.visible) powerMenu.close();
                else powerMenu.open();

            }

            SMOD.Menu {
                id: powerMenu
                x: -powerMenu.width + parent.width //-parent.width + powerMenu.horizontalPadding
                y: -powerMenu.height //-powerMenu.height + rebootButton.height //+ powerMenu.verticalPadding

                Component.onCompleted: {
                    var menuitem = powerMenu.createMenuItem();
                    menuitem.text = "Restart";
                    menuitem.triggered.connect(() => { sddm.reboot() });
                    powerMenu.addAction(menuitem);
                    powerMenu.addItem(powerMenu.createMenuSeparator());

                    if(sddm.canSuspend) {
                        menuitem = powerMenu.createMenuItem();
                        menuitem.text = "Sleep";
                        menuitem.triggered.connect(() => { sddm.suspend() });
                        powerMenu.addAction(menuitem);
                    }
                    if(sddm.canHibernate) {
                        menuitem = powerMenu.createMenuItem();
                        menuitem.text = "Hibernate";
                        menuitem.triggered.connect(() => { sddm.hibernate() });
                        powerMenu.addAction(menuitem);
                    }
                    if(sddm.canHybridSleep) {
                        menuitem = powerMenu.createMenuItem();
                        menuitem.text = "Hybrid Sleep";
                        menuitem.triggered.connect(() => { sddm.hybridSleep() });
                        powerMenu.addAction(menuitem);
                    }
                    menuitem = powerMenu.createMenuItem();
                    menuitem.text = "Shut down";
                    menuitem.triggered.connect(() => { sddm.powerOff() });
                    powerMenu.addAction(menuitem);
                }

            }
            Keys.onReturnPressed: event => {
                clicked()
                event.accepted = true
            }

            KeyNavigation.backtab: shutdownButton
            KeyNavigation.left: shutdownButton
            KeyNavigation.up: pages.currentIndex === Main.LoginPage.Login && switchuser.enabled ? switchuser : rebootbutton
            KeyNavigation.tab: switchLayoutButton
        }
    }

    Item {
        id: startuppage

        anchors.fill: parent

        visible: executable.startupEnabled
        opacity: 1
        z: 99

        SequentialAnimation {
            id: seqanimation
            NumberAnimation { target: startuppage; property: "opacity"; to: 1;   duration: 220; easing.type: Easing.Linear }
            NumberAnimation { target: startupimage; property: "opacity"; to: 1;  duration: 650; easing.type: Easing.Linear }
            NumberAnimation { target: startupimage; property: "opacity"; to: 1;  duration: 200; easing.type: Easing.Linear }
            NumberAnimation { target: startupimage2; property: "opacity"; to: 1; duration: 650; easing.type: Easing.Linear }
            NumberAnimation { target: startupimage3; property: "opacity"; to: 1; duration: 650; easing.type: Easing.Linear }
            NumberAnimation { target: startupimage4; property: "opacity"; to: 1; duration: 650; easing.type: Easing.Linear }
            NumberAnimation { target: startupimage4; property: "opacity"; to: 1; duration: 200; easing.type: Easing.Linear }
            ParallelAnimation {
                NumberAnimation { target: startupimage2; property: "opacity"; to: 0;  duration: 650; easing.type: Easing.OutQuad }
                NumberAnimation { target: startupimage3; property: "opacity"; to: 0;  duration: 650; easing.type: Easing.OutQuad }
                NumberAnimation { target: startupimage4; property: "opacity"; to: 0;  duration: 650; easing.type: Easing.OutQuad }
                NumberAnimation { target: startupimage; property: "opacity"; to: 0;  duration: 950; easing.type:  Easing.OutQuad }
            }
            ScriptAction { script: { pages.startSingleUserMode(); } }
            NumberAnimation { target: startuppage; property: "opacity"; to: 0; duration: 650; easing.type: Easing.Linear }
            NumberAnimation { target: startupanimation; property: "opacity"; to: 0; duration: 650; easing.type: Easing.OutQuad }
            PropertyAction { target: executable; property: "startupEnabled"; value: false }
        }

        Rectangle {
            color: "black"
            anchors.fill: parent
        }

        Item {
            id: startupanimation

            property int progress: 0

            anchors.centerIn: parent

            Image {
                id: startupimage

                anchors.centerIn: parent

                source: Qt.resolvedUrl("./Assets/startup/1")
                opacity: 0
            }

            Image {
                id: startupimage2

                anchors.centerIn: parent

                source: Qt.resolvedUrl("./Assets/startup/2")
                opacity: 0
            }

            Image {
                id: startupimage3

                anchors.centerIn: parent

                source: Qt.resolvedUrl("./Assets/startup/3")
                opacity: 0
            }

            Image {
                id: startupimage4

                anchors.centerIn: parent

                source: Qt.resolvedUrl("./Assets/startup/4")
                opacity: 0
            }

        }

        // to hide the cursor
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.BlankCursor
        }
    }
}
