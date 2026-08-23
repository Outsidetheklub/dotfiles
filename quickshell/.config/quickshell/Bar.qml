import Quickshell
import Quickshell.X11
import QtQuick
import "style.js" as Style
import "."

// Faithful port of polybar main/second bars, driven by Quickshell on X11.
// Layout mirrors polybar: left = i3 workspaces + window title,
// center = date, right = volume bluetooth ram network battery power.
XPanelWindow {
    id: root

    // true for the screen at x=0 (polybar's "main" bar, the only one with a tray)
    property bool isPrimary: screen !== null && screen.x === 0

    anchors.left: true
    anchors.right: true
    anchors.top: true
    exclusiveZone: Style.barHeight
    implicitHeight: Style.barHeight
    aboveWindows: true

    Rectangle {
        anchors.fill: parent
        color: Style.background
    }

    // ── left: workspaces + window title ──────────────────────────────
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 8

        Workspaces {
            height: parent.height
            screenName: root.screen ? root.screen.name : ""
        }
        WindowTitle { height: parent.height }
    }

    // ── center: date (fixed-center like polybar) ─────────────────────
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height

        DateModule { height: parent.height }
    }

    // ── right: modules (polybar order, module-margin-right = 1) ──────
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        rightPadding: 2
        spacing: 1

        Volume { height: parent.height }
        Bluetooth { height: parent.height }
        Ram { height: parent.height }
        Network { height: parent.height }
        Battery { height: parent.height; screenInfo: root.screen }
        Power { height: parent.height; screenInfo: root.screen }
    }
}
