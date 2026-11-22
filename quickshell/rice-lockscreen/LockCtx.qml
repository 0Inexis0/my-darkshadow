pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The lock screen's shared state (shell.qml: the password, PAM, the way out), for every screen's view.
Singleton {
    id: lc
    property var root: null
    // V4.98 Minimal mode (Settings > Look & Feel; rice-minimal): every corner square
    property bool sq: false
    property string frame: "double"
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/minimal.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const j = JSON.parse(text()); lc.sq = j.on === true; lc.frame = j.frame || "double" } catch (e) { lc.sq = false } }
        onLoadFailed: lc.sq = false
    }
}
