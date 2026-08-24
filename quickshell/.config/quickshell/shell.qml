//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "."

// The primary bar doubles as the config root: it's a dock-type panel that's
// always visible and NEVER takes keyboard focus, so child windows (launcher,
// notifications, popups) can map without a focus-stealing host window.
Bar {
    screen: Quickshell.screens[0]

    // bars for the remaining screens (screen 0 is the primary bar above;
    // skip it here — a hidden duplicate bar would double every module,
    // its popups and IPC handlers)
    Instantiator {
        model: Quickshell.screens.filter(s => s.x !== 0)
        delegate: Bar {
            screen: modelData
        }
    }

    // App launcher (rofi replacement)
    Launcher {}

    // Notification daemon UI (dunst replacement)
    Notifications {}

    // Power menu (shared: bar button + $mod+escape)
    PowerMenu {}

    // Clipboard history picker (greenclip)
    Clipboard {}

    // Emoji picker
    Emoji {}

    // Calculator
    Calc {}
}
