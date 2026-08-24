import QtQuick
import QtQuick.Window as RealWindow
import Quickshell.Io
import "style.js" as Style

// App launcher — rofi drun replacement.
// Left panel (640px, full height), search box on top, filtered list below.
// Uses the REAL QtQuick.Window (quickshell's `Window` is a proxy that paints white).
// i3 rule floats it:  for_window [title="Quickshell Launcher"] floating enable
// Toggle from i3:     qs ipc call launcher toggle
RealWindow.Window {
    id: root
    title: "Quickshell Launcher"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    x: 0
    y: 0
    width: 640
    height: 1080
    color: "#232732"

    property var apps: []
    property var filtered: []
    property string query: ""

    // size + position BEFORE showing so i3 places it at the left edge
    function prepare() {
        root.width = 640
        root.height = Screen.height
        root.x = 0
        root.y = 0
    }

    onVisibleChanged: {
        // children may not exist yet on the first show — defer
        if (root.visible) initTimer.start()
    }

    Timer {
        id: initTimer
        interval: 60
        onTriggered: {
            searchInput.text = ""
            root.query = ""
            root.updateFilter()
            loader.running = true // re-scan .desktop files every open (new installs appear)
            searchInput.forceActiveFocus()
            // i3 centers floating windows on map; snap to the left edge after
            moveTimer.start()
        }
    }

    Timer {
        id: moveTimer
        interval: 50
        onTriggered: root.run(["i3-msg", "[title=\"Quickshell Launcher\"]", "move", "position", "0", "0"])
    }

    // opaque background — quickshell windows are transparent, window color doesn't paint
    Rectangle {
        anchors.fill: parent
        color: "#232732"
    }

    // ── search bar ─────────────────────────────────────────────────────
    Rectangle {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 46
        color: "#232732"

        Text {
            id: prompt
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002" // search icon
            color: Style.primary
            font.family: Style.fontFamily
            font.pointSize: Style.fontSize
        }

        TextInput {
            id: searchInput
            anchors.left: prompt.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Style.foreground
            font.family: Style.fontFamily
            font.pointSize: 11
            selectByMouse: true
            onTextChanged: { root.query = text; root.updateFilter() }

            Keys.onUpPressed: root.moveSelection(-1)
            Keys.onDownPressed: root.moveSelection(1)
            Keys.onReturnPressed: root.launch()
            Keys.onEscapePressed: root.hide()
        }
    }

    // ── app list ───────────────────────────────────────────────────────
    ListView {
        id: list
        anchors.top: searchBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        model: root.filtered
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 40
            color: list.currentIndex === index ? Style.backgroundAlt : "transparent"

            Image {
                id: iconImg
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                source: modelData.icon !== "" ? "file://" + modelData.icon : ""
                visible: modelData.icon !== ""
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: iconImg.visible ? 48 : 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.name
                color: list.currentIndex === index ? Style.primary : Style.foreground
                font.family: Style.fontFamily
                font.pointSize: Style.fontSize
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.currentIndex = index
                onClicked: {
                    list.currentIndex = index
                    root.launch()
                }
            }
        }
    }

    // ── data + logic ───────────────────────────────────────────────────
    Process {
        id: loader
        command: ["sh", "-c", "~/.config/quickshell/scripts/apps.py"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => {
                const arr = []
                for (const line of text.trim().split("\n")) {
                    const parts = line.split("\t")
                    if (parts.length >= 2 && parts[0].trim() !== "") {
                        arr.push({ name: parts[0], exec: parts[1], icon: parts[2] || "" })
                    }
                }
                root.apps = arr
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
        root.filtered = q === "" ? root.apps
            : root.apps.filter(a => a.name.toLowerCase().indexOf(q) !== -1)
        list.currentIndex = 0
    }

    function moveSelection(delta) {
        if (list.count === 0) return
        list.currentIndex = (list.currentIndex + delta + list.count) % list.count
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function launch() {
        const app = root.filtered[list.currentIndex]
        if (!app) return
        root.run(["sh", "-c", app.exec])
        root.hide()
    }

    function toggle() {
        if (!root.visible) root.prepare() // size+position must be set BEFORE showing
        root.visible = !root.visible
        if (root.visible) {
            root.requestActivate()
        }
    }

    function hide() {
        root.visible = false
    }

    IpcHandler {
        target: "launcher"
        function toggle() {
            root.toggle()
        }
    }
}
