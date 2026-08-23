import QtQuick
import QtQuick.Window as RealWindow
import Quickshell.Io
import "style.js" as Style

// Clipboard history picker — reads the cliphist store (replaces greenclip).
// Toggle from i3:  qs ipc call clipboard toggle
RealWindow.Window {
    id: root
    title: "Quickshell Clipboard"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    width: 560
    height: 400
    color: Style.background

    property var entries: []
    property bool deleteMode: false
    property var loadCommand: ["sh", "-c", "cliphist list 2>/dev/null | head -30 | while IFS= read -r line; do id=$(printf '%s' \"$line\" | cut -f1); disp=$(printf '%s' \"$line\" | cliphist decode 2>/dev/null | tr '\\n' '\\302\\240'); printf '%s\\t%s\\n' \"$id\" \"$disp\"; done"]

    // opaque background (quickshell windows are transparent)
    Rectangle {
        anchors.fill: parent
        color: Style.background
        radius: 8
        border.color: Style.disabled
        border.width: 1
    }

    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
        text: root.deleteMode ? "\uf0ea  Delete — click entry to remove" : "\uf0ea  Clipboard"
        color: root.deleteMode ? Style.alert : Style.primary
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
    }

    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 14
        text: "\uf00d"
        visible: root.deleteMode
        color: Style.alert
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    ListView {
        id: list
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        model: root.entries
        clip: true
        spacing: 2

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 34
            radius: 5
            color: index === list.currentIndex ? Style.backgroundAlt : "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.text.replace(/\u00a0/g, "\n")
                color: index === list.currentIndex ? Style.primary : Style.foreground
                font.family: Style.fontFamily
                font.pointSize: Style.fontSize
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.currentIndex = index
                onClicked: root.deleteMode ? root.deleteEntry(index) : root.copyEntry(index)
            }
        }
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    function copyEntry(index) {
        const entry = root.entries[index]
        if (entry === undefined) return
        // cliphist entries are flattened to NBSP for list display — restore before copying
        const text = entry.text.replace(/\u00a0/g, "\n")
        root.run(["sh", "-c", "printf '%s' " + JSON.stringify(text) + " | xsel -b"])
        root.visible = false
    }

    function deleteEntry(index) {
        const entry = root.entries[index]
        if (entry === undefined) return
        // cliphist delete takes the entry id (bare id + newline works)
        root.run(["sh", "-c", "printf '%s\\n' " + JSON.stringify(entry.id) + " | cliphist delete"])
        refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 250
        onTriggered: {
            loader.command = root.loadCommand
            loader.running = true
        }
    }

    function toggle() {
        root.deleteMode = false
        root.show()
    }

    function showDeleteMode() {
        if (root.visible) {
            root.visible = false
            return
        }
        root.deleteMode = true
        if (!root.visible) {
            root.x = Screen.width - root.width - 4
            root.y = Style.barHeight + 4
            root.visible = true
            loadTimer.start()
            moveTimer.start()
        }
    }

    function show() {
        root.visible = !root.visible
        if (root.visible) {
            // position top-right below the bar
            root.x = Screen.width - root.width - 4
            root.y = Style.barHeight + 4
            loadTimer.start()
            moveTimer.start()
        }
    }

    Timer {
        id: loadTimer
        interval: 60
        onTriggered: {
            loader.command = root.loadCommand
            loader.running = true
        }
    }

    Process {
        id: loader
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const lines = text.trim().split("\n")
                root.entries = lines.filter(l => l.includes("\t")).map(l => {
                    const i = l.indexOf("\t")
                    return { id: l.slice(0, i), text: l.slice(i + 1) }
                })
                list.currentIndex = 0
            }
        }
    }

    Timer {
        id: moveTimer
        interval: 50
        onTriggered: root.run(["i3-msg", "[title=\"Quickshell Clipboard\"]", "move", "position", String(Screen.width - root.width - 4), String(Style.barHeight + 4)])
    }

    IpcHandler {
        target: "clipboard"
        function toggle() {
            root.toggle()
        }
        function remove() {
            root.deleteEntry(list.currentIndex)
        }
        function deleteMode() {
            root.showDeleteMode()
        }
    }
}
