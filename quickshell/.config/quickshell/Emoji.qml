import QtQuick
import QtQuick.Window as RealWindow
import Quickshell.Io
import "style.js" as Style

// Emoji picker — rofi emoji replacement.
// Full Unicode emoji list (4973) with search-by-name.
// Toggle from i3:  qs ipc call emoji toggle
RealWindow.Window {
    id: root
    title: "Quickshell Emoji"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    x: 1356
    y: 32
    width: 560
    height: 400
    color: Style.background

    property var emojis: []
    property var filtered: []
    property string query: ""

    // opaque background (quickshell windows are transparent)
    Rectangle {
        anchors.fill: parent
        color: Style.background
        radius: 8
        border.color: Style.disabled
        border.width: 1
    }

    // ── header + search ────────────────────────────────────────────────
    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
        text: "\uf118  Emoji"
        color: Style.primary
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
    }

    Rectangle {
        id: searchBox
        anchors.top: parent.top
        anchors.topMargin: 36
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        height: 30
        radius: 6
        color: Style.backgroundAlt

        Text {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002"
            color: Style.foregroundAlt
            font.family: Style.fontFamily
            font.pointSize: Style.fontSize
        }

        TextInput {
            id: searchInput
            anchors.left: searchIcon.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: Style.foreground
            font.family: Style.fontFamily
            font.pointSize: Style.fontSize
            selectByMouse: true
            onTextChanged: { root.query = text; root.updateFilter() }
        }
    }

    // ── emoji grid ─────────────────────────────────────────────────────
    GridView {
        id: grid
        anchors.top: searchBox.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        cellWidth: 52
        cellHeight: 44
        model: root.filtered
        clip: true

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: 48
            height: 40
            radius: 6
            color: index === grid.currentIndex ? Style.backgroundAlt : "transparent"

            Text {
                anchors.centerIn: parent
                text: modelData.emoji
                font.pixelSize: 22
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: grid.currentIndex = index
                onClicked: root.copyEmoji(index)
            }
        }
    }

    // ── data + logic ───────────────────────────────────────────────────
    Process {
        id: loader
        command: ["sh", "-c", "~/.config/quickshell/scripts/emoji-gen.py"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const arr = []
                for (const line of text.trim().split("\n")) {
                    const parts = line.split("\t")
                    if (parts.length >= 2) {
                        arr.push({ emoji: parts[0], name: parts[1] })
                    }
                }
                root.emojis = arr
                root.updateFilter()
            }
        }
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    function updateFilter() {
        const q = root.query.trim().toLowerCase()
        root.filtered = q === "" ? root.emojis
            : root.emojis.filter(e => e.name.toLowerCase().indexOf(q) !== -1)
        grid.currentIndex = 0
    }

    function copyEmoji(index) {
        const entry = root.filtered[grid.currentIndex]
        if (!entry) return
        root.run(["sh", "-c", "printf '%s' " + JSON.stringify(entry.emoji) + " | xsel -b"])
        root.visible = false
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) {
            root.x = Screen.width - root.width - 4
            root.y = Style.barHeight + 4
            grid.currentIndex = 0
            moveTimer.start()
            initTimer.start()
        }
    }

    Timer {
        id: initTimer
        interval: 60
        onTriggered: {
            searchInput.text = ""
            root.query = ""
            root.updateFilter()
            searchInput.forceActiveFocus()
        }
    }

    Timer {
        id: moveTimer
        interval: 50
        onTriggered: root.run(["i3-msg", "[title=\"Quickshell Emoji\"]", "move", "position", String(Screen.width - root.width - 4), String(Style.barHeight + 4)])
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void {
            root.toggle()
        }
    }
}
