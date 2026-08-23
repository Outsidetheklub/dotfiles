import Quickshell
import Quickshell.I3._Ipc
import Quickshell.Io
import QtQuick
import "style.js" as Style

// i3 workspace buttons, polybar internal/i3 styling:
// focused  = primary bg + background fg
// urgent   = alert fg
// visible  = foreground fg (active on another output)
// unfocused = foreground-alt fg
Row {
    id: root
    property string screenName: ""
    spacing: 5

    Repeater {
        model: I3.workspaces
        delegate: Rectangle {
            required property var modelData
            visible: modelData.monitor !== null && modelData.monitor.name === root.screenName
            height: root.height
            width: wsText.implicitWidth + 12

            color: modelData.focused ? Style.primary : "transparent"

            Text {
                id: wsText
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.focused ? Style.background
                     : modelData.urgent ? Style.alert
                     : "#ffffff"
                font.family: Style.fontFamily
                font.pointSize: Style.moduleFontSize
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.switchTo(modelData.num)
            }
        }
    }

    Process {
        id: switcher
        command: ["i3-msg", "workspace", "number", "1"]
    }

    function switchTo(num) {
        switcher.command = ["i3-msg", "workspace", "number", String(num)]
        switcher.startDetached()
    }
}
