import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Window as RealWindow
import "style.js" as Style

// polybar network: script every 10s
// left-click opens QS wifi selector (replaces rofi wifi.sh),
// right-click nm-connection-editor
Item {
    id: root
    property var screenInfo: null
    property string text: ""
    implicitWidth: label.implicitWidth + 8
    height: parent.height

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#ffffff"
        font.family: Style.fontFamily
        font.pointSize: Style.moduleFontSize
    }

    Process {
        id: proc
        command: ["sh", "-c", "~/.config/quickshell/scripts/network.sh"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => root.text = text.trim()
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.run(["nm-connection-editor"])
            } else {
                wifiPopup.toggle()
            }
        }
    }

    // ── wifi selector popup ────────────────────────────────────────────
    RealWindow.Window {
        id: wifiPopup
        title: "Quickshell WiFi"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        visible: false
        x: 1536
        y: 32
        width: 380
        height: 400
        color: Style.background

        property var networks: []
        property var lastScan: []
        property string currentSsid: ""

        function applyList() {
            const arr = wifiPopup.lastScan.slice()
            if (wifiPopup.currentSsid !== "") {
                arr.unshift({ ssid: "Disconnect from " + wifiPopup.currentSsid, signal: "", locked: false, disconnect: true })
            }
            wifiPopup.networks = arr
            list.currentIndex = 0
        }

        Rectangle {
            id: wifiBg
            anchors.fill: parent
            color: Style.background
            radius: 8
            border.color: Style.disabled
            border.width: 1
            focus: true
            Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
            Keys.onDownPressed: list.currentIndex = Math.min(wifiPopup.networks.length - 1, list.currentIndex + 1)
            Keys.onReturnPressed: wifiPopup.connectTo(list.currentIndex)
            Keys.onEscapePressed: wifiPopup.visible = false
        }

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 14
            text: "\uf1eb  WiFi"
            color: Style.primary
            font.family: Style.fontFamily
            font.pointSize: Style.fontSize
        }

        ListView {
            id: list
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            model: wifiPopup.networks
            clip: true
            spacing: 2

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width
                height: 36
                radius: 5
                color: index === list.currentIndex ? Style.backgroundAlt : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: modelData.disconnect ? "\uf05e" : (wifiPopup.currentSsid === modelData.ssid ? "\uf0c1" : (modelData.locked ? "\uf023" : "\uf09c"))
                        color: modelData.disconnect ? Style.alert
                             : (wifiPopup.currentSsid === modelData.ssid ? Style.secondary
                             : modelData.locked ? Style.foregroundAlt : Style.disabled)
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        width: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.ssid
                        color: modelData.disconnect ? Style.alert : (index === list.currentIndex ? Style.primary : Style.foreground)
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        elide: Text.ElideRight
                        width: parent.width - 90
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.signal + "%"
                        color: Style.foregroundAlt
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: list.currentIndex = index
                    onClicked: wifiPopup.connectTo(index)
                }
            }
        }

        function toggle() {
            wifiPopup.visible = !wifiPopup.visible
            if (wifiPopup.visible) {
                refresh()
                wifiBg.forceActiveFocus()
                wifiPopup.requestActivate()
            }
        }

        function refresh() {
            scanProc.running = true
        }

        Process {
            id: scanProc
            command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan yes 2>/dev/null"]
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: () => {
                    const arr = []
                    for (const line of text.split("\n")) {
                        const parts = line.split(":")
                        if (parts.length >= 2 && parts[0] !== "") {
                            arr.push({ ssid: parts[0], signal: parts[1] || "0", locked: (parts[2] || "") !== "" })
                        }
                    }
                    wifiPopup.lastScan = arr
                    wifiPopup.applyList()
                }
            }
        }

        Process {
            id: curProc
            command: ["sh", "-c", "nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | grep -E ':wlan0$|:wlp' | cut -d: -f1 | head -1"]
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: () => wifiPopup.currentSsid = text.trim()
            }
        }

        // fresh process per connect: reliable restart + captured output + feedback
        function disconnect() {
            wifiPopup.visible = false
            root.run(["sh", "-c", "nmcli device disconnect wlan0 2>&1"])
            root.run(["notify-send", "WiFi", "Disconnected from " + wifiPopup.currentSsid])
            wifiPopup.currentSsid = ""
            wifiPopup.applyList()
            proc.running = true // refresh the bar module text
        }

        function connectTo(index) {
            const net = wifiPopup.networks[index]
            if (!net) return
            if (net.disconnect) {
                wifiPopup.disconnect()
                return
            }
            wifiPopup.visible = false
            const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', wifiPopup, "wifiConn")
            const col = Qt.createQmlObject('import Quickshell.Io; StdioCollector { waitForEnd: true }', proc, "wifiConnCol")
            proc.stdout = col
            proc.command = ["sh", "-c", "nmcli -w 20 device wifi connect " + JSON.stringify(net.ssid) + " 2>&1"]
            col.streamFinished.connect(() => {
                const out = col.text.trim()
                if (out.indexOf("successfully activated") !== -1) {
                    root.run(["notify-send", "WiFi", "Connected to " + net.ssid])
                } else {
                    root.run(["notify-send", "WiFi", "Failed: " + (out || "unknown error")])
                }
                col.destroy()
                proc.destroy()
            })
            proc.running = true
        }

        onVisibleChanged: if (visible) {
            curProc.running = true
            refresh()
        }
    }
}
