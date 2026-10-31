pragma Singleton
import Quickshell
import QtQuick

// How see-through the desktop widgets are. shell.qml fills this in from desktop.json and rice-effects.
Singleton {
    // blurred wallpaper behind the cards (Settings > Desktop > Widgets > Blur)
    property bool blur: true
    // no blur and no transparency at all (Settings > Services: Lite, or gaming mode)
    property bool flat: false
}
