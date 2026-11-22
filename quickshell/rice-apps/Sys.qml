pragma Singleton
import Quickshell
import QtQuick

// Runs the helper (rice-apps-helper) and other little commands for the apps.
Singleton {
    id: s
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/rice-apps-helper"
    property Component jobC: Component { Job { } }
    // run(["places"], function(json) {...}, function(progress) {...})
    function run(args, done, prog) {
        const j = jobC.createObject(s, { command: ["python3", helper].concat(args), done: done || null, prog: prog || null })
        j.running = true
        return j
    }
    function sh(script, args) { Quickshell.execDetached(["bash", "-c", script, "_"].concat(args || [])) }
    function open(path) { Quickshell.execDetached(["xdg-open", path]) }
    function app(name, paths) { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-app", name].concat(paths || [])) }
    // the prefs of an app (~/.config/rice/apps/NAME.json), written a moment after the last change
    function savePrefs(name, obj) { run(["prefs", name, "set", JSON.stringify(obj)]) }
}
