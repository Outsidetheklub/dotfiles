import Quickshell
import Quickshell.Io
import QtQuick
import "style.js" as Style

// polybar ram: script every 5s (no click action)
Item {
    id: root
    property string text: ""
    implicitWidth: label.implicitWidth + 8
    height: parent.height

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: "#ffffff"
        font.family: Style.fontFamily
        font.pointSize: Style.fontSize
    }

    Process {
        id: proc
        command: ["sh", "-c", "~/.config/quickshell/scripts/ram.sh"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => root.text = text.trim()
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }
}
