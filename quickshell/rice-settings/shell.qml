import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
FloatingWindow {
    id: win
    title: "Rice Settings"
    // about half of a 1080p screen, a little bigger on bigger screens, never more than fits
    readonly property var scr0: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property int sw0: scr0 ? scr0.width : 1920
    readonly property int sh0: scr0 ? scr0.height : 1080
    implicitWidth: Prefs.winW(sw0, Prefs.size)
    implicitHeight: Prefs.winH(sh0, Prefs.size)
    // While the size changes the window is pinned to it for a moment (Hyprland keeps a floating window inside these limits)
    property bool pin: false
    minimumSize: pin ? Qt.size(implicitWidth, implicitHeight) : Qt.size(0, 0)
    maximumSize: pin ? Qt.size(implicitWidth, implicitHeight) : Qt.size(16384, 16384)
    // A floating window cannot resize itself on Wayland, only Hyprland can. rice-settings-size asks it and checks the result.
    property bool sizeAgain: false
    function applySize() {
        pin = true
        unpin.restart()
        if (sizer.running) sizeAgain = true; else sizer.running = true
    }
    Process {
        id: sizer
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-settings-size\" \"$1\" \"$2\" >/dev/null 2>&1 || true", "_", String(win.implicitWidth), String(win.implicitHeight)]
        onExited: if (win.sizeAgain) { win.sizeAgain = false; running = true }
    }
    Timer { id: unpin; interval: 1200; onTriggered: win.pin = false }
    Timer { interval: 600; running: true; onTriggered: win.applySize() }
    Timer { id: sizeSoon; interval: 120; onTriggered: win.applySize() }
    Connections { target: Prefs; function onSizeChanged() { sizeSoon.restart() } }
    color: "transparent"
    visible: true
    onVisibleChanged: if (!visible) Qt.quit()

    readonly property string home: Quickshell.env("HOME")
    // the tour is on: the rest of the screen goes dark (dimWin below)
    property bool tourOn: false
    function startTour() { page = 0; tour.start() }

    // falling stars across the whole window (Home: Falling stars)
    property bool stars: true
    function setStars(on) {
        stars = on
        Prefs.save("stars", on)
    }
    Process {
        command: ["bash", "-c", "cat \"$HOME/.config/rice/settings-app.json\" 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { win.stars = JSON.parse(text).stars !== false } catch (e) { } } }
    }
    // Auto-hide widgets (Home and Widgets): widgets rest while a tiled window covers the screen
    function setAutoHide(on) {
        const d = JSON.parse(JSON.stringify(win.dst)); d.autoHide = on; win.dst = d
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" auto-hide \"$1\"", "_", on ? "on" : "off"])
        status = "Auto-hide widgets " + (on ? "on" : "off")
    }
    function closeNow() { Qt.quit() }

    // ---------- search: every setting on every page, found by its name, its section, its page or its text ----------
    property var results: []
    property int searchSel: 0
    property var searchIndex: []
    readonly property var synonyms: ({
        bar: ["waybar", "bar"], colour: ["color"], colors: ["color", "theme", "scheme"],
        transparent: ["opacity", "transparency"], transparency: ["opacity", "transparency"], seethrough: ["opacity"],
        round: ["rounding", "radius", "round"], corners: ["rounding", "corner"], lock: ["lock", "idle"],
        sound: ["sound", "sfx", "volume"], sounds: ["sound", "sfx"], sfx: ["sound", "sfx"], music: ["music", "welcome"],
        volume: ["volume", "sound"], mouse: ["cursor", "pointer"], pointer: ["cursor", "pointer"], font: ["font", "text"],
        fonts: ["font"], gap: ["gaps", "gap"], anim: ["animation"], animations: ["animation"], notification: ["notification", "popup"],
        popup: ["popup", "notification"], popups: ["popup", "notification"], keyboard: ["keybind", "bind", "key"],
        shortcut: ["keybind", "bind", "shortcut"], shortcuts: ["keybind", "bind"], screen: ["screen", "monitor", "display"],
        monitor: ["monitor", "screen", "display"], dark: ["dark", "black", "theme"], wallpaper: ["wallpaper", "background"],
        background: ["background", "wallpaper"], top: ["top", "position"], bottom: ["bottom", "position"],
        place: ["position"], where: ["position"], size: ["size", "width", "height", "scale"], big: ["size", "scale"],
        speed: ["speed", "animation"], fast: ["speed"], slow: ["speed", "light", "performance"], lag: ["light", "performance"], laggy: ["light", "performance"], performance: ["light", "performance"], power: ["power", "battery"], wifi: ["wi-fi", "wifi", "network"],
        launcher: ["rofi", "launcher"], record: ["record", "recorder", "recording"], recording: ["record", "recorder"], video: ["record", "recorder", "video"], desktop: ["widgets", "widget"], widget: ["widgets", "widget"], hide: ["auto-hide", "hide"], apps: ["apps", "rofi", "dock"], game: ["gaming"], games: ["gaming"]
    })
    function buildIndex() {
        const out = []
        const slots = pagesHolder.children
        for (let i = 0; i < slots.length; i++) {
            const sl = slots[i]
            if (sl.idx === undefined) continue
            const pg = win.pages[sl.idx]
            if (!pg) continue
            out.push({ page: sl.idx, label: pg.name, section: "", desc: "Page", pageName: pg.name, item: null, kind: "page" })
            const ctx = { section: "" }
            const walk = function(it) {
                const kids = it.children || []
                for (let k = 0; k < kids.length; k++) {
                    const c = kids[k]
                    if (c.sub !== undefined && c.text !== undefined && c.topPadding !== undefined && typeof c.text === "string") {
                        ctx.section = c.text
                        if (c.text.length) out.push({ page: sl.idx, label: c.text, section: "", desc: c.sub || "", pageName: pg.name, item: c, kind: "section" })
                        continue
                    }
                    if (c.reserved !== undefined && c.label !== undefined && typeof c.label === "string" && c.label.length) {
                        out.push({ page: sl.idx, label: c.label, section: ctx.section, desc: c.desc || "", pageName: pg.name, item: c, kind: "row" })
                        continue
                    }
                    // a heading made with a plain title text: it names the section too
                    if (c.kind === "title" && typeof c.text === "string" && c.text.length > 1 && c.text.length < 40 && c.font && c.font.pixelSize >= 15) {
                        ctx.section = c.text
                        continue
                    }
                    // a setting with its own layout (like the clock fonts): its 14 px name counts too
                    if (c.kind === "body" && typeof c.text === "string" && c.font && c.font.pixelSize === 14 && !c.font.bold
                            && c.text.length > 2 && c.text.length < 40 && c.text.indexOf("<") < 0) {
                        out.push({ page: sl.idx, label: c.text, section: ctx.section, desc: "", pageName: pg.name, item: c.parent || c, kind: "row" })
                    }
                    walk(c)
                }
            }
            walk(sl)
        }
        // the same setting twice (a page that keeps two copies of a part): once is enough
        const seen = {}
        searchIndex = out.filter(e => { const k = e.page + "|" + e.label + "|" + e.section; if (seen[k]) return false; seen[k] = true; return true })
    }
    function runSearch(q) {
        q = q.trim().toLowerCase()
        searchSel = 0
        if (!q.length) { results = []; return }
        if (!searchIndex.length) buildIndex()
        const toks = q.split(/\s+/).filter(t => t.length)
        const scored = []
        for (const e of searchIndex) {
            const L = e.label.toLowerCase(), S = e.section.toLowerCase(), P = e.pageName.toLowerCase(), D = e.desc.toLowerCase()
            let score = 0, ok = true
            for (const t of toks) {
                const alts = [t].concat(win.synonyms[t] || [])
                let best = 0
                for (const a of alts) {
                    const w = a === t ? 1 : 0.8
                    if (L.startsWith(a) || L.indexOf(" " + a) >= 0) best = Math.max(best, 7 * w)
                    else if (L.indexOf(a) >= 0) best = Math.max(best, 5 * w)
                    if (S.indexOf(a) >= 0) best = Math.max(best, 3 * w)
                    if (P.indexOf(a) >= 0) best = Math.max(best, 3 * w)
                    if (D.indexOf(a) >= 0) best = Math.max(best, 1.5 * w)
                }
                if (best === 0) { ok = false; break }
                score += best
            }
            if (!ok) continue
            if (e.kind === "page") score += 1
            if (L === q) score += 6
            scored.push({ e: e, s: score })
        }
        scored.sort((a, b) => (b.s - a.s) || (a.e.label.length - b.e.label.length))
        results = scored.slice(0, 40).map(x => x.e)
    }
    function openResult(r) {
        if (!r) return
        Sfx.play("select")
        searchIn.text = ""
        card.forceActiveFocus()
        page = r.page
        if (r.item) { jumpTo.target = r.item; jumpTo.restart() }
    }
    // after the page has changed: scroll to the setting and light it up for a moment
    Timer {
        id: jumpTo
        property var target: null
        interval: 380
        onTriggered: {
            const it = target
            if (!it) return
            let f = it.parent
            while (f && f.contentY === undefined) f = f.parent
            if (f) {
                const y = it.mapToItem(f.contentItem, 0, 0).y
                f.contentY = Math.max(0, Math.min(f.contentHeight - f.height, y - 30))
            }
            Qt.createQmlObject('import QtQuick; Rectangle { anchors.fill: parent; anchors.margins: -3; radius: (parent.radius !== undefined ? parent.radius : 8) + 3; color: "transparent"; border.width: 2; border.color: "#F6F5F4"; opacity: 0; z: 50;' +
                ' SequentialAnimation on opacity { running: true; NumberAnimation { to: 1; duration: 220 } PauseAnimation { duration: 500 } NumberAnimation { to: 0.35; duration: 260 } NumberAnimation { to: 1; duration: 260 } PauseAnimation { duration: 500 } NumberAnimation { to: 0; duration: 600 } ScriptAction { script: destroy() } } }', it, "searchFlash")
        }
    }
    readonly property string presetTool: home + "/.local/bin/waybar-preset"
    property int page: 0
    property var presets: []
    property var st: ({})
    property string status: ""
    property string colorMode: "auto"
    property alias stateTimer: stateTimer
    property var dst: ({ widgets: {}, clock: {}, dock: {}, lock: {} })
    property string osName: "Linux"
    property var osIds: ["linux"]
    // distro logo from the Nerd Font "font logos" set (NixOS logo on NixOS, Arch logo on Arch, ...)
    readonly property var osGlyphs: ({
        nixos: "\uf313", arch: "\uf303", archarm: "\uf303", cachyos: "\uf385", endeavouros: "\uf322", manjaro: "\uf312",
        garuda: "\uf303", ubuntu: "\uf31b", fedora: "\uf30a", nobara: "\uf380", bazzite: "\uf30a", ultramarine: "\uf30a", debian: "\uf306", opensuse: "\uf314", gentoo: "\uf30d",
        void: "\uf32e", alpine: "\uf300", linuxmint: "\uf30e", pop: "\uf32a"
    })
    function osGlyph() {
        for (let i = 0; i < osIds.length; i++) if (osGlyphs[osIds[i]] !== undefined) return osGlyphs[osIds[i]]
        return "\uf17c"
    }
    readonly property string userName: Quickshell.env("USER")
    // rice-effects: blur and transparency are off right now
    property bool flat: false
    Process {
        id: flatProc
        command: ["bash", "-c", "[ -e \"$HOME/.cache/rice/flat\" ] && echo 1 || echo 0"]
        running: true
        stdout: StdioCollector { onStreamFinished: win.flat = text.trim() === "1" }
    }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: if (!flatProc.running) flatProc.running = true }

    function dset(group, key, value) {
        const d = JSON.parse(JSON.stringify(dst))
        if (group === "widget") {
            if (!d.widgets[key]) d.widgets[key] = {}
            d.widgets[key].enabled = (value === "on")
        } else {
            if (!d[group]) d[group] = {}
            d[group][key] = (value === "on" || value === "off") ? (value === "on") : value
        }
        dst = d
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" \"$@\"", "_", group, key, String(value)])
        status = "Applied"
        drefresh.restart()
    }

    // one setting of a widget: wset ID KEY VALUE (visualizer color, clock font, focus minutes)
    function dwset(id, key, value) {
        const d = JSON.parse(JSON.stringify(dst))
        if (id === "clock") { if (!d.clock) d.clock = {}; d.clock[key] = value }
        else { if (!d.widgets[id]) d.widgets[id] = {}; d.widgets[id][key] = value }
        dst = d
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" wset \"$1\" \"$2\" \"$3\"", "_", id, key, String(value)])
        status = "Applied"
        drefresh.restart()
    }
    // widget style: shadow (DarkShadow's Shell), google, outline
    function setWidgetTheme(v) {
        const d = JSON.parse(JSON.stringify(dst)); d.widgetTheme = v; dst = d
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" widgets-theme \"$1\"", "_", v])
        status = "Widget style: " + v
    }
    // dark or light text and cards by the wallpaper behind each widget
    function setWidgetAdapt(on) {
        const d = JSON.parse(JSON.stringify(dst)); d.widgetAdapt = on; dst = d
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" widgets-adapt \"$1\"", "_", on ? "on" : "off"])
        status = "Adaptive colors " + (on ? "on" : "off")
    }

    function dreset() {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" reset-pos"])
        status = "Widget positions reset"
        drefresh.restart()
    }

    Process {
        id: dstate
        command: ["bash", "-c", "\"$HOME/.local/bin/desktop-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { win.dst = JSON.parse(text) } catch (e) { } }
        }
    }
    Timer { id: drefresh; interval: 900; onTriggered: dstate.running = true }

    Process {
        id: osProc
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; printf '%s\\n%s\\n%s\\n' \"${NAME:-Linux}\" \"${ID:-linux}\" \"${ID_LIKE:-}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("\n")
                if (p[0] && p[0].trim().length > 0) win.osName = p[0].trim()
                win.osIds = ((p[1] || "") + " " + (p[2] || "")).trim().toLowerCase().split(/\s+/)
            }
        }
    }

    readonly property var pages: [
        { name: "Home", icon: "\uf015" },
        { name: "Sfx & sounds", icon: "\uf028" },
        { name: "Waybar", icon: "\uf0c9" },
        { name: "Bar layout", icon: "\uf0db" },
        { name: "Hyprland", icon: "\uf108" },
        { name: "Recorder", icon: "\uf03d" },
        { name: "Dashboard", icon: "\uf009" },
        { name: "Rofi", icon: "\uf002" },
        { name: "Theme", icon: "\udb80\udfd8" },
        { name: "Cursors", icon: "\uf245" },
        { name: "Notifications", icon: "\uf0f3" },
        { name: "Idle & Lockscreen", icon: "\uf023" },
        { name: "Widgets", icon: "\uf26c" },
        { name: "Hot corners", icon: "\udb82\ude0b" },
        { name: "Dock", icon: "\uf2d0" },
        { name: "Services", icon: "" }
    ]


    // the sidebar: Home, then groups with an arrow (touch one to see its pages)
    readonly property var navTree: [
        { page: 0 },
        { sep: true },
        { group: "look", name: "Appearance", icon: "\udb80\udfd8", pages: [8, 9, 14] },
        { group: "desk", name: "Desktop", icon: "\uf108", pages: [12, 13, 4, 11] },
        { group: "bar", name: "Bar & launcher", icon: "\uf0c9", pages: [2, 3, 6, 7] },
        { group: "snd", name: "Sound & alerts", icon: "\uf028", pages: [1, 10] },
        { group: "sys", name: "System", icon: "\uf013", pages: [5, 15] }
    ]
    readonly property var navRows: {
        const out = []
        for (let i = 0; i < navTree.length; i++) {
            const n = navTree[i]
            if (n.sep) { out.push({ kind: "sep" }); continue }
            if (n.group) {
                out.push({ kind: "group", gid: n.group, name: n.name, icon: n.icon })
                for (let k = 0; k < n.pages.length; k++) out.push({ kind: "page", idx: n.pages[k], gid: n.group, child: true })
                continue
            }
            out.push({ kind: "page", idx: n.page, gid: "", child: false })
        }
        return out
    }
    readonly property var navGroups: navTree.filter(function(n) { return n.group }).map(function(n) { return n.group })
    property var navOpen: ({})
    function groupOf(idx) {
        for (let i = 0; i < navRows.length; i++) if (navRows[i].kind === "page" && navRows[i].idx === idx) return navRows[i].gid
        return ""
    }
    function toggleGroup(g) { const o = Object.assign({}, navOpen); o[g] = !(o[g] === true); navOpen = o }
    function openFor(idx) { const g = groupOf(idx); if (g !== "" && navOpen[g] !== true) { const o = Object.assign({}, navOpen); o[g] = true; navOpen = o } }
    // the row of a page; when its group is closed: the row of the group
    function navRowOf(idx) {
        let g = -1
        for (let i = 0; i < navRows.length; i++) {
            const r = navRows[i]
            if (r.kind === "page" && r.idx === idx) { if (navLayout.vis[i]) return i; g = r.gid; break }
        }
        if (g === -1) return -1
        for (let i = 0; i < navRows.length; i++) if (navRows[i].kind === "group" && navRows[i].gid === g) return i
        return -1
    }
    readonly property var navLayout: {
        const ys = [], hs = [], vis = [], gbg = {}
        let y = 0
        for (let i = 0; i < navRows.length; i++) {
            const r = navRows[i]
            if (r.kind === "sep") { ys.push(y + 4); hs.push(10); vis.push(true); y += 18; continue }
            if (r.kind === "page" && r.child) {
                if (navOpen[r.gid] !== true) { ys.push(y); hs.push(38); vis.push(false); continue }
                if (!gbg[r.gid]) gbg[r.gid] = { y: y, h: 0 }
                ys.push(y); hs.push(38); vis.push(true)
                gbg[r.gid].h += 40
                y += 40
                continue
            }
            ys.push(y); hs.push(44); vis.push(true)
            y += 48
            // a little air under an open group
            if (r.kind === "group" && navOpen[r.gid] === true) y += 3
        }
        return { ys: ys, hs: hs, vis: vis, gbg: gbg, total: y }
    }
    onPageChanged: openFor(page)
    Component.onCompleted: openFor(page)

    readonly property string hyprTool: home + "/.local/bin/hypr-set"
    property var hv: ({})
    property var hb: ({ mode: "wallpaper", active: "#F6F5F4", inactive: "#444444" })
    property var ha: ({ enabled: true, speed: 100 })

    function hrun(args, msg) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/hypr-set\" \"$@\"", "_"].concat(args.map(a => String(a))))
        if (msg) status = msg
        hrefresh.restart()
    }

    function hset(key, value) {
        const v = Object.assign({}, hv)
        v[key] = value
        hv = v
        hrun(["set", key, String(value)], "Applied")
    }

    function setBorderMode(m) {
        const b = Object.assign({}, hb)
        b.mode = m
        hb = b
        hrun(["border-mode", m], "Borders: " + m)
    }

    function setBorderColor(which, hex) {
        const b = Object.assign({}, hb)
        b[which] = hex
        hb = b
        hrun(["border-color", which, hex], "Border color set")
    }

    function setAnim(k, v) {
        const a = Object.assign({}, ha)
        a[k] = v
        ha = a
        hrun([k === "enabled" ? "anim-enabled" : "anim-speed", k === "enabled" ? (v ? "on" : "off") : v], "Applied")
    }

    function setSt(key, value) {
        const s = Object.assign({}, st)
        s[key] = value
        st = s
    }

    function run(args) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/waybar-set\" \"$@\" && \"$HOME/.local/bin/waybar-reload\"", "_"].concat(args.map(a => String(a))))
        status = "Applied"
        stateTimer.restart()
    }

    function toggleModule(name, on) {
        setSt(name, on)
        run(["toggle", name, on ? "on" : "off"])
    }

    function setColorMode(m) {
        colorMode = m
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-colors\" mode \"$1\"", "_", m])
        let nm = m
        for (let i = 0; i < schemes.length; i++) if (schemes[i].key === m) nm = schemes[i].name
        status = "Colors: " + nm + " (applying...)"
    }

    Process {
        id: lister
        command: ["bash", "-c", "ls -1 \"$HOME/.config/waybar-presets\" 2>/dev/null | grep -v '^_'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: win.presets = text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
        }
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/waybar-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { win.st = JSON.parse(text) } catch (e) { } }
        }
    }

    property var schemes: []
    Process {
        id: schemeProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-colors\" list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { win.schemes = JSON.parse(text) } catch (e) { } }
        }
    }

    Process {
        id: modeProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-colors\" get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { const m = text.trim(); if (m.length > 0) win.colorMode = m }
        }
    }

    Process {
        id: hstate
        command: ["bash", "-c", "\"$HOME/.local/bin/hypr-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j.opts) win.hv = j.opts
                    if (j.borders) win.hb = j.borders
                    if (j.anim) win.ha = j.anim
                } catch (e) { }
            }
        }
    }

    Timer { id: hrefresh; interval: 800; onTriggered: hstate.running = true }

    Timer {
        id: stateTimer
        interval: 900
        onTriggered: { lister.running = true; stateProc.running = true }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        // solid while blur and transparency are off (Settings > Services, or gaming mode); the stars stay
        color: Qt.rgba(0.05, 0.05, 0.05, win.flat ? 1 : 0.72)
        Behavior on color { ColorAnimation { duration: 300 } }
        focus: true
        Keys.onEscapePressed: win.closeNow()
        NumberAnimation on opacity { from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }

        // falling stars over the whole window, behind everything (they stay put while the pages change)
        StarField {
            anchors.fill: parent
            count: 20
            readonly property bool on: win.stars
            running: win.visible && on
            opacity: on ? (win.page === 0 ? 1 : 0.55) : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        // ---------- you: a bigger profile card on top of the sidebar ----------
        Rectangle {
            id: profile
            x: 16
            y: 12
            width: 206
            height: 74
            radius: 18
            color: pfm.containsMouse ? "#181818" : "#131313"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
            Behavior on color { ColorAnimation { duration: 160 } }
            // soft light in the corner
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.045) }
                    GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
            // avatar with a ring (your initial when there is no ~/.face)
            Item {
                id: av
                z: 2            // above the card's click area, so the picture can be clicked on its own
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 52
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#F6F5F4" }
                        GradientStop { position: 1; color: "#5a5a60" }
                    }
                    rotation: pfm.containsMouse ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: width / 2
                    color: "#1c1c1c"
                    T { anchors.centerIn: parent; text: win.userName.length ? win.userName[0].toUpperCase() : "?"; font.pixelSize: 20; font.bold: true }
                }
                RoundImage {
                    id: avImg
                    anchors.fill: parent
                    anchors.margins: 3
                    source: "file://" + win.home + "/.face"
                }
                // click the picture: choose a new one (it is also on the lock screen)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    opacity: avm.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    T { anchors.centerIn: parent; kind: "icon"; text: "\uf030"; font.pixelSize: 15 }
                }
                MouseArea {
                    id: avm
                    anchors.fill: parent
                    z: 5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: facePicker.running = true
                }
                scale: pfm.containsMouse || avm.containsMouse ? 1.05 : 1
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
            }
            Process {
                id: facePicker
                command: ["zenity", "--file-selection", "--title=Choose a profile picture", "--file-filter=Images | *.png *.jpg *.jpeg *.webp"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const p = text.trim()
                        if (p.length === 0) return
                        Quickshell.execDetached(["bash", "-c", "cp -f \"$1\" \"$HOME/.face\"", "_", p])
                        faceReload.restart()
                    }
                }
            }
            Timer { id: faceReload; interval: 400; onTriggered: { avImg.source = ""; avImg.source = "file://" + win.home + "/.face" } }
            Column {
                anchors.left: av.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                T { kind: "title"; text: win.userName; font.pixelSize: 17; font.bold: true; width: parent.width; elide: Text.ElideRight }
                // distro chip
                Rectangle {
                    width: Math.min(parent.width, osRow.implicitWidth + 16)
                    height: 22
                    radius: 11
                    color: "#222224"
                    Row {
                        id: osRow
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        T { kind: "icon"; text: win.osGlyph(); font.pixelSize: 12; color: "#d8d8dc"; anchors.verticalCenter: parent.verticalCenter }
                        T { text: win.osName; font.pixelSize: 11; color: "#b8b8c0"; anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, profile.width - 110); elide: Text.ElideRight }
                    }
                }
            }
            MouseArea { id: pfm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.page = 0 }
        }

        Rectangle {
            id: closeBtn
            width: 30
            height: 30
            radius: 15
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 14
            color: closeMouse.containsMouse ? "#2a2a2a" : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }
            T { anchors.centerIn: parent; text: "\u00d7"; font.pixelSize: 20 }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: win.closeNow()
            }
        }

        // ---------- search anything ----------
        Rectangle {
            id: searchBox
            x: 16; y: 96
            width: 206; height: 40
            radius: 13
            color: searchIn.activeFocus ? "#171717" : "#121212"
            border.width: 1
            border.color: searchIn.activeFocus ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.06)
            Behavior on border.color { ColorAnimation { duration: 160 } }
            T { kind: "icon"; text: "\uf002"; x: 14; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12; color: searchIn.activeFocus ? "#d8d8dc" : "#77777f" }
            TextInput {
                id: searchIn
                objectName: "searchIn"
                x: 36; width: parent.width - 66
                anchors.verticalCenter: parent.verticalCenter
                color: "#F6F5F4"
                font.family: Fonts.family("body")
                font.pixelSize: 13
                clip: true
                selectByMouse: true
                onTextChanged: { if (activeFocus) Sfx.play("type"); win.runSearch(text) }
                Keys.onDownPressed: win.searchSel = Math.min(win.searchSel + 1, win.results.length - 1)
                Keys.onUpPressed: win.searchSel = Math.max(0, win.searchSel - 1)
                Keys.onReturnPressed: win.openResult(win.results[win.searchSel])
                Keys.onEnterPressed: win.openResult(win.results[win.searchSel])
                Keys.onEscapePressed: { text = ""; card.forceActiveFocus() }
            }
            T {
                x: 36; anchors.verticalCenter: parent.verticalCenter
                visible: searchIn.text.length === 0
                text: "Search anything!"
                color: "#6a6a72"; font.pixelSize: 13
            }
            Rectangle {
                visible: searchIn.text.length > 0
                width: 22; height: 22; radius: 11
                anchors.right: parent.right; anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                color: clrM.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                T { anchors.centerIn: parent; text: "\u00d7"; font.pixelSize: 15; color: "#a8a8b0" }
                MouseArea { id: clrM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: searchIn.text = "" }
            }
            MouseArea { anchors.fill: parent; z: -1; cursorShape: Qt.IBeamCursor; onClicked: searchIn.forceActiveFocus() }
        }
        // results: the setting, and where it is (page > section)
        ListView {
            id: resultList
            x: 12; y: 144
            width: 214
            height: parent.height - 144 - 34
            visible: searchIn.text.length > 0
            clip: true
            model: win.results
            currentIndex: win.searchSel
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: Rectangle {
                width: resultList.width
                height: 50
                radius: 11
                color: index === win.searchSel ? Qt.rgba(1, 1, 1, 0.09) : (rm.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                Column {
                    x: 12; width: parent.width - 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    T { text: modelData.label; font.pixelSize: 13; font.bold: index === win.searchSel; width: parent.width; elide: Text.ElideRight }
                    T {
                        text: modelData.kind === "page" ? "Page" : (modelData.pageName + (modelData.section && modelData.section !== modelData.label ? "  \u203a  " + modelData.section : ""))
                        font.pixelSize: 11; color: "#8a8a92"; width: parent.width; elide: Text.ElideRight
                    }
                }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: win.searchSel = index; onClicked: win.openResult(modelData) }
            }
            T {
                visible: win.results.length === 0
                y: 14; x: 8; width: parent.width - 16
                text: "Nothing found. Try other words, like \"blur\" or \"bar position\"."
                wrapMode: Text.WordWrap
                font.pixelSize: 12; color: "#8a8a92"
            }
        }

        // sidebar scrolls when the categories do not fit
        Flickable {
            id: navFlick
            x: 16
            y: 144
            width: 206
            height: parent.height - 144 - 34
            // while you search, the results take this place
            opacity: searchIn.text.length ? 0 : 1
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 160 } }
            contentWidth: width
            contentHeight: navCol.height + 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Behavior on contentY {
                enabled: !navFlick.dragging && !navFlick.flicking
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    const max = Math.max(0, navFlick.contentHeight - navFlick.height)
                    navFlick.contentY = Math.max(0, Math.min(max, navFlick.contentY - e.angleDelta.y * Prefs.wheel * 1.5))
                }
            }
            // keep the selected category visible
            function reveal() {
                const r = win.navRowOf(win.page)
                if (r < 0) return
                const top = win.navLayout.ys[r], bottom = top + win.navLayout.hs[r]
                if (top < contentY) contentY = Math.max(0, top - 6)
                else if (bottom > contentY + height) contentY = Math.min(Math.max(0, contentHeight - height), bottom + 8 - height)
            }
            Connections { target: win; function onPageChanged() { navFlick.reveal() } }

            // the box behind the pages of an open group
            Repeater {
                model: win.navGroups
                delegate: Rectangle {
                    readonly property var g: win.navLayout.gbg[modelData] || ({ y: 0, h: 0 })
                    x: 0
                    y: g.y - 3
                    width: 206
                    height: Math.max(0, g.h + 4)
                    radius: 14
                    color: "#111112"
                    border.width: 1
                    border.color: "#1c1c1e"
                    opacity: win.navOpen[modelData] === true ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
            }

            // the selection glides to the new category and stretches a little on the way (Material 3)
            Rectangle {
                id: navSel
                readonly property int row: win.navRowOf(win.page)
                readonly property bool child: row >= 0 && win.navRows[row] && win.navRows[row].child === true
                property real target: row >= 0 ? win.navLayout.ys[row] : 0
                y: target
                x: child ? 8 : 0
                width: child ? 198 : 206
                height: row >= 0 ? win.navLayout.hs[row] : 44
                radius: child ? 11 : 14
                color: "#262626"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)
                // the page is inside a closed group: the selection rests on the group, a little dimmer
                opacity: row >= 0 && win.navLayout.vis[row] ? 1 : 0
                Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Rectangle {
                    x: 0; anchors.verticalCenter: parent.verticalCenter
                    width: 3; height: 18; radius: 1.5
                    color: "#F6F5F4"
                }
            }

            Item {
                id: navCol
                width: 206
                height: win.navLayout.total

                Repeater {
                    model: win.navRows
                    delegate: Item {
                        id: nr
                        readonly property var r: modelData
                        readonly property bool shown: win.navLayout.vis[index] === true
                        readonly property bool sel: r.kind === "page" && win.page === r.idx
                        // a group is "current" when one of its pages is open
                        readonly property bool holds: r.kind === "group" && win.groupOf(win.page) === r.gid
                        y: win.navLayout.ys[index]
                        width: 206
                        height: win.navLayout.hs[index]
                        opacity: shown ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 180 } }

                        // a thin line between Home and the groups
                        Rectangle {
                            visible: nr.r.kind === "sep"
                            x: 14; width: parent.width - 28; height: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#202022"
                        }

                        Rectangle {
                            visible: nr.r.kind !== "sep"
                            x: nr.r.child ? 8 : 0
                            width: parent.width - (nr.r.child ? 8 : 0)
                            height: parent.height
                            radius: nr.r.child ? 11 : 14
                            color: !nr.sel && navMouse.containsMouse ? (nr.r.child ? "#1a1a1c" : "#1a1a1a") : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            T { kind: "icon"; x: nr.r.child ? 14 : 18; anchors.verticalCenter: parent.verticalCenter
                                text: nr.r.kind === "group" ? nr.r.icon : (nr.r.kind === "page" ? win.pages[nr.r.idx].icon : "")
                                font.pixelSize: nr.r.child ? 14 : 18
                                color: nr.sel || nr.holds ? "#F6F5F4" : "#a8a8b0"
                                scale: nr.sel ? 1.1 : 1
                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } } }
                            T { x: nr.r.child ? 40 : 50; width: parent.width - (nr.r.child ? 52 : 82); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter
                                text: nr.r.kind === "group" ? nr.r.name : (nr.r.kind === "page" ? win.pages[nr.r.idx].name : "")
                                font.pixelSize: nr.r.child ? 13 : 14
                                font.weight: nr.sel || nr.holds ? Font.DemiBold : Font.Normal
                                color: nr.sel || nr.holds ? "#F6F5F4" : "#b8b8c0"
                                Behavior on color { ColorAnimation { duration: 200 } } }
                            // groups: an arrow that turns when the group opens
                            T { visible: nr.r.kind === "group"; kind: "icon"; x: parent.width - 30; anchors.verticalCenter: parent.verticalCenter
                                text: "\uf078"; font.pixelSize: 10; color: navMouse.containsMouse || nr.holds ? "#d0d0d6" : "#7a7a82"
                                rotation: win.navOpen[nr.r.gid] === true ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }
                            // a closed group with the open page inside: a small dot
                            Rectangle { visible: nr.holds && win.navOpen[nr.r.gid] !== true; x: parent.width - 48; width: 5; height: 5; radius: 2.5
                                anchors.verticalCenter: parent.verticalCenter; color: "#F6F5F4" }
                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                enabled: nr.shown
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (nr.r.kind === "group") { Sfx.play(win.navOpen[nr.r.gid] === true ? "switch-off" : "switch-on"); win.toggleGroup(nr.r.gid) }
                                    else win.page = nr.r.idx
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: pagesHolder
            x: 238
            y: 60
            width: parent.width - 238
            height: parent.height - 60
            clip: true


            PageSlot { idx: 0; cur: win.page; HomePage { id: homePage; anchors.fill: parent; ctl: win } }
            PageSlot { idx: 1; cur: win.page; SoundsPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 2; cur: win.page; WaybarPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 3; cur: win.page; BarLayoutPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 4; cur: win.page; HyprlandPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 5; cur: win.page; RecorderPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 6; cur: win.page; DashboardPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 7; cur: win.page; RofiPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 8; cur: win.page; ThemePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 9; cur: win.page; CursorsPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 10; cur: win.page; NotificationsPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 11; cur: win.page; IdlePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 12; cur: win.page; DesktopPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 13; cur: win.page; HotCornersPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 14; cur: win.page; InterfacePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 15; cur: win.page; ServicesPage { anchors.fill: parent; ctl: win } }
        }

        // ---------- the tour (after the welcome intro, or rice-welcome tour) ----------
        Tour {
            id: tour
            objectName: "tour"
            onFinished: { card.forceActiveFocus(); win.tourOn = false }
            onActiveChanged: if (active) win.tourOn = true
            steps: [
                { title: "You can find anything here!", r: 15,
                  body: "Type what you want to change, like \"bar position\" or \"blur\", and jump right to it.",
                  rect: function() { return { x: searchBox.x - 5, y: searchBox.y - 5, w: searchBox.width + 10, h: searchBox.height + 10 } } },
                { title: "Every part has a page", r: 18,
                  body: "The bar, the theme, notifications, the lock screen, the dashboard and more. Click one to open it.",
                  rect: function() { return { x: navFlick.x - 6, y: navFlick.y - 6, w: navFlick.width + 12, h: Math.min(navFlick.height, win.navLayout.total) + 12 } } },
                { title: "Sounds you can change", r: 14,
                  body: "The soft clicks and this quiet music live in Sfx & sounds. Pick another sound pack, make it quieter or turn it off.",
                  rect: function() {
                      win.openFor(1)
                      const r = win.navRowOf(1), y = r >= 0 ? win.navLayout.ys[r] : 0, h = r >= 0 ? win.navLayout.hs[r] : 44
                      return { x: navFlick.x - 4, y: navFlick.y + y - navFlick.contentY - 4, w: navFlick.width + 8, h: h + 8 }
                  } },
                { title: "Make it yours", r: 16,
                  body: "Start with the things people change first. Most changes show up right away, and every page has a live preview.",
                  rect: function() {
                      const q = homePage.quickArea, p = q.mapToItem(card, 0, 0)
                      return { x: p.x - 10, y: p.y - 44, w: q.width + 20, h: q.height + 54 }
                  } },
                { title: "This is you", r: 22,
                  body: "Click your picture to change it, it shows on the lock screen too. Click the card to come back here, to Home.",
                  rect: function() { return { x: profile.x - 5, y: profile.y - 5, w: profile.width + 10, h: profile.height + 10 } } },
                { title: "That's it!", r: 20,
                  body: "Close Settings here and open it again any time with SUPER + U. Have fun with your desktop.",
                  rect: function() { return { x: closeBtn.x - 6, y: closeBtn.y - 6, w: closeBtn.width + 12, h: closeBtn.height + 12 } } }
            ]
        }
        Process {
            // the welcome intro leaves this file behind when it opens Settings
            id: tourCheck
            running: true
            command: ["bash", "-c", "f=\"$HOME/.cache/rice/settings-tour\"; [ -e \"$f\" ] && rm -f \"$f\" && echo 1 || echo 0"]
            stdout: StdioCollector { onStreamFinished: if (text.trim() === "1") tourDelay.start() }
        }
        Timer { id: tourDelay; interval: 650; onTriggered: { win.page = 0; tour.start() } }

        // the click sound for everything clickable in Settings (Sfx & sounds)
        SfxTap {}

        T {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 24
            text: win.status
            color: "#8a8a8a"
            font.pixelSize: 12
        }
    }
}

// ---------- during the tour: the whole screen goes dark (wallpaper, Waybar, widgets), only Settings stays lit ----------
PanelWindow {
    id: dimWin
    readonly property bool want: win.tourOn
    // where the Settings window is on this monitor (hyprctl), plus a little room for its border
    property real hx: 0
    property real hy: 0
    property real hw: 0
    property real hh: 0
    property real k: 0
    visible: k > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-tour-dim"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // clicks on the dark part go nowhere, clicks on Settings go to Settings
    mask: Region { item: dimAll; Region { item: dimHole; intersection: Intersection.Subtract } }
    Item { id: dimAll; anchors.fill: parent }
    Item { id: dimHole; x: dimWin.hx; y: dimWin.hy; width: dimWin.hw; height: dimWin.hh }

    onWantChanged: { dimK.to = want ? 1 : 0; dimK.restart(); if (want) dimWhere.running = true }
    NumberAnimation { id: dimK; target: dimWin; property: "k"; duration: 420; easing.type: Easing.OutCubic }
    Process {
        id: dimWhere
        command: ["bash", "-c", "hyprctl -j clients 2>/dev/null | python3 -c 'import sys,json\nfor c in json.load(sys.stdin):\n    if c.get(\"title\")==\"Rice Settings\": print(c[\"monitor\"], c[\"at\"][0], c[\"at\"][1], c[\"size\"][0], c[\"size\"][1]); break'; hyprctl -j monitors 2>/dev/null | python3 -c 'import sys,json\nfor m in json.load(sys.stdin): print(\"M\", m[\"id\"], m[\"name\"], m[\"x\"], m[\"y\"])'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length === 0 || lines[0].startsWith("M")) return
                const w = lines[0].split(" ").map(Number)
                for (let i = 1; i < lines.length; i++) {
                    const m = lines[i].split(" ")
                    if (Number(m[1]) !== w[0]) continue
                    for (let j = 0; j < Quickshell.screens.length; j++)
                        if (Quickshell.screens[j].name === m[2]) dimWin.screen = Quickshell.screens[j]
                    dimWin.hx = w[1] - Number(m[3]) - 3; dimWin.hy = w[2] - Number(m[4]) - 3
                    dimWin.hw = w[3] + 6; dimWin.hh = w[4] + 6
                }
            }
        }
    }
    // follow the window if it is moved during the tour
    Timer { interval: 500; repeat: true; running: dimWin.want; onTriggered: if (!dimWhere.running) dimWhere.running = true }

    Item {
        anchors.fill: parent
        clip: true
        opacity: dimWin.k
        Rectangle {
            readonly property real b: 4000
            x: dimWin.hx - b; y: dimWin.hy - b
            width: dimWin.hw + 2 * b; height: dimWin.hh + 2 * b
            radius: 14 + b
            color: "transparent"
            border.width: b
            border.color: Qt.rgba(0, 0, 0, 0.88)
        }
    }
}
}
