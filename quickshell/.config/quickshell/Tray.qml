import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "style.js" as Style

// System tray — StatusNotifier (SNI) icons.
// Replaces polybar's tray (which only existed on the main bar).
Item {
    id: root
    implicitWidth: trayRow.childrenRect.width + 4
    height: parent.height
    property var hostWindow: null  // set by Bar.qml (the XPanelWindow)

    Row {
        id: trayRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData
                required property int index
                width: 22
                height: root.height

                Image {
                    anchors.centerIn: parent
                    source: modelData.icon
                    sourceSize.width: 18
                    sourceSize.height: 18
                    asynchronous: true
                }

                ToolTip {
                    visible: trayArea.containsMouse && modelData.tooltipTitle !== ""
                    delay: 500
                    text: modelData.tooltipTitle + (modelData.tooltipDescription !== "" ? "\n" + modelData.tooltipDescription : "")
                }

                MouseArea {
                    id: trayArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            // display() wants WINDOW-relative coords (it maps to global itself)
                            const pos = trayArea.mapToItem(root.hostWindow.contentItem, mouse.x, mouse.y)
                            modelData.display(root.hostWindow, pos.x, pos.y)
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else {
                            modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
