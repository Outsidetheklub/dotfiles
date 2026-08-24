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
        font.pointSize: Style.moduleFontSize
    }

    Process { id: runner }
    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // mapToGlobal: the module's true screen position (root.x is
            // row-relative inside the right-aligned bar Row), so the menu
            // floats right under the power button
            const g = root.mapToGlobal(root.width, 0)
            root.run(["qs", "ipc", "call", "power", "toggleAt", String(g.x), String(g.y)])
        }
    }
}
