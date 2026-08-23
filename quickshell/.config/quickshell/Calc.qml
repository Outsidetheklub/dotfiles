import QtQuick
import QtQuick.Window as RealWindow
import Quickshell.Io
import "style.js" as Style

// Calculator — rofi calc replacement.
// Toggle from i3:  qs ipc call calc toggle
RealWindow.Window {
    id: root
    title: "Quickshell Calc"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    x: 1356
    y: 32
    width: 280
    height: 380
    color: Style.background

    Rectangle {
        anchors.fill: parent
        color: Style.background
        radius: 8
        border.color: Style.disabled
        border.width: 1
    }

    // display
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: 60
        radius: 6
        color: Style.backgroundAlt

        Text {
            id: display
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.display
            color: Style.foreground
            font.family: Style.fontFamily
            font.pointSize: 20
        }
    }

    Grid {
        id: calcGrid
        anchors.top: parent.top
        anchors.topMargin: 80
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        columns: 4
        spacing: 6

        Repeater {
            model: [
                { label: "C", fn: "clear", color: Style.alert },
                { label: "\u00f7", fn: "div", color: Style.primary },
                { label: "\u00d7", fn: "mul", color: Style.primary },
                { label: "\u232b", fn: "back", color: Style.foregroundAlt },
                { label: "7", fn: "d7" }, { label: "8", fn: "d8" }, { label: "9", fn: "d9" }, { label: "\u2212", fn: "sub", color: Style.primary },
                { label: "4", fn: "d4" }, { label: "5", fn: "d5" }, { label: "6", fn: "d6" }, { label: "+", fn: "add", color: Style.primary },
                { label: "1", fn: "d1" }, { label: "2", fn: "d2" }, { label: "3", fn: "d3" }, { label: "=", fn: "eq", color: Style.secondary },
                { label: "0", fn: "d0" }, { label: ".", fn: "dot" }, { label: "%", fn: "pct", color: Style.primary }, { label: "\u00b1", fn: "neg", color: Style.foregroundAlt },
            ]

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: (root.width - 20 - 18) / 4
                height: 48
                radius: 6
                color: modelData.color !== undefined ? (index === calcGrid.currentIndex ? Style.background : modelData.color + "40")
                     : (index === calcGrid.currentIndex ? Style.primary : Style.backgroundAlt)

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: modelData.color !== undefined && index !== calcGrid.currentIndex ? modelData.color : Style.foreground
                    font.family: Style.fontFamily
                    font.pointSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: calcGrid.currentIndex = index
                    onClicked: root.handle(modelData.fn)
                }
            }
        }
    }

    property int gridIndex: 0
    property string display: "0"
    property double acc: 0
    property string pendingOp: ""
    property bool fresh: true

    function handle(fn) {
        if (fn === "clear") { root.display = "0"; root.acc = 0; root.pendingOp = ""; root.fresh = true; return }
        if (fn === "back") { root.display = root.display.length > 1 ? root.display.slice(0, -1) : "0"; return }
        if (fn === "neg") { root.display = root.display.startsWith("-") ? root.display.slice(1) : "-" + root.display; return }
        if (fn === "pct") { root.display = String(parseFloat(root.display) / 100); return }
        if (fn === "dot") { if (root.fresh) { root.display = "0."; root.fresh = false } else if (root.display.indexOf(".") === -1) { root.display += "." }; return }
        if (fn.startsWith("d")) { const d = fn.slice(1); if (root.fresh) { root.display = d; root.fresh = false } else { root.display = root.display === "0" ? d : root.display + d }; return }
        // operators
        const val = parseFloat(root.display)
        if (root.pendingOp !== "" && !root.fresh) {
            root.acc = root.applyOp(root.acc, val, root.pendingOp)
        } else {
            root.acc = val
        }
        if (fn === "eq") {
            root.display = String(root.acc)
            root.pendingOp = ""
            root.fresh = true
        } else {
            root.pendingOp = fn
            root.fresh = true
        }
    }

    function applyOp(a, b, op) {
        switch (op) {
        case "add": return a + b
        case "sub": return a - b
        case "mul": return a * b
        case "div": return b === 0 ? 0 : a / b
        }
        return b
    }

    function toggle() {
        root.visible = !root.visible
        if (root.visible) {
            root.display = "0"
            root.acc = 0
            root.pendingOp = ""
            root.fresh = true
        }
    }

    IpcHandler {
        target: "calc"
        function toggle() {
            root.toggle()
        }
    }
}
