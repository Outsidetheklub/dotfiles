import Quickshell
import Quickshell.I3._Ipc
import Quickshell.Io
import QtQuick
import "style.js" as Style

// i3 mode indicator — polybar's internal/i3 <label-mode> port.
// Shows the active i3 mode (e.g. "resize" during $mod+r) right after
// the workspaces, exactly where polybar used to display it.
// Hidden when mode is "default".
Item {
    id: root
    property string mode: "default"
    visible: mode !== "default"
    height: parent.height
    implicitWidth: modeLabel.implicitWidth + 12

    Rectangle {
        anchors.fill: parent
        color: Style.primary
    }

    Text {
        id: modeLabel
        anchors.centerIn: parent
        text: root.mode
        color: Style.background
        font.family: Style.fontFamily
        font.pointSize: Style.moduleFontSize
    }

    I3IpcListener {
        subscriptions: ["mode"]
        onIpcEvent: (event) => {
            try {
                const d = JSON.parse(event.data)
                root.mode = d.change || "default"
            } catch (e) { /* ignore malformed events */ }
        }
    }
}
