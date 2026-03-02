/*
 * Copyright 2013 Heena Mahour <heena393@gmail.com>
 * Copyright 2013 Sebastian Kügler <sebas@kde.org>
 * Copyright 2013 Martin Klapetek <mklapetek@kde.org>
 * Copyright 2014 David Edmundson <davidedmundson@kde.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.clock
import org.kde.plasma.private.digitalclock

Item {
    id: main

    property string timeFormat
    property date currentTime

    property bool showSeconds: Plasmoid.configuration.showSeconds
    property bool showLocalTimezone: Plasmoid.configuration.showLocalTimezone
    property bool showDate: state != "horizontalSmall"

    Clock {
        id: clock
        timeZone: Plasmoid.configuration.lastSelectedTimezone
        trackSeconds: Plasmoid.configuration.showSeconds
        onDateTimeChanged: main.dateTimeChanged()
        onTimeZoneChanged: main.setupLabels()
    }

    property var dateFormat: {
        if(Plasmoid.configuration.dateFormat == "custom") return Plasmoid.configuration.customFormat
        else {
            if (Plasmoid.configuration.dateFormat === "longDate") {
                return Locale.LongFormat;//Qt.SystemLocaleLongDate;
            } else if (Plasmoid.configuration.dateFormat === "isoDate") {
                return Qt.ISODate;
            }
            return Qt.locale() //Locale.ShortFormat;//Qt.SystemLocaleShortDate;
        }
    }

    property string lastSelectedTimezone: Plasmoid.configuration.lastSelectedTimezone
    property bool displayTimezoneAsCode: Plasmoid.configuration.displayTimezoneAsCode
    property int use24hFormat: Plasmoid.configuration.use24hFormat

    property string lastDate: ""

    // This is the index in the list of user selected timezones
    property int tzIndex: 0
                                        
    property QtObject dashWindow: null

    onDateFormatChanged:            { setupLabels(); }

    onDisplayTimezoneAsCodeChanged: { setupLabels(); }
    onStateChanged:                 {
        setupLabels();
        timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat));
    }

    onLastSelectedTimezoneChanged:  { timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat)) }
    onShowSecondsChanged:           {
        timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat))
        main.dateTimeChanged();
    }
    onShowLocalTimezoneChanged:     {
        timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat))
        main.dateTimeChanged();
    }
    onUse24hFormatChanged:          {
        timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat));
        main.dateTimeChanged();
    }

    Connections {
        target: Plasmoid.configuration
        function onSelectedTimeZonesChanged() {
            // If the currently selected timezone was removed,
            // default to the first one in the list
            var lastSelectedTimezone = Plasmoid.configuration.lastSelectedTimezone;
            if (Plasmoid.configuration.selectedTimeZones.indexOf(lastSelectedTimezone) == -1) {
                Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[0];
            }

            setupLabels();
            setTimezoneIndex();
        }
    }

    // TODO: add vertical panels support
    states: [
        State {
            name: "horizontalBig"
            when: Plasmoid.formFactor == PlasmaCore.Types.Horizontal && main.height >= 40

            PropertyChanges {
                target: main

                Layout.fillHeight: true
                Layout.minimumWidth: mainContent.width
                Layout.maximumWidth: Layout.minimumWidth
            }

            PropertyChanges {
                target: mainContent

                width: 0 + Math.max(timeLabel.implicitWidth, dayLabel.implicitWidth, dateLabel.implicitWidth) + Kirigami.Units.smallSpacing * 3
                height: main.height
            }
        },
        State {
            name: "horizontal"
            when: Plasmoid.formFactor == PlasmaCore.Types.Horizontal && (main.height < 40 && main.height >= 30)

            PropertyChanges {
                target: main

                Layout.fillHeight: true
                Layout.minimumWidth: mainContent.width
                Layout.maximumWidth: Layout.minimumWidth
            }

            PropertyChanges {
                target: mainContent

                width: 0 + Math.max(timeLabel.implicitWidth, dateLabel.implicitWidth) + Kirigami.Units.smallSpacing * 3
                height: main.height
            }
        },
        State {
            name: "horizontalSmall"
            when: Plasmoid.formFactor == PlasmaCore.Types.Horizontal && main.height < 40

            PropertyChanges {
                target: main

                Layout.fillHeight: true
                Layout.minimumWidth: mainContent.width
                Layout.maximumWidth: Layout.minimumWidth
            }

            PropertyChanges {
                target: mainContent

                width: 0 + Math.max(timeLabel.implicitWidth, 0) + (Kirigami.Units.smallSpacing * 2) + 1
                height: main.height
            }
        }
    ]

    Connections {
        target: Plasmoid.configuration
        function onSelectedTimeZonesChanged() {
            // If the currently selected timezone was removed,
            // default to the first one in the list
            var lastSelectedTimezone = Plasmoid.configuration.lastSelectedTimezone;
            if (Plasmoid.configuration.selectedTimeZones.indexOf(lastSelectedTimezone) == -1) {
                Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[0];
            }

            setupLabels();
            setTimezoneIndex();
        }
    }
    
    Timer {
        id: tooltipTimer
        interval: 750
        repeat: false
        running: false
        onTriggered: if(!dashWindow.visible) timeToolTip.showToolTip();
    }

    Item {
        id: mainContent

        ColumnLayout {
            id: timeDate

            anchors.fill: parent

            uniformCellSizes: true
            spacing: 0

            Text {
                id: timeLabel

                Layout.topMargin: Plasmoid.configuration.offsetClock && main.state == "horizontalSmall" ? -4 : 0

                Layout.fillWidth: true

                renderType: Text.NativeRendering
                font {
                    family: Plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
                    weight: Plasmoid.configuration.boldText ? Font.Bold : Kirigami.Theme.defaultFont.weight
                    italic: Plasmoid.configuration.italicText
                    pointSize: Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize
                    hintingPreference: Font.PreferFullHinting
                }
                color: "white"
                style: {
                    if(Screen.devicePixelRatio == 1.0) return Text.Outline;
                    if(Screen.devicePixelRatio >= 2.0) return Text.Normal;
                    return Text.Raised;
                }
                styleColor: "transparent"
                //text:
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: main.state != "horizontalSmall" ? Text.AlignHCenter : Text.AlignLeft
                leftPadding: Plasmoid.configuration.offsetClock && main.state == "horizontalSmall" ? Kirigami.Units.mediumSpacing-2 : 0
            }
            Text {
                id: dayLabel

                Layout.fillWidth: true

                renderType: Text.NativeRendering
                font {
                    family: Plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
                    weight: Plasmoid.configuration.boldText ? Font.Bold : Kirigami.Theme.defaultFont.weight
                    italic: Plasmoid.configuration.italicText
                    pointSize: Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize
                    hintingPreference: Font.PreferFullHinting
                }
                color: "white"
                style: {
                    if(Screen.devicePixelRatio == 1.0) return Text.Outline;
                    if(Screen.devicePixelRatio >= 2.0) return Text.Normal;
                    return Text.Raised;
                }
                styleColor: "transparent"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: {
                    var now = dataSource.data[plasmoid.configuration.lastSelectedTimezone]["DateTime"];
                    return Qt.formatDate(now, "dddd");
                }

                visible: main.state == "horizontalBig"
            }
            Text {
                id: dateLabel

                Layout.fillWidth: true

                renderType: Text.NativeRendering
                font {
                    family: Plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
                    weight: Plasmoid.configuration.boldText ? Font.Bold : Kirigami.Theme.defaultFont.weight
                    italic: Plasmoid.configuration.italicText
                    pointSize: Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize
                    hintingPreference: Font.PreferFullHinting
                }
                color: "white"
                style: {
                    if(Screen.devicePixelRatio == 1.0) return Text.Outline;
                    if(Screen.devicePixelRatio >= 2.0) return Text.Normal;
                    return Text.Raised;
                }
                styleColor: "transparent"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                visible: main.showDate
            }
        }
    }

    MouseArea {
        id: mouseArea

        property int wheelDelta: 0

        anchors.fill: parent

        hoverEnabled: true

        onClicked: {
            Plasmoid.expanded = !Plasmoid.expanded
            dashWindow.visible = !dashWindow.visible;
            if(dashWindow.visible) timeToolTip.hideImmediately();
        }

        onContainsMouseChanged: {
            if(containsMouse) tooltipTimer.start();
            if(!containsMouse) {
                tooltipTimer.stop();
                timeToolTip.hideToolTip();
            }
        }
        onEntered: {
            tooltipTimer.start();
        }
        onExited: {
            tooltipTimer.stop();
            timeToolTip.hideToolTip();
        }
        onWheel: wheel => {
            if (!Plasmoid.configuration.wheelChangesTimezone) {
                return;
            }

            var delta = wheel.angleDelta.y || wheel.angleDelta.x
            var newIndex = main.tzIndex;
            wheelDelta += delta;
            // magic number 120 for common "one click"
            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                newIndex--;
            }
            while (wheelDelta <= -120) {
                wheelDelta += 120;
                newIndex++;
            }

            if (newIndex >= Plasmoid.configuration.selectedTimeZones.length) {
                newIndex = 0;
            } else if (newIndex < 0) {
                newIndex = Plasmoid.configuration.selectedTimeZones.length - 1;
            }

            if (newIndex != main.tzIndex) {
                Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[newIndex];
                main.tzIndex = newIndex;

                //dataSource.dataChanged();
                setupLabels();
            }
        }
    }

    PlasmaCore.ToolTipArea {
        id: timeToolTip

        mainItem: ToolTip {
            time: {
                var now = currentClock.dateTime;
                return Qt.formatDate(now, "dddd, MMMM dd, yyyy");
            }
        }
    }

    FontMetrics {
        id: timeMetrics

        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
    }

    function setLabelText() {
        var dt = clock.dateTime;
        main.currentTime = clock.dateTime //currentTime;
        var showTimezone = main.showLocalTimezone || (Plasmoid.configuration.lastSelectedTimezone != "Local" && !clock.isSystemTimeZone)
        var timezoneString = "";
        if (showTimezone) {
            timezoneString = Plasmoid.configuration.displayTimezoneAsCode ? clock.timeZoneCode : TimeZonesI18n.i18nCity(clock.timeZone);
        }
        timeLabel.text = (showTimezone ? "" : " ") + Qt.formatTime(currentTime, main.timeFormat) + " " + (showTimezone ? (" " + timezoneString) : "");
        dateLabel.text = Qt.formatDate(clock.dateTime, main.dateFormat);
        if(!main.showDate) dateLabel.text = dateLabel.text.slice(1) + " ";
        if(dayLabel.visible) dayLabel.text = Qt.formatDate(clock.dateTime, "dddd")
    }

    function timeFormatCorrection(timeFormatString) {
        var regexp = /(hh*)(.+)(mm)/i
        var match = regexp.exec(timeFormatString);

        var hours = match[1];
        var delimiter = match[2];
        var minutes = match[3]
        var seconds = "ss";
        var amPm = "AP";
        var uses24hFormatByDefault = timeFormatString.toLowerCase().indexOf("ap") == -1;

        // because QLocale is incredibly stupid and does not convert 12h/24h clock format
        // when uppercase H is used for hours, needs to be h or hh, so toLowerCase()
        var result = hours.toLowerCase() + delimiter + minutes;

        if (main.showSeconds) {
            result += delimiter + seconds;
        }

        // add "AM/PM" either if the setting is the default and locale uses it OR if the user unchecked "use 24h format"
        if ((main.use24hFormat == Qt.PartiallyChecked && !uses24hFormatByDefault) || main.use24hFormat == Qt.Unchecked) {
            result += " " + amPm;
        }

        main.timeFormat = result;
        setupLabels();
    }

    function setupLabels() {
        dateLabel.text = Qt.formatDate(clock.dateTime, main.dateFormat);

        // find widest character between 0 and 9
        var maximumWidthNumber = 0;
        var maximumAdvanceWidth = 0;
        for (var i = 0; i <= 9; i++) {
            var advanceWidth = timeMetrics.advanceWidth(i);
            if (advanceWidth > maximumAdvanceWidth) {
                maximumAdvanceWidth = advanceWidth;
                maximumWidthNumber = i;
            }
        }
        // replace all placeholders with the widest number (two digits)
        var format = main.timeFormat.replace(/(h+|m+|s+)/g, "" + maximumWidthNumber + maximumWidthNumber); // make sure maximumWidthNumber is formatted as string
        // build the time string twice, once with an AM time and once with a PM time
        var date = new Date(2000, 0, 1, 1, 0, 0);
        var timeAm = Qt.formatTime(date, format);
        var advanceWidthAm = timeMetrics.advanceWidth(timeAm);
    }

    function dateTimeChanged() {
        var doCorrections = false;

        if (main.showDate) {
            // If the date has changed, force size recalculation, because the day name
            // or the month name can now be longer/shorter, so we need to adjust applet size
            var currentDate = Qt.formatDateTime(clock.dateTime, "yyyy-mm-dd");
            if (main.lastDate != currentDate) {
                doCorrections = true;
                main.lastDate = currentDate
            }
        }

        if (doCorrections) {
            timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat));
        }

        setLabelText();

    }

    function setTimezoneIndex() {
        for (var i = 0; i < Plasmoid.configuration.selectedTimeZones.length; i++) {
            if (Plasmoid.configuration.selectedTimeZones[i] == Plasmoid.configuration.lastSelectedTimezone) {
                main.tzIndex = i;
                break;
            }
        }
    }

    Component.onCompleted: {
        root.initTimezones();
        Plasmoid.configuration.selectedTimeZones = TimeZoneUtils.sortedTimeZones(Plasmoid.configuration.selectedTimeZones);

        setTimezoneIndex();
        dateTimeChanged();
        timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat));
        dashWindow = Qt.createQmlObject("CalendarView {}", root);
    }
}
