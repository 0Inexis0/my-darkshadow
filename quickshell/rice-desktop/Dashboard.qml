import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// The dashboard: point at the middle of the top (or bottom) edge, or press SUPER + W for wallpapers.
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
    property string lastCmd: ""
    property bool cmdSeen: false
    property var visited: ({})
    property var stats: ({})
    property var disks: []
    readonly property var disk: disks.length > 0 ? disks[0] : null
    property var about: ({})

    readonly property var tabs: cfg.tabs && cfg.tabs.length ? cfg.tabs : ["dashboard", "wallpaper", "performance", "about"]
    readonly property int curIdx: Math.max(0, tabs.indexOf(tab))
    readonly property bool atTop: cfg.position !== "bottom"
    readonly property real sc: cfg.scale ? cfg.scale : 1
    readonly property real spd: cfg.speed ? cfg.speed : 1
    readonly property real gapEdge: cfg.bar && cfg.bar.position === cfg.position && !cfg.bar.autohide ? cfg.bar.height + 8 : 12
    readonly property real baseW: Math.min(cfg.width ? cfg.width : 1000, (db.width - 24) / sc)
    readonly property real headH: 66
    readonly property real bodyH: 330
    readonly property real pad: 18
    readonly property real baseH: headH + bodyH + pad

    // ---------------- helpers for the tabs ----------------
    function md(cp) { return String.fromCodePoint(cp) }
    readonly property var glyphs: ({
        nixos: "", arch: "", archarm: "", cachyos: "", endeavouros: "", manjaro: "",
        garuda: "", ubuntu: "", fedora: "", debian: "", opensuse: "", gentoo: "",
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
    function close() { open = false }
    function show(which, hover) {
        tab = which && tabs.indexOf(which) >= 0 ? which : (cfg.default_tab && tabs.indexOf(cfg.default_tab) >= 0 ? cfg.default_tab : tabs[0])
        byHover = hover === true
        entered = false
        open = true
    }
    function loadAbout() { if (!aboutProc.running) aboutProc.running = true }

    // ---------------- colors: three looks ----------------
    function hx(c) {
        const s = String(c).replace("#", "")
        return [parseInt(s.substr(0, 2), 16) / 255, parseInt(s.substr(2, 2), 16) / 255, parseInt(s.substr(4, 2), 16) / 255]
    }
    function mix(a, b, k, al) {
        const x = hx(a), y = hx(b)
        return Qt.rgba(x[0] * (1 - k) + y[0] * k, x[1] * (1 - k) + y[1] * k, x[2] * (1 - k) + y[2] * k, al === undefined ? 1 : al)
    }
    readonly property string acc: cfg.accent ? cfg.accent : "#9ec9bd"
    readonly property string style: cfg.style ? cfg.style : "darkshadow"
    readonly property var p: style === "end4" ? ({
        // light Material You, tinted by your wallpaper colors
        bg: mix(acc, "#ffffff", 0.9, 0.97), card: mix(acc, "#ffffff", 0.74), card2: mix(acc, "#ffffff", 0.64),
        text: mix(acc, "#000000", 0.82), sub: mix(acc, "#000000", 0.55, 0.85), primary: mix(acc, "#000000", 0.42),
        onPrimary: "#ffffff", container: mix(acc, "#ffffff", 0.52), onContainer: mix(acc, "#000000", 0.72),
        line: "transparent", track: mix(acc, "#ffffff", 0.58), radius: 30, cardRadius: 26, tabStyle: "underline", dark: false
    }) : style === "caelestia" ? ({
        // dark tonal surfaces, big rounded shapes
        bg: mix(acc, "#0f0f12", 0.9, 0.94), card: mix(acc, "#1b1b20", 0.86), card2: mix(acc, "#24242a", 0.8),
        text: "#ebe6ee", sub: "#aaa4ae", primary: mix(acc, "#ffffff", 0.22), onPrimary: mix(acc, "#000000", 0.82),
        container: mix(acc, "#1b1b20", 0.62), onContainer: mix(acc, "#ffffff", 0.72),
        line: Qt.rgba(1, 1, 1, 0.05), track: Qt.rgba(1, 1, 1, 0.09), radius: 34, cardRadius: 24, tabStyle: "pill", dark: true
    }) : ({
        // DarkShadow: black glass, white accents
        bg: Qt.rgba(0.05, 0.05, 0.06, 0.92), card: Qt.rgba(1, 1, 1, 0.045), card2: Qt.rgba(1, 1, 1, 0.075),
        text: "#F6F5F4", sub: "#8f8f98", primary: "#F6F5F4", onPrimary: "#0d0d0d",
        container: Qt.rgba(1, 1, 1, 0.1), onContainer: "#F6F5F4",
        line: Qt.rgba(1, 1, 1, 0.07), track: Qt.rgba(1, 1, 1, 0.1), radius: 26, cardRadius: 18, tabStyle: "segment", dark: true
    })

    // ---------------- window ----------------
    visible: cfg.enabled === true
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-dashboard"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: (db.open || db.t > 0.02) ? whole : trigger }
    Item { id: whole; anchors.fill: parent }

    NumberAnimation { id: tAnim; target: db; property: "t" }
    onOpenChanged: {
        tAnim.stop()
        tAnim.to = open ? 1 : 0
        tAnim.duration = (open ? 480 : 260) / spd
        tAnim.easing.type = Easing.BezierSpline
        tAnim.easing.bezierCurve = open ? [0.05, 0.7, 0.1, 1.0, 1, 1] : [0.3, 0.0, 0.8, 0.15, 1, 1]
        tAnim.start()
        if (open) {
            if (!fullProc.running) fullProc.running = true
            const v = Object.assign({}, visited); v[tab] = true; visited = v
            loadAbout()
            keys.forceActiveFocus()
            graceTimer.restart()
        } else { leaveTimer.stop(); graceTimer.stop() }
    }
    onTabChanged: { const v = Object.assign({}, visited); v[tab] = true; visited = v }

    // ---------------- settings + open requests ----------------
    // cheap check every 0.3 s (two small files); the full settings (with bar size and colors)
    // are read when the file changes and each time the dashboard opens
    property string rawCfg: "?"
    Process {
        id: fullProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" config 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim()
                if (c.length > 0 && c !== db.cfgText) { try { db.cfg = JSON.parse(c); db.cfgText = c } catch (e) { } }
            }
        }
    }
    Process {
        id: cfgProc
        command: ["bash", "-c", "cat \"$HOME/.config/rice/dashboard.json\" 2>/dev/null; echo '@@'; cat \"$HOME/.cache/rice/dashboard-open\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const q = text.split("@@")
                if (q[0] !== db.rawCfg) { db.rawCfg = q[0]; if (!fullProc.running) fullProc.running = true }
                const o = q.length > 1 ? q[1].trim() : ""
                if (db.cmdSeen && o.length > 0 && o !== db.lastCmd) {
                    const w = o.split(/\s+/)
                    const want = w[1] && w[1] !== "-" ? w[1] : ""
                    if (db.open && w[2] === "toggle" && (want === "" || want === db.tab)) db.close()
                    else if (db.open && want !== "") db.tab = want
                    else db.show(want, false)
                }
                db.lastCmd = o
                db.cmdSeen = true
            }
        }
    }
    Timer { interval: 300; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!cfgProc.running) cfgProc.running = true }

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

    // ---------------- the hot spot in the middle of the edge ----------------
    Item {
        id: trigger
        width: cfg.trigger ? cfg.trigger : 260
        height: 3
        x: (db.width - width) / 2
        y: db.atTop ? 0 : db.height - height
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: db.cfg.hover !== false
            onEntered: openTimer.restart()
            onExited: openTimer.stop()
            onClicked: db.show("", true)
        }
    }
    Timer { id: openTimer; interval: Math.max(1, db.cfg.delay !== undefined ? db.cfg.delay : 180); onTriggered: db.show("", true) }
    Timer { id: leaveTimer; interval: 450; onTriggered: if (!hover.hovered && db.cfg.close_on_leave !== false) db.close() }
    // opened from the edge but the pointer never came in
    Timer { id: graceTimer; interval: 1600; onTriggered: if (db.byHover && !db.entered && !hover.hovered) db.close() }

    // click outside: close
    MouseArea {
        anchors.fill: parent
        enabled: db.open
        onClicked: db.close()
    }

    // keyboard: Esc, arrows, 1-4
    Item {
        id: keys
        focus: true
        Keys.onPressed: function(e) {
            if (e.key === Qt.Key_Escape) { db.close(); e.accepted = true }
            else if (e.key === Qt.Key_Right || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) { db.tab = db.tabs[(db.curIdx + 1) % db.tabs.length]; e.accepted = true }
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) { db.tab = db.tabs[(db.curIdx - 1 + db.tabs.length) % db.tabs.length]; e.accepted = true }
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4 && e.key - Qt.Key_1 < db.tabs.length) { db.tab = db.tabs[e.key - Qt.Key_1]; e.accepted = true }
        }
    }

    // ---------------- the panel ----------------
    Item {
        id: panel
        visible: db.t > 0.005
        width: db.baseW
        height: db.baseH
        x: (db.width - width) / 2
        y: db.atTop ? db.gapEdge - (1 - db.t) * 26 : db.height - db.gapEdge - height + (1 - db.t) * 26
        transformOrigin: db.atTop ? Item.Top : Item.Bottom
        scale: db.sc * (0.93 + 0.07 * db.t)
        opacity: Math.min(1, db.t * 1.5)

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) { db.entered = true; leaveTimer.stop(); graceTimer.stop() }
                else if (db.open && db.entered) leaveTimer.restart()
            }
        }
        // swallow clicks so they do not reach the "click outside" area
        MouseArea { anchors.fill: parent }

        // soft shadow
        Rectangle { anchors.fill: bg; anchors.margins: -1; anchors.topMargin: 4; anchors.bottomMargin: -8; radius: bg.radius + 4; color: Qt.rgba(0, 0, 0, db.p.dark ? 0.35 : 0.16); z: -2 }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: db.p.radius
            color: db.p.bg
            border.width: 1
            border.color: db.p.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // ---------- tabs ----------
        Item {
            id: head
            x: db.pad; y: 10
            width: parent.width - 2 * db.pad
            height: db.headH - 14
            readonly property real tw: width / Math.max(1, db.tabs.length)
            readonly property var names: ({ dashboard: "Dashboard", wallpaper: "Wallpaper", performance: "Performance", about: "About" })
            readonly property var icons: ({ dashboard: 0xF056E, wallpaper: 0xF02E9, performance: 0xF04C5, about: 0xF02FD })

            // segment track (DarkShadow)
            Rectangle {
                visible: db.p.tabStyle === "segment"
                anchors.fill: parent
                radius: height / 2
                color: db.p.card
            }
            // the moving highlight
            Rectangle {
                id: ind
                readonly property bool under: db.p.tabStyle === "underline"
                readonly property real lw: under ? labelW(db.curIdx) + 18 : head.tw - (db.p.tabStyle === "segment" ? 8 : 14)
                function labelW(i) { const it = tabRep.itemAt(i); return it ? it.labelWidth : 60 }
                x: db.curIdx * head.tw + (head.tw - lw) / 2
                y: under ? head.height - 3 : (db.p.tabStyle === "segment" ? 4 : 2)
                width: lw
                height: under ? 3 : head.height - (db.p.tabStyle === "segment" ? 8 : 4)
                radius: under ? 1.5 : height / 2
                color: under ? db.p.primary : (db.p.tabStyle === "segment" ? db.p.primary : db.p.container)
                Behavior on x { NumberAnimation { duration: 420 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 1.36, 0.64, 1, 1, 1] } }
                Behavior on width { NumberAnimation { duration: 320 / db.spd; easing.type: Easing.OutCubic } }
            }
            Rectangle {
                visible: db.p.tabStyle === "underline"
                anchors.left: parent.left; anchors.right: parent.right
                y: parent.height
                height: 1
                color: db.mix(db.acc, "#000000", 0.4, 0.18)
            }
            Row {
                anchors.fill: parent
                Repeater {
                    id: tabRep
                    model: db.tabs
                    delegate: Item {
                        id: tb
                        readonly property bool on: db.curIdx === index
                        readonly property real labelWidth: lab.implicitWidth
                        width: head.tw
                        height: head.height
                        readonly property color fg: on ? (db.p.tabStyle === "segment" ? db.p.onPrimary : db.p.primary) : db.p.sub
                        Rectangle {
                            visible: db.p.tabStyle !== "segment"
                            anchors.fill: parent; anchors.margins: 2
                            radius: height / 2
                            color: tm.containsMouse && !tb.on ? db.p.card : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            T { anchors.horizontalCenter: parent.horizontalCenter; kind: "icon"; text: db.md(head.icons[modelData] || 0xF02FD); font.pixelSize: 17; color: tb.fg
                                Behavior on color { ColorAnimation { duration: 200 } }
                                scale: tb.on ? 1.08 : 1
                                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } } }
                            T { id: lab; anchors.horizontalCenter: parent.horizontalCenter; text: head.names[modelData] || modelData; font.pixelSize: 12; font.bold: tb.on; color: tb.fg
                                Behavior on color { ColorAnimation { duration: 200 } } }
                        }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: db.tab = modelData }
                    }
                }
            }
        }

        // ---------- tab contents ----------
        Item {
            id: body
            x: db.pad
            y: db.headH + 4
            width: parent.width - 2 * db.pad
            height: db.bodyH
            Repeater {
                model: db.tabs
                delegate: Item {
                    id: page
                    readonly property int dist: index - db.curIdx
                    width: body.width
                    height: body.height
                    x: dist * 70
                    opacity: dist === 0 ? 1 : 0
                    visible: opacity > 0.01
                    enabled: dist === 0
                    Behavior on x { NumberAnimation { duration: 420 / db.spd; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
                    Behavior on opacity { NumberAnimation { duration: 260 / db.spd; easing.type: Easing.OutCubic } }
                    readonly property bool liveNow: db.open && db.t > 0.25 && dist === 0
                    Loader {
                        anchors.fill: parent
                        active: db.visited[modelData] === true
                        sourceComponent: modelData === "dashboard" ? homeC : modelData === "wallpaper" ? wallC
                                       : modelData === "performance" ? perfC : aboutC
                    }
                    Component { id: homeC; DashHome { d: db; live: page.liveNow } }
                    Component { id: wallC; DashWalls { d: db; live: page.liveNow } }
                    Component { id: perfC; DashPerf { d: db; live: page.liveNow } }
                    Component { id: aboutC; DashAbout { d: db; live: page.liveNow } }
                }
            }
        }
    }
}
