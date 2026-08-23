import Quickshell
import Quickshell.I3._Ipc
import Quickshell.Io
import QtQuick
import "style.js" as Style

// Focused window title (polybar internal/xwindow, maxlen ~60 chars).
// Pulls from the i3 tree on startup and on window focus/title events.
Item {
    id: root
    property string title: ""
    implicitWidth: Math.min(titleLabel.implicitWidth, 420)
    height: parent.height

    Text {
        id: titleLabel
        text: root.title
        color: Style.foregroundAlt
        font.family: Style.fontFamily
        font.pointSize: Style.moduleFontSize
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 420)
        anchors.verticalCenter: parent.verticalCenter
    }

    I3IpcListener {
        subscriptions: ["window"]
        onIpcEvent: (event) => {
            try {
                const d = JSON.parse(event.data)
                if (d.change === "focus" || d.change === "title" ||
                    d.change === "close" || d.change === "new") {
                    root.query()
                }
            } catch (e) { /* ignore malformed events */ }
        }
    }

    Process {
        id: queryProc
        command: ["sh", "-c",
            "i3-msg -t get_tree | jq -r '.. | objects | select(.focused == true and .window != null and .name != null) | .name' | head -1"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => root.title = text.trim()
        }
    }

    function query() {
        queryProc.running = true
    }
}
