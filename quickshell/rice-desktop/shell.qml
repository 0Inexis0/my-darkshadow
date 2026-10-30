import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root
    property var cfg: ({ widgets: {}, clock: {}, dock: {}, lock: {} })
    property string cfgText: ""
    property string wallpaper: ""
    property bool locked: false
    readonly property string home: Quickshell.env("HOME")
    readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property int sw: scr ? scr.width : 1920
    readonly property int sh: scr ? scr.height : 1080
    readonly property string placement: cfg.clock && cfg.clock.placement ? cfg.clock.placement : "draggable"

    function wc(id) { return cfg.widgets && cfg.widgets[id] ? cfg.widgets[id] : ({}) }
    function on(id) { return wc(id).enabled === true }
    function savePos(id, x, y) {
        Quickshell.execDetached([home + "/.local/bin/desktop-set", "pos", id, String(x), String(y)])
    }

    Process {
        id: cfgProc
        command: ["bash", "-c", "cat \"$HOME/.config/rice/desktop.json\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0 || text === root.cfgText) return
                try {
                    const j = JSON.parse(text)
                    root.cfgText = text
                    root.cfg = j
                } catch (e) { }
            }
        }
    }
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: { if (!cfgProc.running) cfgProc.running = true }
    }

    property string barPos: "top"
    property int barH: 44
    Process {
        id: barProc
        command: ["bash", "-c", "cat \"$HOME/.config/waybar/config.jsonc\" 2>/dev/null; echo '@@SPLIT@@'; cat \"$HOME/.config/waybar/ui.json\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("@@SPLIT@@")
                let base = 34
                let pad = 4
                let extra = 0
                try {
                    const c = JSON.parse(p[0])
                    root.barPos = c.position === "bottom" ? "bottom" : "top"
                    if (c.height) base = c.height
                } catch (e) { }
                try {
                    const u = JSON.parse(p[1])
                    if (u.height !== undefined && u.height !== null) pad = u.height
                    if (u.style === "floating") extra = 12
                    if (u.style === "islands") extra = 8
                } catch (e) { }
                root.barH = base + 2 * pad + extra
            }
        }
    }
    Timer {
        interval: 3000
        running: root.on("visualizer")
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!barProc.running) barProc.running = true }
    }

    Process {
        id: wpProc
        command: ["bash", "-c", "awww query 2>/dev/null | grep -o 'image: .*' | head -1 | sed 's/^image: //'"]
        stdout: StdioCollector { onStreamFinished: root.wallpaper = text.trim() }
    }
    Timer {
        interval: 6000
        running: !!(root.placement !== "draggable" && root.cfg.clock && root.cfg.clock.enabled === true)
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!wpProc.running) wpProc.running = true }
    }

    Process {
        id: lockProc
        command: ["bash", "-c", "pgrep -x hyprlock >/dev/null && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.locked = text.trim() === "1" }
    }
    Timer {
        interval: 2000
        running: !!(root.cfg.clock && root.cfg.clock.onlyLocked === true)
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!lockProc.running) lockProc.running = true }
    }

    // ---- clock
    WidgetWindow {
        id: clockWin
        wid: "clock"
        wc: root.placement === "draggable" ? (root.cfg.clock ? root.cfg.clock : ({})) : ({})
        draggable: root.placement === "draggable"
        active: !!(root.cfg.clock && root.cfg.clock.enabled === true && (root.cfg.clock.onlyLocked !== true || root.locked))
        bw: root.sw
        bh: root.sh
        cw: clk.natW
        ch: clk.natH
        defX: root.placement === "draggable" || clk.fx < 0 ? 40 : Math.round(Math.max(30, Math.min(root.sw - cw - 30, clk.fx * root.sw - cw / 2)))
        defY: root.placement === "draggable" || clk.fy < 0 ? 40 : Math.round(Math.max(60, Math.min(root.sh - ch - 30, clk.fy * root.sh - ch / 2)))
        onMoved: function(id, x, y) { root.savePos(id, x, y) }
        ClockWidget {
            id: clk
            anchors.fill: parent
            clockStyle: root.cfg.clock && root.cfg.clock.style ? root.cfg.clock.style : "digital"
            mode: root.placement
            wallpaper: root.wallpaper
            bw: root.sw
            bh: root.sh
        }
    }

    // ---- widgets
    WidgetWindow {
        wid: "weather"
        wc: root.wc("weather")
        active: root.on("weather")
        bw: root.sw
        bh: root.sh
        cw: 300
        ch: 120
        defX: 40
        defY: 370
        onMoved: function(id, x, y) { root.savePos(id, x, y) }
        WeatherWidget { anchors.fill: parent; running: root.on("weather") }
    }
    WidgetWindow {
        wid: "media"
        wc: root.wc("media")
        active: root.on("media")
        bw: root.sw
        bh: root.sh
        cw: 400
        ch: 120
        defX: root.sw - 440
        defY: 60
        onMoved: function(id, x, y) { root.savePos(id, x, y) }
        MediaWidget { anchors.fill: parent }
    }
    WidgetWindow {
        wid: "calendar"
        wc: root.wc("calendar")
        active: root.on("calendar")
        bw: root.sw
        bh: root.sh
        cw: 340
        ch: 340
        defX: root.sw - 380
        defY: 200
        onMoved: function(id, x, y) { root.savePos(id, x, y) }
        CalendarWidget { anchors.fill: parent }
    }
    WidgetWindow {
        wid: "usercard"
        wc: root.wc("usercard")
        active: root.on("usercard")
        bw: root.sw
        bh: root.sh
        cw: 340
        ch: 120
        defX: root.sw - 380
        defY: 560
        onMoved: function(id, x, y) { root.savePos(id, x, y) }
        UserCard { anchors.fill: parent }
    }
    WidgetWindow {
        wid: "resources"
        wc: root.wc("resources")
        active: root.on("resources")
        bw: root.sw
        bh: root.sh
        cw: 160
        ch: 380
        defX: 40
        defY: root.sh - 440
        onMoved: function(id, x, y) { root.savePos(id, x, y) }
        ResourcesWidget { anchors.fill: parent; running: root.on("resources") }
    }
    VizStrip { active: root.on("visualizer"); barPos: root.barPos; barH: root.barH }

    Dock { dc: root.cfg.dock ? root.cfg.dock : ({}) }

    // ---- hot corner (Settings > Hot corners)
    HotCorner { }

}
