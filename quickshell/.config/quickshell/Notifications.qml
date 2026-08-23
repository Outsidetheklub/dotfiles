import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Window as RealWindow
import "style.js" as Style

// Notification daemon UI — dunst replacement.
// Popup top-right below the bar; visible while notifications exist.
RealWindow.Window {
    id: root
    title: "Quickshell Notifications"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    width: 380
    height: 96
    color: "transparent"

    NotificationServer {
        id: server
        onNotification: (notification) => {
            notification.tracked = true
            root.notifs.push(notification)
            root.receivedAt[notification.id] = Date.now()
            // drop it from our list when the server closes it
            notification.closed.connect(() => {
                const idx = root.notifs.indexOf(notification)
                if (idx !== -1) root.notifs.splice(idx, 1)
            })
            root.sync()
        }
    }

    property var notifs: []
    property var receivedAt: ({})

    // the server does not auto-expire — the UI must call expire()
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.checkExpiry()
    }

    function checkExpiry() {
        const now = Date.now()
        for (const n of root.notifs) {
            const received = root.receivedAt[n.id] || 0
            if (n.expireTimeout > 0 && now - received > n.expireTimeout) {
                n.expire()
            }
        }
    }

    // keep the window sized/visible in sync with the notification model
    function sync() {
        syncTimer.restart()
    }

    Timer {
        id: syncTimer
        interval: 60
        onTriggered: {
            root.visible = list.count > 0
            root.height = Math.min(list.count * 96 + 10, 600)
            if (root.visible) moveTimer.start()
        }
    }


    // opaque-ish background (quickshell windows are transparent)
    Rectangle {
        anchors.fill: parent
        color: "#CC1C2027" // bar bg with slight translucency
        radius: 10
    }

    // ── notification list ──────────────────────────────────────────────
    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 5
        model: server.trackedNotifications
        clip: true
        spacing: 4
        onCountChanged: root.sync()

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 86
            radius: 8
            color: Style.backgroundAlt
            border.color: modelData.urgency === 2 ? Style.alert : "transparent"
            border.width: modelData.urgency === 2 ? 1 : 0

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 3

                Row {
                    width: parent.width
                    spacing: 6
                    Text {
                        text: modelData.appName
                        color: modelData.urgency === 2 ? Style.alert : Style.foregroundAlt
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width - 30
                    }
                    Text {
                        text: "\uf00d" // x
                        color: Style.disabled
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.dismiss()
                        }
                    }
                }

                Text {
                    text: modelData.summary
                    color: Style.foreground
                    font.family: Style.fontFamily
                    font.pointSize: Style.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: modelData.body
                    color: Style.foregroundAlt
                    font.family: Style.fontFamily
                    font.pointSize: Style.fontSize
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    width: parent.width
                }
            }

            // click card = dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: modelData.dismiss()
            }
        }
    }

    Timer {
        id: moveTimer
        interval: 50
        onTriggered: root.run(["i3-msg", "[title=\"Quickshell Notifications\"]", "move", "position", String(Screen.width - root.width - 4), String(Style.barHeight + 4)])
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }
}
