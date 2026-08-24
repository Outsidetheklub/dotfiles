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
        property string prevSsid: ""

        // shell single-quote escaping (safe for passwords with $, `, ", etc.)
        function sq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

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

        // ── password prompt (overlay, bottom of popup) ─────────────────
        Rectangle {
            id: passPrompt
            visible: false
            z: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            height: 64
            radius: 6
            color: Style.backgroundAlt
            border.color: Style.alert
            border.width: 1

            property string targetSsid: ""

            onVisibleChanged: if (visible) { passField.text = ""; passField.forceActiveFocus() }

            Text {
                id: passLabel
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: cancelBtn.left
                anchors.margins: 8
                text: "Password for " + passPrompt.targetSsid
                color: Style.foreground
                font.family: Style.fontFamily
                font.pointSize: 10
                elide: Text.ElideRight
            }

            Text {
                id: cancelBtn
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                text: "\uf00d"
                color: Style.foregroundAlt
                font.family: Style.fontFamily
                font.pointSize: 10
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: passPrompt.cancel()
                }
            }

            // visible input box (so it's obvious where to type)
            Rectangle {
                id: passBox
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: connectBtn.left
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                height: 26
                radius: 4
                color: Style.background
                border.color: Style.disabled
                border.width: 1

                TextInput {
                    id: passField
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    color: Style.primary
                    selectionColor: Style.primary
                    selectedTextColor: Style.background
                    font.family: Style.fontFamily
                    font.pointSize: 11
                    echoMode: TextInput.Password
                    selectByMouse: true
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Type password, press Enter"
                        color: Style.foregroundAlt
                        font.family: Style.fontFamily
                        font.pointSize: 9
                        verticalAlignment: Text.AlignVCenter
                        visible: parent.text === ""
                        elide: Text.ElideRight
                    }

                    Keys.onReturnPressed: passPrompt.submit()
                    Keys.onEscapePressed: passPrompt.cancel()
                }
            }

            Rectangle {
                id: connectBtn
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.margins: 8
                width: 74
                height: 26
                radius: 4
                color: Style.primary

                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    color: Style.background
                    font.family: Style.fontFamily
                    font.pointSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: passPrompt.submit()
                }
            }

            function submit() {
                const pw = passField.text
                if (pw === "") return // empty = keep prompt open, don't retry without password
                const ssid = passPrompt.targetSsid
                passPrompt.visible = false
                wifiPopup.runConnect(ssid, pw)
            }
            function cancel() {
                passPrompt.visible = false
                if (wifiPopup.prevSsid !== "" && wifiPopup.prevSsid !== passPrompt.targetSsid) {
                    // cancelled the switch → make sure the old network is back
                    root.run(["sh", "-c", "nmcli connection up " + wifiPopup.sq(wifiPopup.prevSsid) + " 2>/dev/null; true"])
                }
                wifiBg.forceActiveFocus()
            }
        }

        function toggle() {
            if (wifiPopup.visible) {
                wifiPopup.visible = false
                return
            }
            // position under the module BEFORE mapping (root.x is row-relative)
            const g = root.mapToGlobal(root.width, 0)
            wifiPopup.x = g.x - wifiPopup.width - 4
            wifiPopup.y = g.y + Style.barHeight + 4
            wifiPopup.visible = true
            refresh()
            wifiBg.forceActiveFocus()
            wifiPopup.requestActivate()
            moveTimer.start()
        }

        Timer {
            id: moveTimer
            interval: 50
            onTriggered: root.run(["i3-msg", "[title=\"Quickshell WiFi\"]", "move", "position", String(wifiPopup.x), String(wifiPopup.y)])
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
            passPrompt.visible = false
            if (net.disconnect) {
                wifiPopup.disconnect()
                return
            }
            // remember what we're on, so a failed switch can restore it
            wifiPopup.prevSsid = wifiPopup.currentSsid
            // try without password first (saved networks connect instantly);
            // if NM says a secret is required, runConnect() will show the prompt
            wifiPopup.runConnect(net.ssid, "")
        }

        function runConnect(ssid, password) {
            wifiPopup.visible = false
            const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', wifiPopup, "wifiConn")
            const col = Qt.createQmlObject('import Quickshell.Io; StdioCollector { waitForEnd: true }', proc, "wifiConnCol")
            proc.stdout = col
            const passArg = password === "" ? "" : " password " + wifiPopup.sq(password)
            proc.command = ["sh", "-c", "nmcli -w 20 device wifi connect " + wifiPopup.sq(ssid) + passArg + " 2>&1"]
            col.streamFinished.connect(() => {
                const out = col.text.trim()
                if (out.indexOf("successfully activated") !== -1) {
                    if (password !== "") {
                        // persist secret to the profile file (psk-flags 0) so
                        // boot auto-connect works without a keyring/agent
                        root.run(["sh", "-c", "nmcli connection modify " + wifiPopup.sq(ssid) + " 802-11-wireless-security.psk-flags 0 2>/dev/null; true"])
                    }
                    root.run(["notify-send", "WiFi", "Connected to " + ssid])
                    wifiPopup.currentSsid = ssid
                    wifiPopup.applyList()
                    proc.running = true // refresh the bar module text
                } else if (password === "" && /secrets were required|no secrets|password|authentication/i.test(out)) {
                    // network demands a password → show the prompt
                    passPrompt.targetSsid = ssid
                    passPrompt.visible = true
                    wifiPopup.visible = true
                    wifiPopup.requestActivate()
                    passField.forceActiveFocus()
                } else {
                    if (wifiPopup.prevSsid !== "" && wifiPopup.prevSsid !== ssid) {
                        // switching failed → bring the old network back
                        root.run(["sh", "-c", "nmcli connection up " + wifiPopup.sq(wifiPopup.prevSsid) + " 2>/dev/null; true"])
                        root.run(["notify-send", "WiFi", "Couldn't connect to " + ssid + ", restored " + wifiPopup.prevSsid])
                    } else {
                        root.run(["notify-send", "WiFi", "Failed: " + (out || "unknown error")])
                    }
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
