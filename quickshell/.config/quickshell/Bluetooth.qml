import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Window as RealWindow
import "style.js" as Style

// polybar bluetooth: script every 5s, click opens QS bluetooth manager
// (replaces rofi bluetooth-rofi.sh)
Item {
    id: root
    property string text: ""
    implicitWidth: label.implicitWidth + 8
    height: parent.height

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#ffffff"
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
    }

    Process {
        id: proc
        command: ["sh", "-c", "~/.config/quickshell/scripts/bluetooth.sh"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => root.text = text.trim()
        }
    }

    Timer {
        interval: 5000
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
        onClicked: btPopup.toggle()
    }

    // ── bluetooth manager popup ────────────────────────────────────────
    RealWindow.Window {
        id: btPopup
        title: "Quickshell Bluetooth"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        visible: false
        x: 1536
        y: 32
        width: 380
        height: 420
        color: Style.background

        property bool powered: false
        property var devices: []
        property var found: []

        Rectangle {
            anchors.fill: parent
            color: Style.background
            radius: 8
            border.color: Style.disabled
            border.width: 1
        }

        // header: title + power toggle
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            height: 36
            radius: 6
            color: btPopup.powered ? Style.backgroundAlt : Style.background

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "\uf293  Bluetooth"
                    color: Style.primary
                    font.family: Style.fontFamily
                    font.pointSize: Style.fontSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: parent.width - 170; height: 1 }

                Text {
                    text: btPopup.powered ? "on" : "off"
                    color: btPopup.powered ? Style.secondary : Style.alert
                    font.family: Style.fontFamily
                    font.pointSize: Style.fontSize
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    btPopup.run(["bluetoothctl", "power", btPopup.powered ? "off" : "on"])
                    btPopup.powered = !btPopup.powered
                    btPopup.refresh()
                }
            }
        }

        Text {
            anchors.top: parent.top
            anchors.topMargin: 56
            anchors.left: parent.left
            anchors.leftMargin: 14
            text: "Devices"
            color: Style.foregroundAlt
            font.family: Style.fontFamily
            font.pointSize: 9
        }

        Text {
            anchors.top: parent.top
            anchors.topMargin: 130
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            text: btPopup.scanMessage
            visible: btPopup.scanMessage !== ""
            color: Style.alert
            font.family: Style.fontFamily
            font.pointSize: Style.fontSize
            wrapMode: Text.Wrap
        }

        ListView {
            id: devList
            anchors.top: parent.top
            anchors.topMargin: 74
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
            anchors.margins: 8
            model: btPopup.devices
            clip: true
            spacing: 2

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: devList.width
                height: 36
                radius: 5
                color: index === devList.currentIndex ? Style.backgroundAlt : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: modelData.connected ? "\uf0a1" : "\uf293"
                        color: modelData.connected ? Style.secondary : Style.primary
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        width: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.name
                        color: index === devList.currentIndex ? Style.primary : Style.foreground
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        elide: Text.ElideRight
                        width: parent.width - 110
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.connected ? "connected" : (modelData.paired ? "paired" : "new")
                        color: modelData.connected ? Style.secondary : Style.foregroundAlt
                        font.family: Style.fontFamily
                        font.pointSize: Style.fontSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: devList.currentIndex = index
                    onClicked: btPopup.connectTo(index)
                }
            }
        }

        // bottom: add new device / scan
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            height: 36
            radius: 6
            color: Style.backgroundAlt

            Text {
                anchors.centerIn: parent
                text: btPopup.scanning ? "\uf002  Scanning..." : "\uf067  Add new device"
                color: Style.primary
                font.family: Style.fontFamily
                font.pointSize: Style.fontSize
            }

            MouseArea {
                anchors.fill: parent
                onClicked: btPopup.scan()
            }
        }

        function toggle() {
            btPopup.visible = !btPopup.visible
            if (btPopup.visible) {
                btPopup.run(["bluetoothctl", "agent", "on"])
                btPopup.run(["bluetoothctl", "default-agent"])
                refresh()
            }
        }

        function refresh() {
            powerProc.running = true
            devProc.running = true
        }

        Process {
            id: powerProc
            command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: () => btPopup.powered = text.trim() === "yes"
            }
        }

        Process {
            id: devProc
            command: ["sh", "-c",
                "bluetoothctl devices Paired | while read -r _ mac rest; do name=$rest; connected=$(bluetoothctl info $mac | grep -c 'Connected: yes'); echo \"$name|$mac|$connected\"; done"]
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: () => {
                    const arr = []
                    for (const line of text.trim().split("\n")) {
                        const parts = line.split("|")
                        if (parts.length >= 3) {
                            arr.push({ name: parts[0], mac: parts[1], connected: parts[2] === "1", paired: true })
                        }
                    }
                    btPopup.devices = arr
                    devList.currentIndex = 0
                }
            }
        }

        Process { id: actionRunner }
        function run(cmd) {
            actionRunner.command = cmd
            actionRunner.startDetached()
        }

        function connectTo(index) {
            const dev = btPopup.devices[index]
            if (!dev) return
            btPopup.visible = false
            if (dev.connected) {
                root.run(["bluetoothctl", "disconnect", dev.mac])
                root.run(["notify-send", "Bluetooth", "Disconnected " + dev.name])
                return
            }
            // pair only if unpaired (pair+connect on paired devices leaves
            // bluetoothd busy -> org.bluez.Error.InProgress); connect with feedback
            const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', btPopup, "btConn")
            const col = Qt.createQmlObject('import Quickshell.Io; StdioCollector { waitForEnd: true }', proc, "btConnCol")
            proc.stdout = col
            const pairStep = dev.paired ? "" : "bluetoothctl pair " + dev.mac + " 2>&1; sleep 1; "
            proc.command = ["sh", "-c", pairStep + "bluetoothctl connect " + dev.mac + " 2>&1"]
            col.streamFinished.connect(() => {
                const out = col.text.trim()
                if (out.indexOf("Connected: yes") !== -1 || out.indexOf("Connection successful") !== -1) {
                    root.run(["notify-send", "Bluetooth", "Connected " + dev.name])
                } else if (out.indexOf("Failed to pair") !== -1) {
                    root.run(["notify-send", "Bluetooth", "Pairing failed for " + dev.name])
                } else {
                    root.run(["notify-send", "Bluetooth", dev.name + ": " + out.split("\n").pop()])
                }
                col.destroy()
                proc.destroy()
            })
            proc.running = true
        }

        property bool scanning: false
        property string scanMessage: ""
        function scan() {
            btPopup.scanning = true
            btPopup.scanMessage = ""
            scanProc.running = true
        }

        Process {
            id: scanProc
            command: ["sh", "-c", "bluetoothctl --timeout 8 scan on 2>&1 | perl -pe 's/\\e\\[[0-9;]*[a-zA-Z]//g' | grep -E '^\\[NEW\\] Device ' | sed 's/^\\[NEW\\] Device //' | awk '{mac=$1; $1=\"\"; sub(/^ +/, \"\"); print mac\"|\"$0}' | sort -u"]
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: () => {
                    const arr = []
                    for (const line of text.trim().split("\n")) {
                        const parts = line.split("|")
                        if (parts.length >= 2 && parts[0].indexOf(":") !== -1) {
                            arr.push({ name: parts[1] || parts[0], mac: parts[0], connected: false, paired: false })
                        }
                    }
                    btPopup.found = arr
                    btPopup.devices = arr
                    btPopup.scanning = false
                    btPopup.scanMessage = arr.length ? "" : "No devices found — make sure the device is in pairing mode"
                }
            }
        }
    }
}
