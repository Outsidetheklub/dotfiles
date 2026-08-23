import QtQuick
import "style.js" as Style

// polybar internal/date: "%a %d %b %H:%M", click toggles "%Y-%m-%d %H:%M:%S"
Item {
    id: root
    property bool alt: false
    property string display: ""
    implicitWidth: label.implicitWidth
    height: parent.height

    Text {
        id: label
        anchors.centerIn: parent
        text: root.display
        color: Style.foreground
        font.family: Style.fontFamily
        font.pointSize: Style.moduleFontSize
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.update()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.alt = !root.alt
    }

    function update() {
        const d = new Date()
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        const p2 = (n) => String(n).padStart(2, "0")
        if (root.alt) {
            root.display = `${d.getFullYear()}-${p2(d.getMonth() + 1)}-${p2(d.getDate())} ${p2(d.getHours())}:${p2(d.getMinutes())}:${p2(d.getSeconds())}`
        } else {
            root.display = `${days[d.getDay()]} ${p2(d.getDate())} ${months[d.getMonth()]} ${p2(d.getHours())}:${p2(d.getMinutes())}`
        }
    }

    Component.onCompleted: update()
}
