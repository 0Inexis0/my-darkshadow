pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// App icons as plain picture files. Icons.get(name, fallback) gives "file://..." (or "" while it is still being
// looked up, or when there is none): use it in an Image or an IconImage instead of Quickshell.iconPath.
// Why: Quickshell.iconPath goes through Qt's icon theme engine, and with Qt 6.12 (NixOS) that engine crashed
// Quickshell on some icons (the bar, the dock and the widgets went down). Plain files never touch it.
// The lookups run in the background (iconfile.sh), several names at once, and each name only once.
Singleton {
    id: ic
    property var files: ({})          // name -> file ("" = none)
    property int rev: 0               // goes up when new files are known: bindings that use get() look again
    property var pending: []
    property var asked: ({})

    function get(n, fallback) {
        const r = ic.rev                // (makes the binding depend on new lookups)
        const p = one(n)
        if (p !== "") return p
        if (typeof fallback === "string" && fallback !== "") return one(fallback)
        return ""
    }
    // a tray icon or a menu icon: "image://icon/NAME" (Qt's theme engine) becomes the file; others stay as they are
    function src(u) {
        const r = ic.rev
        if (!u) return ""
        u = String(u)
        if (u.indexOf("image://icon/") !== 0) return u
        let n = u.substring(13)
        const q = n.indexOf("?")
        if (q >= 0) n = n.substring(0, q)
        try { n = decodeURIComponent(n) } catch (e) {}
        return one(n)
    }
    function one(n) {
        if (!n) return ""
        n = String(n)
        if (n.indexOf("file://") === 0) return n
        if (n.indexOf("://") > 0) return ""          // other providers: not ours to draw
        const f = ic.files[n]
        if (f !== undefined) return f !== "" ? "file://" + f : ""
        if (!ic.asked[n]) { ic.asked[n] = true; ic.pending.push(n); batch.restart() }
        return ""
    }
    Timer { id: batch; interval: 40; onTriggered: ic.next() }
    function next() {
        if (look.running || ic.pending.length === 0) return
        look.names = ic.pending.splice(0, 60)
        look.running = true
    }
    Process {
        id: look
        property var names: []
        command: ["bash", Quickshell.shellPath("iconfile.sh")].concat(names)
        stdout: StdioCollector {
            onStreamFinished: {
                const f = Object.assign({}, ic.files)
                text.split("\n").forEach(function(l) {
                    const i = l.indexOf("\t")
                    if (i > 0) f[l.substring(0, i)] = l.substring(i + 1).trim()
                })
                look.names.forEach(function(n) { if (f[n] === undefined) f[n] = "" })
                ic.files = f
                ic.rev++
                if (ic.pending.length > 0) batch.restart()
            }
        }
    }
}
