import Quickshell
import Quickshell.Io
import QtQuick
import "style.js" as Style

// polybar volume: wpctl script every 1s
// left-click pavucontrol, right-click mute toggle, scroll ±5%
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
        command: ["sh", "-c", "~/.config/quickshell/scripts/volume.sh"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: () => root.text = text.trim()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: proc.running = true
    }

    Process {
        id: runner
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    }

    function run(cmd) {
        runner.command = cmd
        runner.startDetached()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
            else
                root.run(["pavucontrol"])
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0)
                root.run(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+"])
            else
                root.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
        }
    }
}
