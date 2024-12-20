import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_url: url.text

    ColumnLayout {
        Text {
            text: "RSS Feed URL"
        }
        QQC2.TextField {
            id: url
            Layout.fillWidth: true
            placeholderText: "https://wiki.qt.io/api.php?hidebots=1&urlversion=1&days=7&limit=50&action=feedrecentchanges"
        }
    }
}
