import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Window as RealWindow
import "style.js" as Style

// Power menu popup — shared by the bar power button and $mod+escape.
// Toggle from anywhere:  qs ipc call power toggle [screenRightEdge]
RealWindow.Window {
    id: root
    title: "Quickshell Power"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    x: 1706
    y: 32
    width: 210
    height: 5 * 38 + 14
    color: Style.backgroundAlt

    // opaque background (quickshell windows are transparent)
    Rectangle {
        id: bg
        anchors.fill: parent
        color: Style.backgroundAlt
        radius: 8
        border.color: Style.disabled
        border.width: 1
        focus: true
        Keys.onUpPressed: root.currentIndex = (root.currentIndex + 4) % 5
        Keys.onDownPressed: root.currentIndex = (root.currentIndex + 1) % 5
        Keys.onReturnPressed: {
            const item = rep.model[root.currentIndex]
            if (item) {
                root.run(["sh", "-c", item.cmd])
                root.visible = false
            }
        }
        Keys.onEscapePressed: root.visible = false
    }

    property int currentIndex: 0

    Column {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 2

        Repeater {
            id: rep
            model: [
                { icon: "\uf2dc", label: " Shutdown", cmd: "systemctl poweroff" },
                { icon: "\uf021", label: " Reboot", cmd: "systemctl reboot" },
                { icon: "\uf2f5", label: " Logout", cmd: "i3-msg exit" },
                { icon: "\uf023", label: " Lock", cmd: "i3lock" },
                { icon: "\uf186", label: " Sleep", cmd: "systemctl suspend" },
            ]

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: root.width - 14
                height: 36
                radius: 5
                color: index === root.currentIndex ? Style.background : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon + " " + modelData.label
                    color: index === root.currentIndex ? Style.primary : Style.foreground
                    font.family: Style.fontFamily
                    font.pointSize: Style.fontSize
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.currentIndex = index
                    onClicked: {
                        root.run(["sh", "-c", modelData.cmd])
                        root.visible = false
                    }
                }
            }
        }
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    // no-arg IPC entry: popup on the primary screen (used by $mod+escape)
    function toggle(): void {
        root.showAt(Screen.width, 0)
    }

    // IPC entry with the screen's right edge + top (used by the bar power buttons)
    function toggleAt(rightEdge: string, screenTop: string): void {
        root.showAt(parseInt(rightEdge), parseInt(screenTop))
    }

    function showAt(edge, top) {
        root.visible = !root.visible
        if (root.visible) {
            root.x = edge - root.width - 4
            root.y = top + Style.barHeight + 4
            root.currentIndex = 0
            moveTimer.start()
            bg.forceActiveFocus()
            root.requestActivate()
        }
    }

    Timer {
        id: moveTimer
        interval: 50
        onTriggered: {
            const edge = root.x + root.width + 4
            root.run(["i3-msg", "[title=\"Quickshell Power\"]", "move", "position", String(root.x), String(root.y)])
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            root.toggle()
        }
        function toggleAt(rightEdge: string, screenTop: string): void {
            root.toggleAt(rightEdge, screenTop)
        }
    }
}
