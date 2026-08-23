import Quickshell
import Quickshell.Io
import QtQuick
import "style.js" as Style

// polybar power: button — opens the shared QS power menu (PowerMenu.qml)
Item {
    id: root
    property var screenInfo: null
    implicitWidth: label.implicitWidth + 8
    height: parent.height

    Text {
        id: label
        anchors.centerIn: parent
        text: "\uf011" // power icon
        color: "#ffffff"
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // tell the shared popup which screen's right edge to sit under
            const si = root.screenInfo
            if (si) {
                root.run(["qs", "ipc", "call", "power", "toggleAt", String(si.x + si.width), String(si.y)])
            } else {
                root.run(["qs", "ipc", "call", "power", "toggle"])
            }
        }
    }
}
