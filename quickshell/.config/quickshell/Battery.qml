import Quickshell
import Quickshell.Io
import Quickshell.X11
import QtQuick
import "style.js" as Style

// Battery module. Completely hidden when no battery is present (desktop).
// On laptops: shows charge % + icon; click opens a power-mode picker
// (power saver / balanced / performance) via power-profiles-daemon.
Item {
    id: root

    property var screenInfo: null
    property bool hasBattery: false
    property string batteryName: ""
    property int capacity: 0
    property bool charging: false
    property bool ppdAvailable: false
    property string powerMode: ""
    property bool popupOpen: false

    visible: hasBattery
    implicitWidth: label.implicitWidth + 8
    height: parent.height

    readonly property string iconGlyph:
        root.charging ? "\uf0e7"
        : root.capacity >= 90 ? "\uf240"
        : root.capacity >= 60 ? "\uf241"
        : root.capacity >= 40 ? "\uf242"
        : root.capacity >= 20 ? "\uf243"
        : "\uf244"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.iconGlyph + " " + root.capacity + "%"
        color: (root.capacity <= 20 && !root.charging) ? Style.alert : Style.foreground
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.popupOpen = !root.popupOpen
            if (root.popupOpen) root.refresh()
        }
    }

    // ── detection + polling ────────────────────────────────────────────
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    function refresh() {
        detectProc.running = true
        if (root.hasBattery) readProc.running = true
        ppdProc.running = true
    }

    // find the battery device name (BAT0, BAT1, ...)
    Process {
        id: detectProc
        command: ["sh", "-c", "ls /sys/class/power_supply/ | grep -iE '^BAT[0-9]+$' | head -1"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const name = text.trim()
                root.hasBattery = name.length > 0
                root.batteryName = name
            }
        }
    }

    // read capacity + status
    Process {
        id: readProc
        command: ["sh", "-c",
            "cat /sys/class/power_supply/" + root.batteryName +
            "/capacity /sys/class/power_supply/" + root.batteryName +
            "/status 2>/dev/null"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const lines = text.trim().split("\n")
                root.capacity = parseInt(lines[0] || "0")
                root.charging = (lines[1] || "").indexOf("Charg") === 0
            }
        }
    }

    // power-profiles-daemon availability + current mode
    Process {
        id: ppdProc
        command: ["sh", "-c", "which powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get 2>/dev/null || echo __NOPPD__"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const out = text.trim()
                root.ppdAvailable = out.length > 0 && out !== "__NOPPD__"
                if (root.ppdAvailable) root.powerMode = out
            }
        }
    }

    Process { id: setProc }

    function setMode(mode) {
        setProc.command = ["powerprofilesctl", "set", mode]
        setProc.running = true
        root.powerMode = mode
    }

    // ── power mode popup ───────────────────────────────────────────────
    XPanelWindow {
        id: popup
        visible: root.popupOpen && root.hasBattery
        screen: root.screenInfo
        anchors.right: true
        anchors.top: true
        margins.top: Style.barHeight + 4
        exclusiveZone: 0
        implicitWidth: 216
        implicitHeight: 136

        Rectangle {
            anchors.fill: parent
            color: Style.backgroundAlt
            border.color: Style.disabled
            border.width: 1
            radius: 6

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 3

                Text {
                    text: "Power Mode"
                    color: Style.foregroundAlt
                    font.family: Style.fontFamily
                    font.pointSize: Style.smallFontSize
                }

                Repeater {
                    model: [
                        { icon: "\uf0e7", label: " Power Saver", mode: "power-saver" },
                        { icon: "\uf24e", label: " Balanced", mode: "balanced" },
                        { icon: "\uf135", label: " Performance", mode: "performance" },
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: popup.width - 12
                        height: 30
                        radius: 4
                        color: root.powerMode === modelData.mode ? Style.primary : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon + " " + modelData.label
                            color: root.powerMode === modelData.mode ? Style.background : Style.foreground
                            font.family: Style.fontFamily
                            font.pointSize: Style.fontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.ppdAvailable
                            onClicked: {
                                root.setMode(modelData.mode)
                                root.popupOpen = false
                            }
                        }
                    }
                }

                Text {
                    text: root.ppdAvailable ? "" : "power-profiles-daemon not found"
                    visible: !root.ppdAvailable
                    color: Style.disabled
                    font.family: Style.fontFamily
                    font.pointSize: Style.smallFontSize
                }
            }
        }
    }
}
