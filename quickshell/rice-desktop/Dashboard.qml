import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// The dashboard. It comes out of the bottom, top, left or right edge (Settings > Dashboard > Position).
// At the bottom and top the tabs run along the top of it, at the left and right they are a column on its left side.
// SUPER + ALT + D opens it, SUPER + W opens the wallpapers.
// Tabs: Dashboard, Wallpaper, Performance, About. Settings > Dashboard.
PanelWindow {
    id: db
    property var cfg: ({ enabled: false })
    property string cfgText: ""
    property bool open: false
    property string tab: "dashboard"
    property real t: 0
    property bool entered: false
    property bool byHover: false
    property bool armed: true
    property bool editing: false
    property bool typing: false
    property string lastCmd: ""
    property bool cmdSeen: false
    property var visited: ({})
    property var stats: ({})
    property var disks: []
    readonly property var disk: disks.length > 0 ? disks[0] : null
    property var about: ({})
    property var layouts: ({})
    property var grids: ({})
    property string toastText: ""
    // switches (Wi-Fi, Bluetooth, ...) and the to-do list: shared by the Dashboard, Control and Tasks tabs
    property var svc: ({})
    property var todos: []
    function svcRefresh() { if (!svcProc.running) svcProc.running = true }
    function svcToggle(k) {
        const n = Object.assign({}, svc); n[k] = !n[k]; svc = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-services\" toggle \"$1\"", "_", k])
        svcLater.restart()
    }
    function todoRefresh() { if (!todoProc.running) todoProc.running = true }
    function todoRun(args) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-todo\" \"$@\"", "_"].concat(args))
        todoLater.restart()
    }
    function todoToggle(i) {
        const n = todos.map(function(x, j) { return j === i ? { t: x.t, done: !x.done } : x }); todos = n
        todoRun(["toggle", String(i)])
    }
    function todoAdd(t) { t = String(t).trim(); if (t === "") return; todos = todos.concat([{ t: t, done: false }]); todoRun(["add", t]) }
    function todoRemove(i) { todos = todos.filter(function(x, j) { return j !== i }); todoRun(["remove", String(i)]) }
    function todoClear() { todos = todos.filter(function(x) { return !x.done }); todoRun(["clear"]) }
    Process {
        id: svcProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-services\" state 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { db.svc = JSON.parse(text) } catch (e) { } } }
    }
    Process {
        id: todoProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-todo\" list 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { db.todos = JSON.parse(text) } catch (e) { } } }
    }
    Timer { id: svcLater; interval: 1300; onTriggered: db.svcRefresh() }
    Timer { id: todoLater; interval: 900; onTriggered: db.todoRefresh() }
    Timer { interval: 6000; running: db.open; repeat: true; triggeredOnStart: true; onTriggered: { db.svcRefresh(); db.todoRefresh() } }

    readonly property var tabs: cfg.tabs && cfg.tabs.length ? cfg.tabs : ["dashboard", "control", "tasks", "wallpaper", "performance", "about"]
    readonly property int curIdx: Math.max(0, tabs.indexOf(tab))
    readonly property string pos: cfg.position === "top" || cfg.position === "left" || cfg.position === "right" ? cfg.position : "bottom"
    readonly property bool atTop: pos === "top"
    readonly property bool atLeft: pos === "left"
    readonly property bool atRight: pos === "right"
    readonly property bool side: atLeft || atRight       // floating in the middle of a side edge, tabs in a column
    readonly property real railW: side ? 124 : 0
    readonly property real sc: cfg.scale ? cfg.scale : 1
    readonly property real spd: cfg.speed ? cfg.speed : 1
    readonly property string anim: cfg.animation === "fade" || cfg.animation === "none" ? cfg.animation : "slide"
    readonly property bool attach: cfg.attach !== false && !side
    readonly property bool barHere: !side && !!cfg.bar && cfg.bar.position === (atTop ? "top" : "bottom") && !cfg.bar.autohide
    readonly property real barOff: barHere ? cfg.bar.height : 0
    readonly property real earR: attach ? 24 : 0
    readonly property real headH: 64
    readonly property real pad: 18
    readonly property real trayH: 0
    readonly property real baseW: cfg.width ? cfg.width : 1000
    // one size for every tab (the size of Performance), so switching tabs never resizes the panel
    // side positions: a tall panel, top to bottom of the screen, with the cards next to the tab column
    function tabW(t) { return side ? Math.min((db.width - 40) / sc - railW, baseW * 0.52) : Math.min((db.width - 40) / sc - 2 * earR, baseW * 1.04) }
    // the side panel is a compact one, floating in the middle of the edge (not the whole screen height)
    function tabH(t) { return side ? Math.min((db.height - 20) / sc, 860) - 2 * pad - 4 : 330 }
    readonly property real wantW: tabW(tab) + railW
    readonly property real wantH: (side ? 2 * pad + 4 : headH + pad) + tabH(tab)
    property real curW: wantW
    property real curH: wantH
    Behavior on curW { NumberAnimation { duration: 460 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
    Behavior on curH { NumberAnimation { duration: 460 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

    // ---------------- helpers for the tabs ----------------
    function md(cp) { return String.fromCodePoint(cp) }
    readonly property var glyphs: ({
        nixos: "", arch: "", archarm: "", cachyos: "", endeavouros: "", manjaro: "",
        garuda: "", ubuntu: "", fedora: "", nobara: "", bazzite: "", ultramarine: "", debian: "", opensuse: "", gentoo: "",
        void: "", alpine: "", linuxmint: "", pop: ""
    })
    function distroGlyph() {
        const di = about.distro || {}
        const ids = ((di.id || "") + " " + (di.like || "")).toLowerCase().split(/\s+/)
        for (let i = 0; i < ids.length; i++) if (glyphs[ids[i]] !== undefined) return glyphs[ids[i]]
        return ""
    }
    function greeting(d) {
        const h = d.getHours()
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"
    }
    function uptimeText(s) {
        s = Math.floor(s || 0)
        const dd = Math.floor(s / 86400), hh = Math.floor(s % 86400 / 3600), mm = Math.floor(s % 3600 / 60)
        return (dd ? dd + "d " : "") + (hh ? hh + "h " : "") + mm + "m"
    }
    function close() { open = false; editing = false }
    function show(which, hover) {
        tab = which && tabs.indexOf(which) >= 0 ? which : (cfg.default_tab && tabs.indexOf(cfg.default_tab) >= 0 ? cfg.default_tab : tabs[0])
        byHover = hover === true
        entered = false
        open = true
    }
    function loadAbout() { if (!aboutProc.running) aboutProc.running = true }
    function registerGrid(tabId, g) { const n = Object.assign({}, grids); n[tabId] = g; grids = n }
    function saveLayout(tabId, l) {
        const n = Object.assign({}, layouts); n[tabId] = l; layouts = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" layout \"$1\" \"$2\"", "_", tabId, JSON.stringify(l)])
    }
    function resetLayout(tabId) {
        const n = Object.assign({}, layouts); delete n[tabId]; layouts = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" reset-layout \"$1\"", "_", tabId])
    }
    function toast(m) { toastText = m; toastTimer.restart() }
    Timer { id: toastTimer; interval: 2400; onTriggered: db.toastText = "" }

    // ---------------- looks ----------------
    function hx(c) {
        const s = String(c).replace("#", "")
        return [parseInt(s.substr(0, 2), 16) / 255, parseInt(s.substr(2, 2), 16) / 255, parseInt(s.substr(4, 2), 16) / 255]
    }
    function mix(a, b, k, al) {
        const x = hx(a), y = hx(b)
        return Qt.rgba(x[0] * (1 - k) + y[0] * k, x[1] * (1 - k) + y[1] * k, x[2] * (1 - k) + y[2] * k, al === undefined ? 1 : al)
    }
    readonly property string acc: cfg.accent ? cfg.accent : "#9ec9bd"
    readonly property real op: cfg.opacity !== undefined ? cfg.opacity : 0.9
    // dark or light text on top of the wallpaper color
    function lum(c) { const x = hx(c); return 0.299 * x[0] + 0.587 * x[1] + 0.114 * x[2] }
    // the wallpaper color, made light enough to stand out on the dark blurred glass (a dark green wallpaper gives a
    // dark green accent that disappears on the blur otherwise)
    function vivid(c) {
        let k = 0
        while (k < 0.9 && lum(mixHex(c, "#ffffff", k)) < 0.6) k += 0.08
        return mixHex(c, "#ffffff", k)
    }
    function mixHex(a, b, k) {
        const x = hx(a), y = hx(b)
        const h = function(v) { const n = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16); return n.length < 2 ? "0" + n : n }
        return "#" + h(x[0] * (1 - k) + y[0] * k) + h(x[1] * (1 - k) + y[1] * k) + h(x[2] * (1 - k) + y[2] * k)
    }
    readonly property string accV: vivid(acc)
    readonly property string accFg: lum(accV) > 0.55 ? "#0d0d0d" : "#F6F5F4"
    readonly property var barRgb: cfg.bar && cfg.bar.rgb && (cfg.bar.rgb[0] + cfg.bar.rgb[1] + cfg.bar.rgb[2]) < 200 ? cfg.bar.rgb : [12, 12, 14]
    readonly property string style: cfg.style ? cfg.style : "shadow"
    readonly property var p: style === "graphite" ? ({
        // warm grey, soft and solid, your color as the accent
        bg: Qt.rgba(0.11, 0.11, 0.122, op), solidBg: "#1c1c1f", card: Qt.rgba(1, 1, 1, 0.055), card2: Qt.rgba(1, 1, 1, 0.085),
        text: "#ECECEE", sub: "#a8a8b0", primary: accV, inkOn: "#141416",
        container: mix(accV, "#2a2a2e", 0.62), onContainer: mix(accV, "#ffffff", 0.55),
        line: "transparent", track: Qt.rgba(1, 1, 1, 0.09), radius: 30, cardRadius: 22, tabStyle: "underline", dark: true, glow: false
    }) : style === "aurora" ? ({
        // deep and dark, tinted by your wallpaper colors, with a soft glow
        bg: mix(acc, "#06060a", 0.88, op), solidBg: mix(acc, "#06060a", 0.88), card: mix(acc, "#16161c", 0.8, 0.72), card2: mix(acc, "#1e1e26", 0.72, 0.8),
        text: "#EEEAF2", sub: "#b4afba", primary: accV, inkOn: mix(acc, "#000000", 0.85),
        container: mix(accV, "#16161c", 0.5), onContainer: mix(accV, "#ffffff", 0.7),
        line: Qt.rgba(1, 1, 1, 0.05), track: Qt.rgba(1, 1, 1, 0.09), radius: 34, cardRadius: 26, tabStyle: "pill", dark: true, glow: true
    }) : style === "frost" ? ({
        // light frosted glass
        bg: Qt.rgba(0.965, 0.965, 0.972, op), solidBg: "#f6f6f8", card: Qt.rgba(0, 0, 0, 0.045), card2: Qt.rgba(0, 0, 0, 0.07),
        text: "#18181b", sub: "#6b6b74", primary: "#18181b", inkOn: "#ffffff",
        container: Qt.rgba(0, 0, 0, 0.07), onContainer: "#18181b",
        line: Qt.rgba(0, 0, 0, 0.05), track: Qt.rgba(0, 0, 0, 0.08), radius: 30, cardRadius: 22, tabStyle: "segment", dark: false, glow: false
    }) : ({
        // Shadow: the color of your bar (black glass), details in your wallpaper color (like the hot corner)
        bg: Qt.rgba(barRgb[0] / 255, barRgb[1] / 255, barRgb[2] / 255, Math.max(op, 0.82)), solidBg: "#0c0c0e", card: Qt.rgba(1, 1, 1, 0.075), card2: Qt.rgba(1, 1, 1, 0.11),
        text: "#F6F5F4", sub: "#b0b0b8", primary: accV, inkOn: accFg,
        container: mix(accV, "#141416", 0.62), onContainer: mix(accV, "#ffffff", 0.45),
        line: Qt.rgba(1, 1, 1, 0.09), track: Qt.rgba(1, 1, 1, 0.16), radius: 28, cardRadius: 20, tabStyle: "segment", dark: true, glow: false
    })

    // ---------------- window ----------------
    visible: cfg.enabled === true
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-dashboard"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // closed: only a thin strip at the bottom edge takes the pointer (it opens the dashboard)
    mask: Region { item: (db.open || db.t > 0.02) ? whole : (db.edgeOn ? edge : nothing) }
    Item { id: whole; anchors.fill: parent }
    Item { id: nothing; width: 0; height: 0 }

    // ---------------- open by touching the bottom edge ----------------
    readonly property bool edgeOn: cfg.edge !== false
    Item {
        id: edge
        // the middle of the bottom edge, as wide as the dashboard; the corners stay free for the hot corner
        width: db.side ? 2 : Math.min(db.width - 360, (db.wantW + 2 * db.earR) * db.sc)
        height: db.side ? Math.min(db.height - 360, db.wantH * db.sc + 120) : 2
        x: db.atLeft ? 0 : (db.atRight ? db.width - width : (db.width - width) / 2)
        y: db.side ? (db.height - height) / 2 : (db.atTop ? 0 : db.height - height)
        HoverHandler {
            id: edgeHover
            enabled: db.edgeOn
            onHoveredChanged: {
                if (hovered) { if (!db.open) edgeTimer.restart() }
                else edgeTimer.stop()
                db.pointerMoved()
            }
        }
    }
    Timer {
        id: edgeTimer
        interval: Math.max(1, db.cfg.delay !== undefined ? db.cfg.delay : 150)
        onTriggered: if (!db.open && edgeHover.hovered) db.show("", true)
    }

    // wallpaper preview (Wallpaper tab): shown behind the desktop while you pick, dropped when you leave
    property string previewPath: ""
    property var wallsTab: null
    Timer { id: previewDone; interval: 1600; onTriggered: db.previewPath = "" }
    function keepPreview() { previewDone.restart() }

    NumberAnimation { id: tAnim; target: db; property: "t" }
    onOpenChanged: {
        tAnim.stop()
        tAnim.to = open ? 1 : 0
        tAnim.duration = db.anim === "none" ? 1 : (open ? 560 : 300) / spd
        tAnim.easing.type = Easing.BezierSpline
        tAnim.easing.bezierCurve = open ? [0.05, 0.7, 0.1, 1.0, 1, 1] : [0.3, 0.0, 0.8, 0.15, 1, 1]
        tAnim.start()
        if (open) {
            if (!fullProc.running) fullProc.running = true
            const v = Object.assign({}, visited); v[tab] = true; visited = v
            loadAbout()
            keys.forceActiveFocus()
        } else { leaveTimer.stop(); typing = false; if (!previewDone.running) previewPath = "" }
    }
    onTabChanged: { const v = Object.assign({}, visited); v[tab] = true; visited = v; if (tab === "wallpaper") editing = false }

    // ---------------- settings + open requests ----------------
    // a cheap look at two small files every 0.3 s; the full settings (with bar size and colors)
    // are read when the file changes and every time the dashboard opens
    property string rawCfg: "?"
    Process {
        id: fullProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" config 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim()
                if (c.length > 0 && c !== db.cfgText) {
                    try { db.cfg = JSON.parse(c); db.cfgText = c; db.layouts = db.cfg.layouts || {} } catch (e) { }
                }
            }
        }
    }
    Process {
        id: cfgProc
        // (gaming mode and "no blur & transparency" count as a change of the settings too)
        command: ["bash", "-c", "cat \"$HOME/.config/rice/dashboard.json\" 2>/dev/null; [ -e \"$HOME/.config/rice/gaming-on\" ] && echo G; [ -e \"$HOME/.cache/rice/flat\" ] && echo F"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text !== db.rawCfg) { db.rawCfg = text; if (!fullProc.running) fullProc.running = true }
            }
        }
    }
    // the settings file: read when it changes; the flags (gaming, flat) are looked at every few seconds
    Trigger { name: ""; path: Quickshell.env("HOME") + "/.config/rice/dashboard.json"; every: 4000
        onContent: function(t) { if (!cfgProc.running) cfgProc.running = true } }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!cfgProc.running) cfgProc.running = true }
    // open requests (rice-dashboard open / the bar's clock / the hot edge)
    Trigger {
        name: "dashboard-open"
        onFired: function(o) {
            const w = o.split(/\s+/)
            const want = w[1] && w[1] !== "-" ? w[1] : ""
            if (db.open && w[2] === "toggle" && (want === "" || want === db.tab)) db.close()
            else if (db.open && want !== "") db.tab = want
            else db.show(want, false)
            if (w[3] === "edit") db.editing = true
        }
    }

    Process {
        id: statsProc
        command: ["bash", "-c", "exec \"$HOME/.local/bin/rice-dashboard\" stats"]
        running: db.open
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    const j = JSON.parse(line)
                    if (j.disks) db.disks = j.disks
                    else j.disks = db.disks
                    db.stats = j
                } catch (e) { }
            }
        }
    }
    Process {
        id: aboutProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" about"]
        stdout: StdioCollector { onStreamFinished: { try { db.about = JSON.parse(text) } catch (e) { } } }
    }

    // ---------------- staying open while the pointer is near ----------------
    // the whole bottom edge counts as "near" while it is open: moving the pointer along the bottom of the
    // screen never closes it (it used to close in the corners and open again on the edge, over and over)
    function inside() { return shellHover.hovered || bridgeHover.hovered || edgeHover.hovered || trayHover.hovered || bottomHover.hovered }
    Item {
        id: bottomZone
        visible: db.open && db.byHover
        width: db.side ? 10 : db.width
        height: db.side ? db.height : 10
        x: db.atRight ? db.width - width : 0
        y: db.atTop ? 0 : (db.side ? 0 : db.height - height)
        HoverHandler { id: bottomHover; onHoveredChanged: db.pointerMoved() }
    }
    function pointerMoved() {
        if (shellHover.hovered) db.entered = true
        if (inside()) leaveTimer.stop()
        else if (db.open && (db.entered || db.byHover)) leaveTimer.restart()
    }
    Timer {
        id: leaveTimer
        // opened from the edge but not moved into it yet: a little longer
        interval: db.entered ? 380 : 900
        onTriggered: {
            if (db.inside() || db.cfg.close_on_leave === false || db.editing || db.typing || !(db.entered || db.byHover)) return
            // a screenshot is being taken (slurp takes the pointer): stay, so the dashboard can be in the picture
            shotCheck.running = true
        }
    }
    Process {
        id: shotCheck
        command: ["bash", "-c", "[ -e \"$HOME/.cache/rice/shooting\" ] && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "1") { shotWait.restart(); return }
                if (!db.inside() && db.open) db.close()
            }
        }
    }
    // check again until the screenshot is done, then close only if the pointer is not back on the dashboard
    Timer { id: shotWait; interval: 400; onTriggered: if (db.open && !db.inside()) shotCheck.running = true }

    // click outside: close
    MouseArea {
        anchors.fill: parent
        enabled: db.open
        onClicked: db.close()
    }


    // between the edge and the panel: the bar itself counts as "near"
    Item {
        id: bridge
        visible: db.open
        x: db.atLeft ? 0 : (db.atRight ? shell.x + shell.width * db.sc : shell.x)
        width: db.atLeft ? shell.x : (db.atRight ? db.width - x : shell.width * db.sc)
        y: db.side ? shell.y : (db.atTop ? 0 : shell.y + shell.height * db.sc)
        height: db.side ? shell.height * db.sc : (db.atTop ? shell.y + 2 : db.height - y)
        HoverHandler { id: bridgeHover; onHoveredChanged: db.pointerMoved() }
    }

    // keyboard: Esc, arrows, 1-4
    Item {
        id: keys
        focus: true
        Keys.onPressed: function(e) {
            if (e.key === Qt.Key_Escape) { if (db.editing) db.editing = false; else db.close(); e.accepted = true }
            else if (db.typing) return
            // Wallpaper tab: arrows move through the wallpapers (down / right = next, up / left = back), Enter sets it
            else if (db.tab === "wallpaper" && db.wallsTab && (e.key === Qt.Key_Down || e.key === Qt.Key_Right)) { db.wallsTab.move(1); e.accepted = true }
            else if (db.tab === "wallpaper" && db.wallsTab && (e.key === Qt.Key_Up || e.key === Qt.Key_Left)) { db.wallsTab.move(-1); e.accepted = true }
            else if (db.tab === "wallpaper" && db.wallsTab && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) { db.wallsTab.applySel(); e.accepted = true }
            else if (e.key === Qt.Key_Right || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) { db.tab = db.tabs[(db.curIdx + 1) % db.tabs.length]; e.accepted = true }
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) { db.tab = db.tabs[(db.curIdx - 1 + db.tabs.length) % db.tabs.length]; e.accepted = true }
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9 && e.key - Qt.Key_1 < db.tabs.length) { db.tab = db.tabs[e.key - Qt.Key_1]; e.accepted = true }
        }
    }

    // ---------------- edit tray: floats just above the panel ----------------
    Item {
        id: tray
        readonly property bool on: db.editing && db.open && db.tab !== "wallpaper"
        transformOrigin: Item.TopLeft
        scale: db.sc
        width: db.curW - 2 * db.pad - db.railW
        height: 52
        x: db.side ? shell.x + (db.pad + db.railW) * db.sc : (db.width - width * db.sc) / 2
        // at a side edge the panel is as tall as the screen: the bar floats over the bottom of the cards
        y: db.side ? shell.y + (shell.height - height - db.pad) * db.sc + (on ? 0 : 14)
           : (db.atTop ? shell.y + (shell.height + 12) * db.sc - (on ? 0 : 14) : shell.y - (height + 12) * db.sc + (on ? 0 : 14))
        opacity: on ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        HoverHandler { id: trayHover }
        MouseArea { anchors.fill: parent }
        readonly property var g: db.grids[db.tab] || null
        readonly property var hid: g && g.packed ? (g.packed, g.hidden()) : []
        Rectangle {
            anchors.fill: parent; radius: height / 2
            color: db.p.solidBg
            border.width: 1
            border.color: db.p.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }
        Row {
            x: 18; anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            DText { text: tray.hid.length ? "Add" : "All cards are on"; font.pixelSize: 12; color: db.p.sub; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: tray.hid
                Rectangle {
                    height: 32; width: ar.implicitWidth + 24; radius: 16
                    color: am.containsMouse ? db.p.primary : db.p.container
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: ar
                        anchors.centerIn: parent
                        spacing: 4
                        MIcon { name: "add"; glyph: "+"; size: 16; color: am.containsMouse ? db.p.inkOn : db.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                        DText { text: modelData.name; font.pixelSize: 12; color: am.containsMouse ? db.p.inkOn : db.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tray.g.add(modelData.id) }
                }
            }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            DText { visible: !db.side; text: "Drag to move · pull the handles to resize · + fills a gap"; font.pixelSize: 11; color: db.p.sub; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                height: 32; width: rr.implicitWidth + 24; radius: 16
                color: rm.containsMouse ? db.p.card2 : db.p.container
                DText { id: rr; anchors.centerIn: parent; text: "Reset"; font.pixelSize: 12; color: db.p.onContainer }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: db.resetLayout(db.side ? db.tab + "-side" : db.tab) }
            }
            Rectangle {
                height: 32; width: dn.implicitWidth + 28; radius: 16
                color: dnm.containsMouse ? Qt.lighter(db.p.primary, 1.08) : db.p.primary
                DText { id: dn; anchors.centerIn: parent; text: "Done"; font.pixelSize: 12; font.weight: Font.DemiBold; color: db.p.inkOn }
                MouseArea { id: dnm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: db.editing = false }
            }
        }
    }

    // ---------------- the panel ----------------
    Item {
        id: shell
        // the full size; what you see grows inside it
        width: db.curW + 2 * db.earR
        height: db.curH
        x: db.atLeft ? 10 : (db.atRight ? db.width - width * db.sc - 10 : (db.width - width * db.sc) / 2)
        y: db.side ? (db.height - height * db.sc) / 2 : (db.atTop ? db.barOff + (db.attach ? 0 : 10) : db.height - db.barOff - (db.attach ? 0 : 10) - height * db.sc)
        transformOrigin: Item.TopLeft
        scale: db.sc
        visible: db.t > 0.003
        clip: db.anim === "slide" && db.t < 0.999

        // how much of it shows (Morph grows out of the bar, Slide comes down, Fade fades in)
        readonly property real e: db.t
        readonly property real sw: db.curW
        readonly property real sh: db.curH
        readonly property real slideY: db.anim === "slide" && !db.side ? (db.atTop ? -1 : 1) * (1 - e) * (db.curH + 4) : 0
        readonly property real slideX: db.anim === "slide" && db.side ? (db.atLeft ? -1 : 1) * (1 - e) * (db.curW + 14) : 0
        opacity: db.anim === "fade" ? e : (db.anim === "slide" ? Math.min(1, 0.4 + e) : 1)

        HoverHandler { id: shellHover; onHoveredChanged: db.pointerMoved() }
        MouseArea { x: (shell.width - shell.sw) / 2 - db.earR; y: db.atTop ? 0 : shell.height - shell.sh; width: shell.sw + 2 * db.earR; height: shell.sh }

        Item {
            id: frameBox
            width: shell.width
            height: shell.height
            x: shell.slideX
            y: shell.slideY
            // shape: flat edge against the bar, curved "ears" where it meets it, round corners away from it
            Canvas {
                id: shape
                anchors.fill: parent
                property real sw: shell.sw
                property real sh: shell.sh
                property color fill: db.p.bg
                property color stroke: db.p.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.07)
                onSwChanged: requestPaint()
                onShChanged: requestPaint()
                onFillChanged: requestPaint()
                onWidthChanged: requestPaint()
                transform: Scale { yScale: db.atTop ? 1 : -1; origin.y: shape.height / 2 }
                onPaint: {
                    const c = getContext("2d")
                    c.reset()
                    const er = db.attach ? Math.min(db.earR, sh / 2) : 0
                    const r = Math.min(db.p.radius, sh / 2, sw / 2)
                    const L = (width - sw) / 2, R = L + sw, B = sh
                    function outline(close) {
                        c.beginPath()
                        if (db.attach) {
                            c.moveTo(L - er, 0)
                            c.arc(L - er, er, er, -Math.PI / 2, 0, false)
                        } else {
                            c.moveTo(L, r)
                            c.arc(L + r, r, r, Math.PI, 1.5 * Math.PI, false)
                            c.lineTo(R - r, 0)
                            c.arc(R - r, r, r, 1.5 * Math.PI, 2 * Math.PI, false)
                            c.lineTo(R, B - r)
                            c.arc(R - r, B - r, r, 0, Math.PI / 2, false)
                            c.lineTo(L + r, B)
                            c.arc(L + r, B - r, r, Math.PI / 2, Math.PI, false)
                            c.closePath()
                            return
                        }
                        c.lineTo(L, B - r)
                        c.arc(L + r, B - r, r, Math.PI, Math.PI / 2, true)
                        c.lineTo(R - r, B)
                        c.arc(R - r, B - r, r, Math.PI / 2, 0, true)
                        c.lineTo(R, er)
                        c.arc(R + er, er, er, Math.PI, 1.5 * Math.PI, false)
                        if (close) c.closePath()
                    }
                    outline(true)
                    c.fillStyle = fill
                    c.fill()
                    outline(false)
                    c.lineWidth = 1
                    c.strokeStyle = stroke
                    c.stroke()
                }
            }
            // a soft colored glow (Aurora)
            Rectangle {
                visible: db.p.glow
                x: (shell.width - shell.sw) / 2 + 30; width: shell.sw - 60
                y: db.atTop ? 0 : shell.height - height
                height: Math.min(140, shell.sh)
                radius: 60
                opacity: 0.12 * db.t
                gradient: Gradient {
                    GradientStop { position: db.atTop ? 0 : 1; color: db.acc }
                    GradientStop { position: db.atTop ? 1 : 0; color: "transparent" }
                }
            }

            // ---------- contents (clipped to the growing shape) ----------
            Item {
                id: clipBox
                x: (shell.width - shell.sw) / 2
                y: db.atTop ? 0 : shell.height - shell.sh
                width: shell.sw
                height: shell.sh
                clip: true
                Item {
                    id: content
                    width: db.curW
                    height: db.curH
                    x: (clipBox.width - width) / 2
                    y: db.atTop ? 0 : clipBox.height - height
                    opacity: 1

                    // ---------- tabs ----------
                    Item {
                        id: head
                        x: db.pad; y: db.side ? db.pad : 10
                        // along the top (bottom and top positions) or a column on the left (side positions)
                        width: db.side ? db.railW - db.pad : parent.width - 2 * db.pad - (canEdit ? 50 : 0)
                        height: db.side ? head.cell * Math.max(1, db.tabs.length) : db.headH - 14
                        readonly property bool canEdit: db.tab !== "wallpaper"
                        // in the column: the tabs sit together in one pill, like the bar along the top, and the edit button under it
                        readonly property real cell: db.side ? 88 : 84
                        readonly property real tw: db.side ? cell : width / Math.max(1, db.tabs.length)
                        function slotY(i) { return i * cell }
                        readonly property var names: ({ dashboard: "Dashboard", control: "Control", tasks: "Tasks", wallpaper: "Wallpaper", performance: "Performance", about: "About" })
                        readonly property var icons: ({ dashboard: ["space_dashboard", 0xF056E], wallpaper: ["wallpaper", 0xF02E9],
                                                        performance: ["speed", 0xF04C5], about: ["info", 0xF02FD],
                                                        control: ["tune", 0xF062E], tasks: ["checklist", 0xF05E1] })
                        Behavior on width { enabled: !db.side; NumberAnimation { duration: 260 } }
                        Rectangle {
                            visible: db.p.tabStyle === "segment"
                            anchors.fill: parent
                            radius: db.side ? 22 : height / 2
                            color: db.p.card
                        }
                        Rectangle {
                            id: ind
                            readonly property bool under: db.p.tabStyle === "underline" && !db.side
                            function labelW(i) { const it = tabRep.itemAt(i); return it ? it.labelWidth : 60 }
                            readonly property real lw: under ? labelW(db.curIdx) + 22 : (db.side ? Math.min(head.tw, 92) : head.tw) - (db.p.tabStyle === "segment" ? 8 : 14)
                            x: db.side ? (db.p.tabStyle === "segment" ? 4 : 2) : db.curIdx * head.tw + (head.tw - lw) / 2
                            y: db.side ? head.slotY(db.curIdx) + (head.tw - lw) / 2 : (under ? head.height - 3 : (db.p.tabStyle === "segment" ? 4 : 2))
                            width: db.side ? head.width - (db.p.tabStyle === "segment" ? 8 : 4) : lw
                            height: db.side ? lw : (under ? 3 : head.height - (db.p.tabStyle === "segment" ? 8 : 4))
                            radius: under ? 1.5 : Math.min(width, height) / 2
                            color: under ? db.p.primary : (db.p.tabStyle === "segment" ? db.p.primary : db.p.container)
                            Behavior on x { NumberAnimation { duration: 460 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 1.36, 0.64, 1, 1, 1] } }
                            Behavior on y { NumberAnimation { duration: 460 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 1.36, 0.64, 1, 1, 1] } }
                            Behavior on width { NumberAnimation { duration: 320 / db.spd; easing.type: Easing.OutCubic } }
                        }
                        Rectangle {
                            visible: db.p.tabStyle === "underline" && !db.side
                            anchors.left: parent.left; anchors.right: parent.right
                            y: parent.height
                            height: 1
                            color: db.p.track
                        }
                        Item {
                            anchors.fill: parent
                            Repeater {
                                id: tabRep
                                model: db.tabs
                                delegate: Item {
                                    id: tb
                                    readonly property bool on: db.curIdx === index
                                    readonly property real labelWidth: lab.implicitWidth
                                    x: db.side ? 0 : index * head.tw
                                    y: db.side ? head.slotY(index) : 0
                                    width: db.side ? head.width : head.tw
                                    height: db.side ? head.tw : head.height
                                    readonly property color fg: on ? (db.p.tabStyle === "segment" ? db.p.inkOn : db.p.primary) : db.p.sub
                                    Rectangle {
                                        visible: db.p.tabStyle !== "segment"
                                        anchors.fill: parent; anchors.margins: 2
                                        radius: height / 2
                                        color: tm.containsMouse && !tb.on ? db.p.card : "transparent"
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        MIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            name: (head.icons[modelData] || ["info", 0xF02FD])[0]
                                            glyph: db.md((head.icons[modelData] || ["info", 0xF02FD])[1])
                                            size: 20; color: tb.fg
                                            Behavior on color { ColorAnimation { duration: 220 } }
                                            scale: tb.on ? 1.08 : 1
                                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                        }
                                        DText { id: lab; anchors.horizontalCenter: parent.horizontalCenter; text: head.names[modelData] || modelData; font.pixelSize: 12; font.weight: tb.on ? Font.DemiBold : Font.Medium; color: tb.fg
                                            Behavior on color { ColorAnimation { duration: 220 } } }
                                    }
                                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: db.tab = modelData }
                                }
                            }
                        }
                    }
                    // edit button
                    Rectangle {
                        visible: head.canEdit
                        x: db.side ? db.pad + (head.width - width) / 2 : parent.width - db.pad - width
                        y: db.side ? head.y + head.height + 12 : head.y + (head.height - height) / 2
                        width: 40; height: 40; radius: 20
                        color: db.editing ? db.p.primary : (edm.containsMouse ? db.p.card2 : db.p.card)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        MIcon { anchors.centerIn: parent; name: db.editing ? "check" : "edit"; glyph: db.editing ? db.md(0xF012C) : ""; size: 19; color: db.editing ? db.p.inkOn : db.p.text }
                        MouseArea { id: edm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: db.editing = !db.editing }
                    }

                    // ---------- tab pages ----------
                    Item {
                        id: body
                        x: db.pad + db.railW
                        y: db.side ? db.pad + 4 : db.headH + 4
                        width: parent.width - 2 * db.pad - db.railW
                        height: db.tabH(db.tab)
                        Repeater {
                            model: db.tabs
                            delegate: Item {
                                id: page
                                readonly property int dist: index - db.curIdx
                                width: db.tabW(modelData) - 2 * db.pad
                                height: db.tabH(modelData)
                                x: dist * 90 + (body.width - width) / 2
                                opacity: dist === 0 ? 1 : 0
                                visible: opacity > 0.01
                                enabled: dist === 0
                                Behavior on x { NumberAnimation { duration: 460 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
                                Behavior on opacity { NumberAnimation { duration: 240 / db.spd; easing.type: Easing.OutCubic } }
                                readonly property bool liveNow: db.open && db.t > 0.3 && dist === 0
                                Loader {
                                    anchors.fill: parent
                                    active: db.visited[modelData] === true
                                    sourceComponent: modelData === "dashboard" ? homeC : modelData === "wallpaper" ? wallC
                                                   : modelData === "control" ? ctlC : modelData === "tasks" ? tasksTabC
                                                   : modelData === "performance" ? perfC : aboutC
                                }
                                Component { id: homeC; DashHome { d: db; live: page.liveNow } }
                                Component { id: wallC; DashWalls { d: db; live: page.liveNow } }
                                Component { id: perfC; DashPerf { d: db; live: page.liveNow } }
                                Component { id: aboutC; DashAbout { d: db; live: page.liveNow } }
                                Component { id: ctlC; DashControl { d: db; live: page.liveNow } }
                                Component { id: tasksTabC; DashTasks { d: db; live: page.liveNow } }
                            }
                        }
                    }

                    // ---------- toast ----------
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height - height - 14
                        width: tt.implicitWidth + 28; height: 32; radius: 16
                        color: db.p.primary
                        opacity: db.toastText !== "" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        DText { id: tt; anchors.centerIn: parent; text: db.toastText; font.pixelSize: 12; color: db.p.inkOn }
                    }
                }
            }
        }
    }

    // the click sound for everything clickable on the dashboard (Settings > Sfx & sounds)
    SfxTap { visible: db.open }
}
