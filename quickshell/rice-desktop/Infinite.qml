pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Infinite Desktop, as the shell sees it: where the canvas is (Hyprland writes ~/.config/rice/infinite.state when
// it settles) and, live, how it moves while you hold SUPER + ALT (rice-canvasd tells it over a small socket, one
// line per step: "hold 1", "pan DX DY", "hold 0"). The moving wallpaper (WallCanvas) and the bar and dock that get
// out of the way while you move (Settings > Desktop > Infinite Desktop) follow it.
Singleton {
    id: cv
    // infinite.state
    property bool on: false
    property int ws: -1
    property real ox: 0
    property real oy: 0
    property real zoom: 1
    // infinite.conf: the wallpaper moves with the canvas (wall=1), the bar and the dock hide while it moves (hidebar=1)
    property bool wallOn: true
    property bool hideBarOn: true
    // live
    property bool held: false
    property bool moved: false           // this hold moved the canvas
    property bool live: false            // the last change came from a hold (short smoothing), not from a glide
    readonly property bool here: Wm.hypr && on && Wm.focusedId === ws
    readonly property bool moving: here && held && moved
    // the bar and the dock go while you move it, and come back a moment after you let go
    property bool hideUi: false
    onMovingChanged: if (moving) { backT.stop(); hideUi = hideBarOn } else backT.restart()
    Timer { id: backT; interval: 260; onTriggered: cv.hideUi = false }

    function msg(line) {
        const p = String(line).trim().split(/\s+/)
        if (p[0] === "hold") {
            held = p[1] === "1"
            if (held) moved = false
        } else if (p[0] === "pan" && p.length >= 3) {
            const dx = Number(p[1]), dy = Number(p[2])
            if (!isFinite(dx) || !isFinite(dy) || !here) return
            live = true
            ox += dx; oy += dy
            if (held) moved = true
        }
    }

    function parseState(t) {
        const g = k => { const m = t.match(new RegExp("^" + k + "=(.*)$", "m")); return m ? m[1].trim() : "" }
        on = g("on") === "1"
        const w = parseInt(g("ws")); ws = isNaN(w) ? -1 : w
        const nz = parseFloat(g("z")); zoom = isNaN(nz) ? 1 : nz
        const nx = parseFloat(g("ox")), ny = parseFloat(g("oy"))
        // a settled place from Hyprland: glide to it (unless a hold is still going on, then it is the same place)
        if (!held) live = false
        ox = isNaN(nx) ? 0 : nx; oy = isNaN(ny) ? 0 : ny
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/infinite.state"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: cv.parseState(text())
        onLoadFailed: { cv.on = false }
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/infinite.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const t = text()
            const g = (k, d) => { const m = t.match(new RegExp("^\\s*" + k + "\\s*=\\s*(\\S+)", "m")); return m ? m[1] : d }
            cv.wallOn = g("wall", "1") !== "0"
            cv.hideBarOn = g("hidebar", "1") !== "0"
        }
        onLoadFailed: { cv.wallOn = true; cv.hideBarOn = true }
    }

    // the socket rice-canvasd writes to. Made on the fly: a Quickshell without SocketServer only loses the live
    // part (the wallpaper then moves when you let go, and the bar stays)
    readonly property string sock: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/rice-canvas.sock"
    property var server: null
    Process {
        id: clean
        // a socket file left from the last start would keep the new one from listening
        command: ["rm", "-f", cv.sock]
        running: Wm.hypr
        onExited: {
            try {
                cv.server = Qt.createQmlObject('import Quickshell.Io\nSocketServer { id: srv; property var target; active: true; path: "' + cv.sock
                    + '"; handler: Socket { parser: SplitParser { onRead: function(l) { srv.target.msg(l) } } } }', cv, "canvassock")
                cv.server.target = cv
            } catch (e) { cv.server = null }
        }
    }
}
