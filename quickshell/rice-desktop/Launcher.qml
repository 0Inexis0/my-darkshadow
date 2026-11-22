import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// The DarkShadow Launcher: the app launcher of this shell (Settings > Launcher, SUPER + R, ALT + Space), in Material 3
// Expressive (LauncherM3.qml draws it) in your theme's colors and the icon style of Edit mode > Icons. V4.91: three
// styles: Drawer (big icons, filter chips, all apps in a grid), Spotlight (a search bar and a list that grows as you
// type) and Side sheet (a tall panel at the edge of the screen). This file finds things; LauncherM3.qml shows them.
// Type to search, arrows or Tab to move, Enter to open, Esc to close. "2+2" calculates and "10 km in mi" or "100 usd pln" converts (Enter copies the result),
// files in your home show after three letters ("/" in front: only files), anything else can be searched on the web. The apps you open most come first.
PanelWindow {
    screen: Mon.screen
    id: ln
    property bool open: false
    onOpenChanged: if (!open) { ctx = null; qs = false }

    // ---------- settings (rice-rofi state) ----------
    property var rs: ({})
    // the style: drawer (the old List, Grid, Split, Bar and Classic come here too), spotlight, side
    readonly property string lay: rs.layout === "spotlight" || rs.layout === "side" ? rs.layout : "drawer"
    readonly property string where: rs.position === "top" || rs.position === "bottom" ? rs.position : "center"
    readonly property real alpha: rs.transparency === false ? 1 : (rs.opacity !== undefined ? rs.opacity : 0.82)
    readonly property bool icons: rs.icons !== false
    readonly property int nlines: rs.lines ? rs.lines : 8
    readonly property string ff: Fonts.main
    readonly property bool mat: true
    NPal { id: lpal; theme: "shell"; alpha: Math.max(0.6, ln.alpha) }
    // the menus' colors (col() turns them into colors with their own see-through)
    readonly property var th: ({ bg: lpal.surface, alt: lpal.card, fg: lpal.fg, dim: lpal.dim, sel: lpal.primary, selfg: lpal.inkPrimary, bd: lpal.line })
    function col(h, a) {            // "#rrggbb" or "#rrggbbaa" (like rofi) to a color; a color stays one
        if (typeof h === "object" && h !== null) return Qt.rgba(h.r, h.g, h.b, a !== undefined ? a : h.a)
        const s = String(h).replace("#", "")
        const al = s.length >= 8 ? parseInt(s.substr(6, 2), 16) / 255 : 1
        return Qt.rgba(parseInt(s.substr(0, 2), 16) / 255, parseInt(s.substr(2, 2), 16) / 255, parseInt(s.substr(4, 2), 16) / 255, a !== undefined ? a : al)
    }

    // ---------- the apps ----------
    property string query: ""
    property var usage: ({})
    // your favorites: first in the list (and ahead in a search). Right click an app (or Ctrl + D) adds or takes it
    // away; ~/.config/rice/launcher-favs.json
    property var favs: []
    function isFav(id) { return favs.indexOf(id) >= 0 }
    function toggleFav(r) {
        if (!r || r.kind !== "app" || !r.id) return
        const l = favs.slice(), i = l.indexOf(r.id)
        if (i >= 0) l.splice(i, 1); else l.unshift(r.id)
        favs = l
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$HOME/.config/rice\" && printf '%s\\n' \"$1\" > \"$HOME/.config/rice/launcher-favs.json\"", "_", JSON.stringify(l)])
        Sfx.play("click")
        const keep = cur; recompute(); cur = Math.min(keep, Math.max(0, results.length - 1))
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/launcher-favs.json"
        printErrors: false
        onLoaded: { try { const l = JSON.parse(text()); if (Array.isArray(l)) ln.favs = l.filter(x => typeof x === "string") } catch (e) { } }
    }
    property int cur: 0
    readonly property var apps: DesktopEntries.applications.values.filter(function(e) { return !e.noDisplay })
    // the app list was read again (an app was installed or removed, rice-app wrote its entries): Quickshell deletes
    // the old entries, so the results are made again at once. Kept, they pointed at deleted entries and the whole
    // shell crashed the next time the launcher showed them (V4.85)
    onAppsChanged: Qt.callLater(recompute)
    property var results: []
    function sub(s, q) {            // letters of q appear in s in order
        let i = 0
        for (let k = 0; k < s.length && i < q.length; k++) if (s[k] === q[i]) i++
        return i === q.length
    }
    function score(e, q) {
        const n = (e.name || "").toLowerCase()
        if (n === q) return 1000
        if (n.indexOf(q) === 0) return 900 - n.length * 0.1
        if (n.indexOf(" " + q) >= 0) return 800
        const at = n.indexOf(q)
        if (at >= 0) return 700 - at
        const g = ((e.genericName || "") + " " + (e.keywords ? e.keywords.join(" ") : "")).toLowerCase()
        if (g.indexOf(q) >= 0) return 400
        if ((e.comment || "").toLowerCase().indexOf(q) >= 0) return 250
        if (q.length >= 2 && sub(n, q)) return 150
        return -1
    }
    function calc(q) {
        const s = q.replace(/^=/, "").trim()
        if (s === "" || !/^[0-9+\-*\/%^().,\s]+$/.test(s) || !/[+\-*\/%^]/.test(s.replace(/^[-+]/, ""))) return null
        try {
            const v = Function('"use strict"; return (' + s.replace(/\^/g, "**").replace(/,/g, ".") + ")")()
            if (typeof v === "number" && isFinite(v)) return String(Math.round(v * 1e10) / 1e10)
        } catch (e) { }
        return null
    }
    function recompute() {
        const q = query.trim().toLowerCase()
        const out = []
        const list = []
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i]
            const u = Math.min(usage[e.id] || 0, 30)
            const fv = favs.indexOf(e.id)
            const fb = fv >= 0 ? 100000 - fv : 0
            if (lay !== "spotlight" && cat !== "" && !inCat(e, cat, fv >= 0)) continue
            if (q === "") list.push({ e: e, s: u * 10 + fb })
            else { const sc = score(e, q); if (sc >= 0) list.push({ e: e, s: sc + u * 4 + (fv >= 0 ? 150 : 0) }) }
        }
        // the drawer and the side sheet before you type: the grid goes A to Z (the most used are the big icons above it)
        const az = lay !== "spotlight" && q === ""
        if (az) { freqList = list.slice().sort(function(a, b) { return b.s - a.s }).filter(function(x) { return x.s > 0 }).slice(0, 8).map(function(x) {
                      return { kind: "app", name: x.e.name, sub: "", entry: x.e, id: x.e.id } }) }
        list.sort(function(a, b) { return !az && b.s !== a.s ? b.s - a.s : (a.e.name || "").localeCompare(b.e.name || "") })
        const c = q !== "" ? calc(query) : null
        if (c !== null) out.push({ kind: "calc", name: "= " + c, sub: Tr.t("Press Enter to copy the result"), val: c })
        // "10 km in mi", "100 usd pln": units and money (Conv.qml; the rates are fetched only when you type money)
        if (q !== "" && /^\s*-?[\d.,]/.test(query)) {
            if (Conv.looksLikeMoney(query)) Conv.ask()
            const cvr = Conv.parse(query)
            if (cvr) out.push({ kind: "calc", name: "= " + cvr.text, sub: cvr.from + "  ·  " + Tr.t("Press Enter to copy the result"), val: cvr.val })
        }
        for (let i = 0; i < list.length && i < 80; i++)
            out.push({ kind: "app", name: list[i].e.name, sub: list[i].e.genericName || list[i].e.comment || "", entry: list[i].e, id: list[i].e.id })
        // files in your home (rice-find files), after a few letters; "/" in front: only files
        const fq = query.trim().replace(/^\//, "").trim()
        if (fq === filesFor) for (let i = 0; i < files.length; i++)
            out.push({ kind: "file", name: files[i].name, sub: files[i].where, path: files[i].path, dir: files[i].dir })
        if (q !== "") out.push({ kind: "web", name: Tr.t("Search the web for") + " \"" + query.trim() + "\"", sub: "DuckDuckGo", q: query.trim() })
        if (query.trim().indexOf("/") === 0) { for (let i = out.length - 1; i >= 0; i--) if (out[i].kind !== "file") out.splice(i, 1) }
        results = out
        resetScroll()
        cur = 0
    }
    onQueryChanged: { recompute(); fileT.restart() }

    // ---------- V4.90: Material: the filter chips, the icon style, the keys ----------
    property string cat: ""
    property var freqList: []           // Material: the apps you use most and your favorites
    onCatChanged: recompute()
    readonly property var catDefs: [
        { id: "fav", name: "Favorites", c: [] },
        { id: "net", name: "Internet", c: ["Network", "WebBrowser", "Email", "Chat", "InstantMessaging"] },
        { id: "media", name: "Media", c: ["AudioVideo", "Audio", "Video", "Music", "Player"] },
        { id: "games", name: "Games", c: ["Game"] },
        { id: "dev", name: "Development", c: ["Development", "IDE", "TextEditor"] },
        { id: "gfx", name: "Graphics", c: ["Graphics", "Photography", "2DGraphics", "3DGraphics"] },
        { id: "office", name: "Office", c: ["Office", "Education"] },
        { id: "sys", name: "System", c: ["System", "Settings", "Monitor", "PackageManager"] },
        { id: "util", name: "Utilities", c: ["Utility", "Accessories", "FileManager", "TerminalEmulator", "Archiving"] }
    ]
    function inCat(e, id, fav) {
        if (id === "fav") return fav
        let d = null
        for (let i = 0; i < catDefs.length; i++) if (catDefs[i].id === id) d = catDefs[i]
        if (!d) return true
        const c = e.categories || []
        for (let i = 0; i < c.length; i++) if (d.c.indexOf(c[i]) >= 0) return true
        return false
    }
    // the chips: All, then only those that have apps (Favorites once you have some)
    readonly property var cats: {
        const out = [{ id: "", name: "All" }]
        for (let k = 0; k < catDefs.length; k++) {
            const d = catDefs[k]
            if (d.id === "fav") { if (favs.length > 0) out.push(d); continue }
            for (let i = 0; i < apps.length; i++) if (inCat(apps[i], d.id, false)) { out.push(d); break }
        }
        return out
    }
    readonly property int mcols: m3 ? m3.cols : 6
    // the grid before you type moves by rows with up and down
    readonly property bool gridNow: lay !== "spotlight" && query.trim() === ""
    function groupName(k) { return ({ calc: "Result", app: "Apps", file: "Files", web: "The web" })[k] || "" }
    function fileIcon(r) {
        const ext = (String(r.name).split(".").pop() || "").toLowerCase()
        const m = { png: "image-x-generic", jpg: "image-x-generic", jpeg: "image-x-generic", webp: "image-x-generic", gif: "image-x-generic",
                    mp4: "video-x-generic", mkv: "video-x-generic", webm: "video-x-generic", mp3: "audio-x-generic", flac: "audio-x-generic",
                    pdf: "application-pdf", zip: "package-x-generic", gz: "package-x-generic", tar: "package-x-generic",
                    sh: "text-x-script", py: "text-x-script", qml: "text-x-script" }
        return m[ext] || "text-x-generic"
    }
    // how app icons look: Edit mode > Icons (desktop.json "icons"); "auto" is the app's own picture here
    property var iconCfg: ({})
    readonly property string iLook: iconCfg.look && iconCfg.look !== "auto" ? iconCfg.look : "original"
    readonly property string iShape: iconCfg.shape && iconCfg.shape !== "auto" && iconCfg.shape !== "none" ? iconCfg.shape : ""
    // the keys of the search field (both looks)
    function keyNav(e, inp) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0
        const grid = gridNow, cols = mcols
        if (e.key === Qt.Key_Escape) { if (ctx || qs) { ctx = null; qs = false } else if (cat !== "" && query === "") cat = ""; else hide(); e.accepted = true }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { activate(results[cur]); e.accepted = true }
        else if (ctrl && e.key === Qt.Key_D) { toggleFav(results[cur]); e.accepted = true }
        else if (lay !== "spotlight" && ctrl && e.key === Qt.Key_Tab) { const i = cats.findIndex(function(c) { return c.id === cat }); cat = cats[(i + 1) % cats.length].id; e.accepted = true }
        else if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)) || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) { move(grid && e.key === Qt.Key_Down ? cols : (grid && e.key !== Qt.Key_Tab ? cols : 1)); e.accepted = true }
        else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) { move(grid && e.key !== Qt.Key_Backtab ? -cols : -1); e.accepted = true }
        else if (grid && e.key === Qt.Key_Right && inp.cursorPosition === inp.text.length) { move(1); e.accepted = true }
        else if (grid && e.key === Qt.Key_Left && inp.cursorPosition === 0) { move(-1); e.accepted = true }
        else if (e.key === Qt.Key_PageDown) { move(grid ? cols * 3 : nlines); e.accepted = true }
        else if (e.key === Qt.Key_PageUp) { move(grid ? -cols * 3 : -nlines); e.accepted = true }
    }
    // ---------- files: asked a moment after you stop typing ----------
    property var files: []
    property string filesFor: ""
    Timer {
        id: fileT
        interval: 260
        onTriggered: {
            const fq = ln.query.trim().replace(/^\//, "").trim()
            if (fq.length < 3 && !(ln.query.trim().indexOf("/") === 0 && fq.length >= 2)) { ln.files = []; ln.filesFor = ""; return }
            if (fq === ln.filesFor) return
            if (fileP.running) { fileT.restart(); return }     // one at a time: asked again when this one is done
            fileP.want = fq
            fileP.running = true
        }
    }
    Process {
        id: fileP
        property string want: ""
        command: ["bash", "-c", "exec \"$HOME/.local/bin/rice-find\" files \"$1\" 2>/dev/null", "_", want]
        stdout: StdioCollector { onStreamFinished: {
            let l = []
            try { l = JSON.parse(text) } catch (e) { l = [] }
            if (fileP.want !== ln.query.trim().replace(/^\//, "").trim()) { fileT.restart(); return }
            ln.files = l; ln.filesFor = fileP.want
            const keep = ln.cur; ln.recompute(); ln.cur = Math.min(keep, Math.max(0, ln.results.length - 1))
        } }
    }
    Connections { target: Conv; function onRatesChanged() { if (ln.open && ln.query !== "") ln.recompute() } }
    onUsageChanged: if (open) recompute()

    // ---------- opening and closing ----------
    function show() {
        query = ""
        cat = ""
        rsProc.running = true
        usageProc.running = true
        open = true
        recompute()
        focusTimer.restart()
    }
    function hide() { open = false }
    Timer { id: focusTimer; interval: 40; onTriggered: m3.input.forceActiveFocus() }
    function bump(id) {
        const n = Object.assign({}, usage); n[id] = (n[id] || 0) + 1; usage = n
        Quickshell.execDetached(["bash", "-c", "python3 - \"$1\" <<'PY'\nimport json, os, sys\np = os.path.expanduser('~/.cache/rice/launcher-usage.json')\ntry:\n    d = json.load(open(p))\nexcept Exception:\n    d = {}\nos.makedirs(os.path.dirname(p), exist_ok=True)\nd[sys.argv[1]] = d.get(sys.argv[1], 0) + 1\njson.dump(d, open(p, 'w'))\nPY", "_", id])
    }
    function activate(r) {
        if (!r) return
        // close first (and give the keyboard back), then start the app: the new window gets the focus and the
        // launcher never stays on top of it, even if something below fails
        hide()
        try { Sfx.play("select") } catch (e) { }
        try {
            if (r.kind === "app") { r.entry.execute(); bump(r.id) }
            else if (r.kind === "calc") Quickshell.execDetached(["bash", "-c", "printf %s \"$1\" | wl-copy", "_", r.val])
            else if (r.kind === "web") Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(r.q)])
            else if (r.kind === "file") Quickshell.execDetached(["xdg-open", r.path])
        } catch (e) { console.warn("launcher: could not start " + r.name + ": " + e) }
    }
    function move(d) { if (results.length > 0) cur = Math.max(0, Math.min(results.length - 1, cur + d)) }

    // ---------- V4.87: a menu on the right click (open, favorite, pin to the dock) and quick settings (the gear) ----------
    property var ctx: null              // { r, x, y }
    property bool qs: false
    function menuFor(r, p) { if (r) { qs = false; ctx = { r: r, x: p.x, y: p.y } } }
    function setv(k, v) {
        // shown at once (as a number or a yes/no, like rice-rofi state gives them back)
        const x = v === "true" ? true : v === "false" ? false : (typeof v === "string" && /^[0-9.]+$/.test(v) ? Number(v) : v)
        const n = JSON.parse(JSON.stringify(rs)); n[k] = x; rs = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-rofi\" set \"$1\" \"$2\"", "_", k, String(v)])
    }
    // the dock's pinned apps (desktop.json), to pin and unpin from here
    property var dockApps: []
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/desktop.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const j = JSON.parse(text()); ln.dockApps = j.dock && j.dock.apps ? j.dock.apps : []; ln.iconCfg = j.icons || ({}) } catch (e) { } }
    }
    function appId(r) { return r && r.entry ? (r.entry.id || "").replace(/\.desktop$/, "") : "" }
    function onDock(r) { return dockApps.indexOf(appId(r)) >= 0 }
    function togglePin(r) {
        const id = appId(r), on = onDock(r)
        if (!id) return
        dockApps = on ? dockApps.filter(function(x) { return x !== id }) : dockApps.concat([id])
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" \"$1\" \"$2\"", "_", on ? "dock-unpin" : "dock-pin", id])
    }

    Process {
        id: rsProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-rofi\" state 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { ln.rs = JSON.parse(text) } catch (e) { console.warn("launcher: bad rice-rofi state") } } }
    }
    // the launcher settings are re-read as soon as Settings > Launcher changes them, not only when it opens
    Trigger { path: Quickshell.env("HOME") + "/.config/rice/rofi.json"; every: 3000
        onContent: function(t) { if (!rsProc.running) rsProc.running = true } }
    Process {
        id: usageProc
        command: ["bash", "-c", "cat \"$HOME/.cache/rice/launcher-usage.json\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { ln.usage = JSON.parse(text) } catch (e) { } } }
    }
    // rice-launch writes a line into this file: open it, or close it when it is already open
    Trigger { name: "launcher-open"; fresh: true; onFired: function(o) { if (ln.open) ln.hide(); else ln.show() } }

    // ---------- window ----------
    visible: open || (m3.p > 0.005 && !closeT.done)
    // if the closing animation ever stalls (the compositor sent no frames for a moment), it still goes away
    Timer { id: closeT; property bool done: false; interval: 600; running: !open; onRunningChanged: if (running) done = false; onTriggered: done = true }
    // niri: blur behind the card (Hyprland blurs this layer with its own rule)
    NiriBlur { win: ln; items: [ln.box]; radius: m3.card.radius; on: ln.open && m3.p > 0.98 }
    readonly property Item box: m3.card
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea { anchors.fill: parent; onClicked: { if (ln.ctx || ln.qs) { ln.ctx = null; ln.qs = false } else ln.hide() } }

    LauncherM3 { id: m3; ln: ln; pal: lpal }

    // smooth scrolling: the wheel and the keys move the view with an easing animation
    property bool noScroll: false
    function clampY(v, view) { return Math.max(0, Math.min(v, view.contentHeight - view.height)) }
    function glide(view, anim, y) {
        const to = clampY(y, view)
        anim.stop(); anim.from = view.contentY; anim.to = to; anim.start()
    }
    function wheel(view, anim, e, h) {
        // a touchpad: the list follows the fingers (a glide per event lagged behind them)
        if (e.pixelDelta.y !== 0) { anim.stop(); view.contentY = clampY(view.contentY - e.pixelDelta.y * 1.4, view); return }
        const d = e.angleDelta.y * 1.9
        const base = anim.running ? anim.to : view.contentY
        glide(view, anim, base - d)
    }
    function resetScroll() { if (m3) m3.reset() }
    onCurChanged: if (!noScroll) m3.follow()

    // ---------- the right-click menu ----------
    Rectangle {
        id: ctxM
        visible: ln.ctx !== null
        width: 232
        height: ctxC.implicitHeight + 12
        x: ln.ctx ? Math.min(ln.width - width - 8, ln.box.x + ln.ctx.x) : 0
        y: ln.ctx ? Math.min(ln.height - height - 8, ln.box.y + ln.ctx.y) : 0
        radius: 22
        color: ln.col(ln.th.bg, Math.min(1, ln.alpha + 0.12))
        border.width: 1; border.color: ln.col(ln.th.bd)
        MouseArea { anchors.fill: parent }
        Column {
            id: ctxC
            x: 6; y: 6
            width: parent.width - 12
            readonly property var r: ln.ctx ? ln.ctx.r : null
            readonly property bool app: !!(r && r.kind === "app")
            LItem { sym: "open_in_new"; glyph: "\uf35d"; text: Tr.t("Open"); onPicked: { const r = ctxC.r; ln.ctx = null; ln.activate(r) } }
            LItem { visible: ctxC.app; sym: "star"; glyph: "\uf005"; text: ctxC.app && ln.isFav(ctxC.r.id) ? Tr.t("Remove from favorites") : Tr.t("Add to favorites")
                onPicked: { ln.toggleFav(ctxC.r); ln.ctx = null } }
            LItem { visible: ctxC.app; sym: "keep"; glyph: "\uf08d"; text: ctxC.app && ln.onDock(ctxC.r) ? Tr.t("Unpin from the dock") : Tr.t("Pin to the dock")
                onPicked: { ln.togglePin(ctxC.r); ln.ctx = null } }
            LItem { visible: !!(ctxC.r && ctxC.r.kind === "file"); sym: "folder_open"; glyph: "\uf07c"; text: Tr.t("Open its folder")
                onPicked: { Quickshell.execDetached(["xdg-open", ctxC.r.dir]); ln.ctx = null; ln.hide() } }
        }
    }

    // ---------- quick settings (the gear) ----------
    Rectangle {
        id: qsP
        visible: ln.qs && ln.open
        width: 300
        height: qsC.implicitHeight + 28
        readonly property bool side: ln.box.x + ln.box.width + 12 + width < ln.width - 8
        x: side ? ln.box.x + ln.box.width + 12 : Math.max(8, ln.box.x + ln.box.width - width)
        y: side ? Math.max(8, Math.min(ln.height - height - 8, ln.box.y)) : Math.min(ln.height - height - 8, ln.box.y + 84)
        radius: 28
        color: ln.col(ln.th.bg, Math.min(1, ln.alpha + 0.12))
        border.width: 1; border.color: ln.col(ln.th.bd)
        opacity: visible ? 1 : 0
        MouseArea { anchors.fill: parent }
        Column {
            id: qsC
            x: 14; y: 14
            width: parent.width - 28
            spacing: 12
            DText { text: Tr.t("Launcher"); font.family: ln.ff; font.pixelSize: 16; font.weight: Font.DemiBold; color: ln.col(ln.th.fg) }
            LSeg { title: Tr.t("Style"); value: ln.lay; opts: [["drawer", Tr.t("Drawer")], ["spotlight", Tr.t("Spotlight")], ["side", Tr.t("Side sheet")]]
                onChosen: function(v) { ln.setv("layout", v) } }
            LSeg { visible: ln.lay !== "side"; title: Tr.t("Position"); value: ln.where; opts: [["top", Tr.t("Top")], ["center", Tr.t("Center")], ["bottom", Tr.t("Bottom")]]
                onChosen: function(v) { ln.setv("position", v) } }
            LSeg { title: Tr.t("Icons"); value: ln.icons ? "on" : "off"; opts: [["on", Tr.t("Shown")], ["off", Tr.t("Hidden")]]
                onChosen: function(v) { ln.setv("icons", v === "on" ? "true" : "false") } }
            LStep { title: Tr.t("Rows"); value: ln.nlines; lo: 3; hi: 14; step: 1; onPick: function(v) { ln.setv("lines", v) } }
            LStep { title: Tr.t("Width"); value: ln.rs.width || 620; lo: 360; hi: 1200; step: 40; unit: " px"; onPick: function(v) { ln.setv("width", v) } }
            LStep { title: Tr.t("See-through"); value: Math.round((1 - ln.alpha) * 100); lo: 0; hi: 70; step: 5; unit: " %"
                onPick: function(v) { ln.setv("opacity", (1 - v / 100).toFixed(2)) } }
            LItem { sym: "settings"; glyph: "\uf013"; text: Tr.t("All launcher settings")
                onPicked: { ln.hide(); Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-settings\" 7"]) } }
        }
    }

    component LItem: Rectangle {
        id: li
        property string sym: ""
        property string glyph: ""
        property string text: ""
        signal picked()
        width: parent ? parent.width : 200
        height: visible ? 40 : 0
        radius: 14
        color: lim.containsMouse ? ln.col(ln.th.alt) : "transparent"
        MIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: li.sym; glyph: li.glyph; size: 17; color: ln.col(ln.th.dim) }
        DText { x: 42; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 50; elide: Text.ElideRight
            text: li.text; font.family: ln.ff; font.pixelSize: 13; color: ln.col(ln.th.fg) }
        MouseArea { id: lim; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: li.picked() }
    }
    component LSeg: Column {
        id: ls
        property string title: ""
        property string value: ""
        property var opts: []
        signal chosen(string v)
        width: parent ? parent.width : 260
        spacing: 6
        DText { text: ls.title; font.family: ln.ff; font.pixelSize: 12; color: ln.col(ln.th.dim) }
        Rectangle {
            width: parent.width; height: 36; radius: 18
            color: ln.col(ln.th.alt)
            Row {
                anchors.fill: parent; anchors.margins: 3
                Repeater {
                    model: ls.opts
                    Rectangle {
                        id: so
                        required property var modelData
                        readonly property bool on: modelData[0] === ls.value
                        width: (ls.width - 6) / ls.opts.length; height: 30; radius: 15
                        color: on ? ln.col(ln.th.sel) : (som.containsMouse ? ln.col(ln.th.bg, 0.5) : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }
                        DText { anchors.centerIn: parent; text: so.modelData[1]; font.family: ln.ff; font.pixelSize: 12
                            font.weight: so.on ? Font.DemiBold : Font.Normal; color: so.on ? ln.col(ln.th.selfg) : ln.col(ln.th.fg) }
                        MouseArea { id: som; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ls.chosen(so.modelData[0]) }
                    }
                }
            }
        }
    }
    component LStep: Item {
        id: lst
        property string title: ""
        property int value: 0
        property int lo: 0
        property int hi: 10
        property int step: 1
        property string unit: ""
        signal pick(int v)
        width: parent ? parent.width : 260
        height: 36
        DText { anchors.verticalCenter: parent.verticalCenter; text: lst.title; font.family: ln.ff; font.pixelSize: 13; color: ln.col(ln.th.fg) }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: [-1, 0, 1]
                Item {
                    id: sb
                    required property int modelData
                    width: modelData === 0 ? 64 : 32; height: 32
                    Rectangle {
                        visible: sb.modelData !== 0
                        anchors.fill: parent; radius: 16
                        color: sbm.containsMouse ? ln.col(ln.th.sel) : ln.col(ln.th.alt)
                        opacity: (sb.modelData < 0 ? lst.value > lst.lo : lst.value < lst.hi) ? 1 : 0.35
                        MIcon { anchors.centerIn: parent; name: sb.modelData < 0 ? "remove" : "add"; glyph: sb.modelData < 0 ? "\uf068" : "\uf067"; size: 15
                            color: sbm.containsMouse ? ln.col(ln.th.selfg) : ln.col(ln.th.fg) }
                        MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: lst.pick(Math.max(lst.lo, Math.min(lst.hi, lst.value + sb.modelData * lst.step))) }
                    }
                    DText { visible: sb.modelData === 0; anchors.centerIn: parent; text: lst.value + lst.unit; font.family: ln.ff; font.pixelSize: 13; color: ln.col(ln.th.fg) }
                }
            }
        }
    }

}
