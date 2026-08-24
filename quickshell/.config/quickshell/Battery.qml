import Quickshell
import Quickshell.Io
import Quickshell.X11
import QtQuick
import QtQuick.Window as RealWindow
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
        font.pointSize: Style.moduleFontSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.hasBattery) return
            root.refresh()
            popup.toggle()
        }
    }

    // ── detection + polling ────────────────────────────────────────────
    // 5s poll as fallback; the udev watcher below handles plug/unplug
    // and capacity changes instantly.
    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    function refresh() {
        detectProc.running = true
        root.readBattery()
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
                // read immediately once we know the device name, otherwise
                // the module shows 0% from boot until the first timer tick
                if (root.hasBattery) root.readBattery()
            }
        }
    }

    // read capacity + status. The command is built per-run in readBattery():
    // batteryName is only known after async detection, so a static binding
    // would read /sys/class/power_supply//capacity (empty) at boot → 0%.
    Process {
        id: readProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const lines = text.trim().split("\n")
                root.capacity = parseInt(lines[0] || "0")
                root.charging = (lines[1] || "").indexOf("Charg") === 0
            }
        }
    }

    function readBattery() {
        if (!root.batteryName) return
        readProc.command = ["sh", "-c",
            "cat /sys/class/power_supply/" + root.batteryName +
            "/capacity /sys/class/power_supply/" + root.batteryName +
            "/status 2>/dev/null"]
        readProc.running = true
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

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    // ── instant charger/status events ──────────────────────────────────
    // udevadm monitor blocks until a power_supply uevent (plug/unplug,
    // charge status or capacity change); grep -m1 exits on the first
    // battery/AC event and onStreamFinished re-arms the watcher.
    Process {
        id: ueventProc
        command: ["sh", "-c",
            "udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep -m1 -E 'power_supply/(BAT|AC)'"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                root.readBattery()
                rearmTimer.start()
            }
        }
    }

    // re-arm guard: keeps us from busy-looping if udevadm is unavailable
    Timer {
        id: rearmTimer
        interval: 1500
        onTriggered: ueventProc.running = true
    }

    function setMode(mode) {
        setProc.command = ["powerprofilesctl", "set", mode]
        setProc.running = true
        root.powerMode = mode
    }

    // ── power mode popup ───────────────────────────────────────────────
    // A RealWindow + i3 floating rule (same pattern as PowerMenu.qml).
    // An XPanelWindow here gets TILED into the workspace layout by i3,
    // pushing other windows down; a floated RealWindow does not.
    RealWindow.Window {
        id: popup
        title: "Quickshell Battery"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        visible: false
        width: 216
        height: 136
        color: Style.backgroundAlt

        property var modes: [
            { icon: "\uf0e7", label: " Power Saver", mode: "power-saver" },
            { icon: "\uf24e", label: " Balanced", mode: "balanced" },
            { icon: "\uf135", label: " Performance", mode: "performance" },
        ]
        property int currentIndex: 0

        Rectangle {
            id: bg
            anchors.fill: parent
            color: Style.backgroundAlt
            border.color: Style.disabled
            border.width: 1
            radius: 6
            focus: true
            Keys.onUpPressed: popup.currentIndex = (popup.currentIndex + 2) % 3
            Keys.onDownPressed: popup.currentIndex = (popup.currentIndex + 1) % 3
            Keys.onReturnPressed: popup.selectCurrent()
            Keys.onEscapePressed: popup.hide()

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
                    model: popup.modes

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: popup.width - 12
                        height: 30
                        radius: 4
                        color: index === popup.currentIndex ? Style.background : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: (root.powerMode === modelData.mode ? "\uf00c " : "") + modelData.icon + " " + modelData.label
                            color: index === popup.currentIndex ? Style.primary : Style.foreground
                            font.family: Style.fontFamily
                            font.pointSize: Style.fontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: popup.currentIndex = index
                            enabled: root.ppdAvailable
                            onClicked: {
                                root.setMode(modelData.mode)
                                popup.hide()
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

        // position BEFORE mapping: i3 honors the requested position for
        // floating windows, but ignores position changes made after map
        function toggle() {
            if (root.popupOpen) { popup.hide(); return }
            // mapToGlobal gives the module's true screen position:
            // root.x is row-relative inside the right-aligned bar Row
            const g = root.mapToGlobal(root.width, 0)
            popup.x = g.x - popup.width - 4
            popup.y = g.y + Style.barHeight + 4
            root.popupOpen = true
            popup.currentIndex = 0
            popup.visible = true
            moveTimer.tries = 0
            moveTimer.start()
            bg.forceActiveFocus()
            popup.requestActivate()
        }

        function hide() {
            root.popupOpen = false
            popup.visible = false
            moveTimer.stop()
        }

        function selectCurrent() {
            const m = popup.modes[popup.currentIndex]
            if (m && root.ppdAvailable) {
                root.setMode(m.mode)
                popup.hide()
            }
        }

        IpcHandler {
            target: "battery"
            function toggle(): void {
                popup.toggle()
            }
        }

        // i3 can still race us at map time, so keep nudging the window
        // into place for a few hundred ms until it sticks
        Timer {
            id: moveTimer
            interval: 50
            repeat: true
            property int tries: 0
            onTriggered: {
                root.run(["i3-msg", "[title=\"Quickshell Battery\"]", "move", "position", String(popup.x), String(popup.y)])
                if (++moveTimer.tries >= 8) moveTimer.stop()
            }
        }
    }
}
