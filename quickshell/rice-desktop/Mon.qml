pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The screen the shell lives on: the bar, the island, the widgets, the dock, the menus (Settings > System > Screen >
// Main screen; ~/.config/rice/screens.json "main"). With no choice, or when that screen is not plugged in: the first.
Singleton {
    id: mon
    property string want: ""
    readonly property var screen: pick(Quickshell.screens, want)
    function pick(l, n) {
        if (!l || l.length === 0) return null
        if (n !== "") for (let i = 0; i < l.length; i++) if (l[i].name === n) return l[i]
        return l[0]
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/screens.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const j = JSON.parse(text()); mon.want = j.main || "" } catch (e) { mon.want = "" } }
        onLoadFailed: mon.want = ""
    }
}
