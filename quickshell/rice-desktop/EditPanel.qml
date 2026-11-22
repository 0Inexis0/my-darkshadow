import Quickshell
import Quickshell.Io
import QtQuick

// Edit mode (SUPER + ALT + W): the panel on the left. Sections that open and close:
//   Widgets         every widget as a chip: click to put it on the desktop (and select it), × takes it away
//   Quick settings  blur, transparency, colors from the wallpaper, hiding, grid, the interface font
//   Bar             style, edge, auto-hide and which modules it shows
//   Visualizer      on or off, edge, style, colors and height (cava)
//   Dock            where, its style, when it shows, sizes, the pinned apps (add, move, remove)   (V4.89)
//   Icons           how app icons look: their style, the shape they sit on, the icon pack        (V4.89)
// The dock's own menu (right click on the dock) opens it right on the Dock or Icons tab.
// It slides in from the left, its parts one after another (Material 3 emphasized-decelerate).
Item {
    id: ep
    property var ed: null                   // EditorWindow
    readonly property var root: ed ? ed.root : null
    property bool shown: false
    width: 300
    height: Math.min(parent ? parent.height - 40 : 800, col.implicitHeight + 28)

    property real t: 0
    NumberAnimation { id: tA; target: ep; property: "t"; easing.type: Easing.Linear }
    onShownChanged: {
        tA.stop(); tA.from = t; tA.to = shown ? 1 : 0; tA.duration = Math.max(1, Math.round((shown ? 680 : 240) * Math.abs(tA.to - t))); tA.start()
        if (shown && root && root.editSec !== "") openSec(root.editSec)
        if (!shown) { addOpen = false; addField.text = "" }
    }
    function ease(p) { return 1 - Math.pow(1 - p, 4) }
    readonly property real et: ease(t)
    function stg(i) { return ease(Math.max(0, Math.min(1, (t - i * 0.06) / 0.7))) }
    opacity: Math.min(1, et * 1.5)
    transform: Translate { x: (1 - ep.et) * -60 }

    NPal { id: pal; theme: "shell"; alpha: 0.93 }

    // ---------- open one tab (the dock's menu: Edit dock, Add apps, Icons) ----------
    function openSec(k) {
        const want = k === "dock-add" ? "dock" : k
        const all = [secWidgets, secQuick, secBar, viz, secDock, secIcons]
        for (let i = 0; i < all.length; i++) all[i].open = all[i].key === want
        if (k === "dock-add") { addOpen = true; addField.forceActiveFocus() }
        scrollT.want = want; scrollT.restart()
    }
    Connections { target: ep.root; function onEditSecChanged() { if (ep.root.editSec !== "" && ep.shown) ep.openSec(ep.root.editSec) } }
    // once the tabs have opened and closed: bring the one asked for into view
    Timer {
        id: scrollT
        property string want: ""
        interval: 480
        onTriggered: {
            const all = [secWidgets, secQuick, secBar, viz, secDock, secIcons]
            for (let i = 0; i < all.length; i++) if (all[i].key === want) {
                // Add apps: the search field and what it finds, else the tab's top
                const y = ep.addOpen && want === "dock" ? addBox.mapToItem(col, 0, 0).y - 120 : all[i].y - 4
                scrollA.to = Math.max(0, Math.min(y, flick.contentHeight - flick.height)); scrollA.restart()
            }
        }
    }
    NumberAnimation { id: scrollA; target: flick; property: "contentY"; duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph }

    // ---------- the dock (Dock.qml) and the icons ----------
    readonly property var dk: root ? root.dockRef : null
    readonly property var iconCfg: root ? root.iconCfg : ({})
    function cap(w) { w = String(w || ""); return w.charAt(0).toUpperCase() + w.slice(1) }
    function lookName(l) { return ({ original: "Original", tinted: "Wallpaper", grey: "Grey", themed: "Themed", filled: "Filled", mono: "Mono" })[l] || "Original" }
    function settingsPage(n) { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-settings\" \"$1\"", "_", String(n)]) }
    function setIcons(k, v) {
        if (!root) return
        const c = JSON.parse(JSON.stringify(root.cfg))
        c.icons = Object.assign({ look: "auto", shape: "auto", theme: "" }, c.icons || {})
        c.icons[k] = k === "theme" && v === "none" ? "" : v
        root.cfg = c                         // at once; desktop.json says the same a moment later
        ds(["icons", k, v])
    }
    function entryId(e) { return String(e.id || "").replace(/\.desktop$/, "") }
    function pinnedId(e) { return !!dk && (dk.dc.apps || []).indexOf(entryId(e)) >= 0 }
    function pinEntry(e) { const id = entryId(e); if (!dk || id === "" || pinnedId(e)) return; dk.setApps((dk.dc.apps || []).concat([id])) }
    function unpinApp(id) { if (dk) dk.setApps((dk.dc.apps || []).filter(function(x) { return x !== id })) }
    // the dock's order (V4.94): a part one step to the left or right; past your apps it lands on their other side
    function moveMod(i, d) {
        const l = (dk.order || []).slice(), j = i + d
        if (j < 0 || j >= l.length) return
        const x = l[i]; l[i] = l[j]; l[j] = x
        dk.setKey("mods", l.join(","))
    }
    function moveApp(i, d) {
        const l = (dk.dc.apps || []).slice(), j = i + d
        if (j < 0 || j >= l.length) return
        const x = l[i]; l[i] = l[j]; l[j] = x
        dk.setApps(l)
    }
    property bool addOpen: false
    property string q: ""
    readonly property var found: {
        if (!addOpen) return []
        const s = q.trim().toLowerCase()
        const all = DesktopEntries.applications.values
        const out = []
        for (let i = 0; i < all.length; i++) {
            const e = all[i]
            if (!e || e.noDisplay) continue
            if (s === "" || String(e.name || "").toLowerCase().indexOf(s) >= 0 || String(e.id || "").toLowerCase().indexOf(s) >= 0) out.push(e)
        }
        out.sort(function(a, b) { return String(a.name).localeCompare(String(b.name)) })
        return out.slice(0, s === "" ? 8 : 14)
    }
    // a few apps to show the icon looks on: the dock's, then some well known ones
    readonly property var samples: {
        const out = [], seen = {}
        const it = dk && dk.items ? dk.items : []
        for (let i = 0; i < it.length && out.length < 5; i++) {
            const x = it[i]
            if (seen[x.key]) continue
            seen[x.key] = true
            out.push({ n: x.entry ? (x.entry.icon || x.key) : x.key, k: [x.key, x.entry ? x.entry.id : ""] })
        }
        const def = ["firefox", "org.gnome.Nautilus", "kitty", "spotify", "discord"]
        for (let j = 0; j < def.length && out.length < 5; j++) if (!seen[def[j]]) out.push({ n: def[j], k: [def[j]] })
        return out
    }
    // the icon packs of this computer (iconthemes.sh), looked up when the Icons tab opens
    property var packs: []
    property bool packsBusy: false
    function packName(id) { for (let i = 0; i < packs.length; i++) if (packs[i].id === id) return packs[i].name; return id }
    function loadPacks() { if (!packP.running) { packsBusy = true; packP.running = true } }
    Process {
        id: packP
        command: ["bash", Quickshell.shellPath("iconthemes.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                text.split("\n").forEach(function(l) {
                    const p = l.split("\t")
                    if (p.length >= 6 && p[0] !== "") out.push({ id: p[0], name: p[1], f: p.slice(2, 6).filter(function(x) { return x !== "" }) })
                })
                out.sort(function(a, b) { return a.name.localeCompare(b.name) })
                ep.packs = out
                ep.packsBusy = false
            }
        }
    }
    function ds(args) { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/desktop-set"].concat(args.map(function(a) { return String(a) }))) }
    function bar(args) { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-bar"].concat(args.map(function(a) { return String(a) }))) }
    function fontSet(f) { Quickshell.execDetached(["bash", "-c", "for k in main title numbers reading; do \"$HOME/.local/bin/font-set\" set $k \"$1\" >/dev/null 2>&1; done", "_", f]) }

    // ---------- the bar's settings (bar.json) ----------
    property var bc: ({})
    Trigger {
        path: Quickshell.env("HOME") + "/.config/rice/bar.json"
        every: 2000
        onContent: function(t) { try { ep.bc = t.trim() !== "" ? JSON.parse(t) : {} } catch (e) { } }
    }
    readonly property var modules: [
        { k: "launcher", n: "Launcher", i: "apps", g: "" }, { k: "workspaces", n: "Workspaces", i: "view_week", g: "" },
        { k: "title", n: "Window", i: "title", g: "" }, { k: "media", n: "Music", i: "music_note", g: "" },
        { k: "tray", n: "Tray", i: "more_horiz", g: "" },
        { k: "volume", n: "Volume", i: "volume_up", g: "" }, { k: "network", n: "Wi-Fi", i: "wifi", g: "" },
        { k: "bluetooth", n: "Bluetooth", i: "bluetooth", g: "" }, { k: "battery", n: "Battery", i: "battery_full", g: "" },
        { k: "notifications", n: "Notifications", i: "notifications", g: "" }, { k: "power", n: "Power", i: "power_settings_new", g: "" },
        { k: "island", n: "Island (clock)", i: "schedule", g: "" }
    ]
    function lay() { return bc.layout ? bc.layout : { left: ["launcher", "workspaces", "title"], center: ["island"], right: ["music", "tray", "volume", "bluetooth", "network", "battery", "notifications", "power"] } }
    function hasMod(k) { const l = lay(); return (l.left || []).indexOf(k) >= 0 || (l.center || []).indexOf(k) >= 0 || (l.right || []).indexOf(k) >= 0 }
    function toggleMod(k) {
        const l = JSON.parse(JSON.stringify(lay()))
        if (hasMod(k)) { ["left", "center", "right"].forEach(function(z) { l[z] = (l[z] || []).filter(function(x) { return x !== k }) }); bar(["layout-set", JSON.stringify({ left: l.left, center: l.center, right: l.right })]) }
        else bar(["layout-add", "right", k])
        const n = JSON.parse(JSON.stringify(bc)); if (hasMod(k)) n.layout = l; else { n.layout = l; n.layout.right = (n.layout.right || []).concat([k]) } bc = n
    }
    function setBar(k, v) { const n = Object.assign({}, bc); n[k] = v; bc = n; bar(["set", k, typeof v === "boolean" ? (v ? "on" : "off") : v]) }

    // ---------- pieces ----------
    component Section: Item {
        id: sec
        property string title: ""
        property string sub: ""
        property string key: ""
        property string icon: ""
        property string glyph: ""
        property bool open: false
        property int order: 0
        default property alias content: inner.data
        width: col.width
        height: head.height + (open ? inner.implicitHeight + 14 : 0)
        clip: true
        Behavior on height { NumberAnimation { duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
        opacity: ep.stg(sec.order); transform: Translate { x: (1 - ep.stg(sec.order)) * -30 }
        Rectangle { anchors.fill: parent; radius: Look.sq ? 0 : (22); color: sec.open ? pal.card : (hm.containsMouse ? pal.card : Qt.rgba(1, 1, 1, 0.03))
            Behavior on color { ColorAnimation { duration: 200 } } }
        Item {
            id: head
            width: parent.width; height: 58
            Item {
                x: 12; anchors.verticalCenter: parent.verticalCenter; width: 36; height: 36
                Blob { anchors.fill: parent; kind: sec.open ? Look.shape : "circle"; color: sec.open ? pal.primary : pal.container
                    SlowSpin { turn: 360; period: 30000; running: sec.open && ep.shown && !Look.lite } }
                MIcon { anchors.centerIn: parent; size: 17; name: sec.icon; glyph: sec.glyph; filled: sec.open; color: sec.open ? pal.inkPrimary : pal.inkContainer }
            }
            Column {
                x: 58; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 58 - 40
                Text { text: sec.title; color: pal.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: sec.sub; color: pal.dim; font.family: Fonts.main; font.pixelSize: 11 }
            }
            MIcon { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; size: 20; name: "expand_more"; glyph: ""; color: pal.dim
                rotation: sec.open ? 180 : 0; Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } } }
            MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sec.open = !sec.open }
        }
        Column {
            id: inner
            x: 12; y: head.height
            width: parent.width - 24
            spacing: 8
            opacity: sec.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
    }
    component Switchy: Item {
        id: sw
        property string label: ""
        property bool on: false
        signal flipped(bool v)
        width: parent ? parent.width : 200; height: 36
        Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60; elide: Text.ElideRight; text: sw.label; color: pal.fg; font.family: Fonts.main; font.pixelSize: 12 }
        Rectangle {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: 46; height: 28; radius: Look.sq ? 0 : (14)
            color: sw.on ? pal.primary : pal.cardHi
            Behavior on color { ColorAnimation { duration: 180 } }
            Rectangle {
                width: sw.on ? 20 : 14; height: width; radius: Look.sq ? 0 : (width / 2)
                anchors.verticalCenter: parent.verticalCenter
                x: sw.on ? parent.width - width - 4 : 7
                color: sw.on ? pal.inkPrimary : pal.dim
                Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.flipped(!sw.on) }
        }
    }
    component Pills: Flow {
        id: pls
        property var options: []          // [[value, label], ...]
        property string current: ""
        signal chosen(string v)
        width: parent ? parent.width : 200
        spacing: 4
        Repeater {
            model: pls.options
            delegate: Rectangle {
                readonly property bool on: pls.current === modelData[0]
                width: pt.implicitWidth + 22; height: 30
                radius: Look.sq ? 0 : (on ? 15 : 9)
                color: on ? pal.primary : (pm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                Behavior on color { ColorAnimation { duration: 160 } }
                Text { id: pt; anchors.centerIn: parent; text: modelData[1]; color: parent.on ? pal.inkPrimary : pal.fg; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pls.chosen(modelData[0]) }
            }
        }
    }
    component Label: Text { color: pal.dim; font.family: Fonts.main; font.pixelSize: 11; topPadding: 4 }
    // a slider: its name and value above, the track below (Material 3: the handle is a bar with room on both sides)
    component Slide: Item {
        id: sl
        property string label: ""
        property string unit: ""
        property real value: 0
        property real lo: 0
        property real hi: 100
        property bool drag: false
        property real live: 0
        readonly property real cur: drag ? live : value
        readonly property real f: Math.max(0, Math.min(1, (cur - lo) / Math.max(1, hi - lo)))
        signal moved(real v)
        signal done(real v)
        width: parent ? parent.width : 200
        height: 50
        Text { y: 2; text: sl.label; color: pal.fg; font.family: Fonts.main; font.pixelSize: 12 }
        Text { anchors.right: parent.right; y: 2; text: Math.round(sl.cur) + sl.unit; color: sl.drag ? pal.primary : pal.dim
            font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium }
        Item {
            id: tr
            y: 24; width: parent.width; height: 20
            readonly property real hx: 2 + (width - 4) * sl.f
            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: 0; width: Math.max(0, tr.hx - 6); height: 14; color: pal.primary
                topLeftRadius: Look.sq ? 0 : (7); bottomLeftRadius: Look.sq ? 0 : (7); topRightRadius: Look.sq ? 0 : (3); bottomRightRadius: Look.sq ? 0 : (3) }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: tr.hx + 6; width: Math.max(0, tr.width - x); height: 14; color: pal.cardHi
                topRightRadius: Look.sq ? 0 : (7); bottomRightRadius: Look.sq ? 0 : (7); topLeftRadius: Look.sq ? 0 : (3); bottomLeftRadius: Look.sq ? 0 : (3) }
            Rectangle { x: tr.hx - 2; anchors.verticalCenter: parent.verticalCenter; width: 4; height: sl.drag ? 26 : 22; radius: Look.sq ? 0 : (2); color: pal.primary
                Behavior on height { NumberAnimation { duration: 160 } } }
        }
        MouseArea {
            anchors.fill: tr; anchors.topMargin: -8; anchors.bottomMargin: -6
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function at(x) { return sl.lo + Math.max(0, Math.min(1, x / width)) * (sl.hi - sl.lo) }
            onPressed: function(m) { sl.live = at(m.x); sl.drag = true; sl.moved(sl.live) }
            onPositionChanged: function(m) { if (pressed) { sl.live = at(m.x); sl.moved(sl.live) } }
            onReleased: { sl.drag = false; sl.done(sl.live) }
        }
    }
    // a choice of three with a little screen each that shows it (the dock's position, its style)
    component MiniTiles: Row {
        id: mt
        property var options: []           // [[value, label], ...]
        property string current: ""
        property string kind: "pos"         // pos | style
        property string edge: "bottom"
        property string sty: "floating"
        signal chosen(string v)
        width: parent ? parent.width : 276
        spacing: 6
        Repeater {
            model: mt.options
            delegate: Rectangle {
                id: tl
                required property var modelData
                readonly property bool on: mt.current === modelData[0]
                readonly property string e: mt.kind === "pos" ? modelData[0] : mt.edge
                readonly property string st: mt.kind === "style" ? modelData[0] : mt.sty
                width: (mt.width - mt.spacing * (mt.options.length - 1)) / Math.max(1, mt.options.length)
                height: 80
                radius: Look.sq ? 0 : (on ? 22 : 14)
                color: on ? pal.container : (tm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                border.width: on ? 2 : 0; border.color: pal.primary
                Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                Behavior on color { ColorAnimation { duration: 160 } }
                scale: tm.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
                Rectangle {
                    id: scr
                    x: 10; y: 10; width: parent.width - 20; height: 40; radius: Look.sq ? 0 : (10)
                    color: Qt.rgba(0, 0, 0, 0.3)
                    clip: true
                    readonly property bool v: tl.e !== "bottom"
                    readonly property bool full: tl.st === "full"
                    readonly property color ink: tl.on ? pal.primary : pal.dim
                    Rectangle {
                        readonly property real len: scr.v ? (scr.full ? scr.height : scr.height * 0.7) : (scr.full ? scr.width : scr.width * 0.62)
                        width: scr.v ? 8 : len
                        height: scr.v ? len : 8
                        x: scr.v ? (tl.e === "left" ? (scr.full ? 0 : 3) : scr.width - width - (scr.full ? 0 : 3)) : (scr.width - width) / 2
                        y: scr.v ? (scr.height - height) / 2 : scr.height - height - (scr.full ? 0 : 3)
                        radius: Look.sq ? 0 : (scr.full ? 0 : 4)
                        color: tl.st === "pills" ? "transparent" : scr.ink
                        Grid {
                            anchors.centerIn: parent
                            columns: scr.v ? 1 : 4
                            spacing: tl.st === "pills" ? 2 : 3
                            Repeater {
                                model: 4
                                Rectangle { width: tl.st === "pills" ? 6 : 3; height: width; radius: Look.sq ? 0 : (tl.st === "pills" ? 2 : 1.5)
                                    color: tl.st === "pills" ? scr.ink : (tl.on ? pal.inkPrimary : pal.surface) }
                            }
                        }
                    }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; y: 56; text: Tr.t(tl.modelData[1])
                    color: tl.on ? pal.inkContainer : pal.fg; font.family: Fonts.main; font.pixelSize: 12; font.weight: tl.on ? Font.DemiBold : Font.Normal }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mt.chosen(tl.modelData[0]) }
            }
        }
    }
    // a small round button (move a pinned app, take it off)
    component TinyBtn: Rectangle {
        id: tb
        property string sym: ""
        property string glyph: ""
        property bool danger: false
        property bool dimmed: false
        signal picked()
        width: 30; height: 30; radius: Look.sq ? 0 : (15)
        color: tbm.containsMouse && !dimmed ? (danger ? Qt.rgba(1, 0.35, 0.35, 0.22) : pal.cardHi) : "transparent"
        opacity: dimmed ? 0.3 : 1
        MIcon { anchors.centerIn: parent; size: 15; name: tb.sym; glyph: tb.glyph; color: tb.danger ? "#ffb4ab" : pal.fg }
        MouseArea { id: tbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (!tb.dimmed) tb.picked() }
    }
    // a link at the end of a tab
    component LinkRow: Rectangle {
        id: lr
        property string text: ""
        property string sym: "open_in_new"
        property string glyph: String.fromCodePoint(0xF03CC)
        signal picked()
        width: lrr.implicitWidth + 28; height: 34; radius: Look.sq ? 0 : (17)
        color: lrm.containsMouse ? pal.cardHi : "transparent"
        Row { id: lrr; anchors.centerIn: parent; spacing: 6
            MIcon { size: 15; name: lr.sym; glyph: lr.glyph; color: pal.primary; anchors.verticalCenter: parent.verticalCenter }
            Text { text: lr.text; color: pal.primary; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter } }
        MouseArea { id: lrm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lr.picked() }
    }

    // ---------- the panel ----------
    Shadow { anchors.fill: bgr; radius: Look.sq ? 0 : (bgr.radius); on: Look.shadows && Look.shadowPanels }
    Rectangle {
        id: bgr
        anchors.fill: parent
        radius: Look.sq ? 0 : (28)
        color: pal.surface
        border.width: 1; border.color: pal.line
        MouseArea { anchors.fill: parent }     // clicks here do not deselect the widget
    }
    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 14
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Column {
            id: col
            width: parent.width
            spacing: 8

            // ---- header
            Item {
                width: parent.width; height: 52
                opacity: ep.stg(0); transform: Translate { x: (1 - ep.stg(0)) * -30 }
                Item {
                    width: 44; height: 44; anchors.verticalCenter: parent.verticalCenter
                    Blob { anchors.fill: parent; kind: Look.shape; color: pal.primary
                        SlowSpin { turn: 360; period: 24000; running: ep.shown && !Look.lite } }
                    MIcon { anchors.centerIn: parent; size: 20; name: "edit"; glyph: ""; filled: true; color: pal.inkPrimary }
                }
                Column {
                    x: 56; anchors.verticalCenter: parent.verticalCenter
                    Text { text: Tr.t("Edit mode"); color: pal.fg; font.family: Fonts.title; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Text { text: Tr.t("Customize your desktop"); color: pal.dim; font.family: Fonts.main; font.pixelSize: 11 }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: Look.sq ? 0 : (dm.pressed ? 12 : 20)
                    color: dm.containsMouse ? pal.primary : pal.card
                    Behavior on radius { NumberAnimation { duration: 200 } }
                    MIcon { anchors.centerIn: parent; size: 20; name: "check"; glyph: ""; color: dm.containsMouse ? pal.inkPrimary : pal.fg }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ep.root.finishEditing() }
                }
            }

            // ---- widgets
            Section {
                id: secWidgets
                key: "widgets"
                order: 1
                open: true
                icon: "widgets"; glyph: ""; title: Tr.t("Widgets")
                sub: {
                    if (!ep.root) return ""
                    let n = 0; const c = ep.root.catalog
                    for (let i = 0; i < c.length; i++) if (ep.root.enabledOf(c[i].id)) n++
                    return n + " / " + c.length + Tr.t(" on  ·  click to add, × to remove")
                }
                // V4.93: tiles, three in a row (15 widgets: the ones that were nearly the same are one now, with styles)
                Grid {
                    width: parent.width
                    columns: 3
                    spacing: 6
                    Repeater {
                        model: ep.root ? ep.root.catalog : []
                        delegate: Rectangle {
                            id: wc
                            required property var modelData
                            readonly property bool on: ep.root.enabledOf(modelData.id)
                            readonly property bool picked: ep.ed.sel === modelData.id || (ep.ed.sel !== "" && ep.root.famOf(ep.ed.sel) === modelData.id)
                            width: (parent.width - 12) / 3; height: 70
                            radius: Look.sq ? 0 : (wc.on ? 20 : 14)
                            color: wc.picked ? pal.primary : (wc.on ? pal.container : (wm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05)))
                            Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                            Behavior on color { ColorAnimation { duration: 180 } }
                            scale: wm.pressed ? 0.94 : 1
                            Behavior on scale { NumberAnimation { duration: 140 } }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 14; text: wc.modelData.icon; font.family: Fonts.icons; font.pixelSize: 19
                                color: wc.picked ? pal.inkPrimary : (wc.on ? pal.inkContainer : pal.fg) }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 43; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                text: Tr.t(wc.modelData.name); font.family: Fonts.main; font.pixelSize: 11
                                color: wc.picked ? pal.inkPrimary : (wc.on ? pal.inkContainer : pal.fg) }
                            MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ep.ed.pick(wc.modelData.id) }
                            // on: a small × in the corner takes it away
                            Rectangle {
                                visible: wc.on
                                x: parent.width - 22; y: 4
                                width: 18; height: 18; radius: Look.sq ? 0 : (9)
                                color: xm.containsMouse ? Qt.rgba(1, 0.4, 0.4, 0.55) : (wc.picked ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(1, 1, 1, 0.12))
                                MIcon { anchors.centerIn: parent; size: 11; name: "close"; glyph: "\uf00d"; color: wc.picked ? pal.inkPrimary : pal.inkContainer }
                                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { ep.root.removeWidget(wc.modelData.id); if (wc.picked) ep.ed.sel = "" } }
                            }
                        }
                    }
                }
            }

            // ---- quick settings
            Section {
                id: secQuick
                key: "quick"
                order: 2
                icon: "tune"; glyph: ""; title: Tr.t("Quick settings")
                sub: (Look.blur ? Tr.t("Blur") : Tr.t("No blur")) + "  ·  " + Math.round(Look.widgetAlpha * 100) + "%  ·  " + Fonts.main
                Switchy { label: Tr.t("Blur behind widgets"); on: Look.blur; onFlipped: function(v) { Look.blur = v; ep.ds(["widgets-blur", v ? "on" : "off"]) } }
                Label { text: Tr.t("Transparency") + "  ·  " + Math.round((1 - Look.widgetAlpha) * 100) + "%" }
                Pills { options: [["1", "Solid"], ["0.8", "Light"], ["0.6", "Medium"], ["0.4", "Strong"]]
                    current: String(Look.widgetAlpha >= 0.95 ? "1" : (Look.widgetAlpha >= 0.7 ? "0.8" : (Look.widgetAlpha >= 0.5 ? "0.6" : "0.4")))
                    onChosen: function(v) { Look.widgetAlpha = Number(v); ep.ds(["widgets-opacity", v]) } }
                Switchy { label: Tr.t("Colors follow the wallpaper"); on: Look.adapt; onFlipped: function(v) { Look.adapt = v; ep.ds(["widgets-adapt", v ? "on" : "off"]) } }
                Switchy { label: Tr.t("Hide while windows are open"); on: ep.root ? ep.root.cfg.autoHide === true : false; onFlipped: function(v) { ep.ds(["auto-hide", v ? "on" : "off"]) } }
                Switchy { label: Tr.t("Snap to a grid"); on: ep.ed ? ep.ed.grid : false; onFlipped: function(v) { ep.ed.grid = v } }
                Label { text: Tr.t("Font") }
                Pills { options: [["Google Sans Flex", "Google Sans"], ["Rubik", "Rubik"], ["Inter", "Inter"], ["Outfit", "Outfit"]]; current: Fonts.main
                    onChosen: function(v) { ep.fontSet(v) } }
                Item { width: 1; height: 2 }
                Rectangle {
                    width: rt.implicitWidth + 30; height: 34; radius: Look.sq ? 0 : (17); color: rm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05)
                    Row { id: rt; anchors.centerIn: parent; spacing: 6
                        MIcon { size: 15; name: "restart_alt"; glyph: ""; color: pal.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: Tr.t("Reset all positions"); color: pal.fg; font.family: Fonts.main; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ep.root.resetAll(); ep.ed.sel = "" } }
                }
            }

            // ---- the bar
            Section {
                id: secBar
                key: "bar"
                order: 3
                icon: "toolbar"; glyph: ""; title: Tr.t("Bar")
                sub: (ep.bc.style || "islands") + "  ·  " + (ep.bc.position || "top") + (ep.bc.autohide === true ? Tr.t("  ·  auto-hide") : "")
                Label { text: Tr.t("Style") }
                Pills { options: [["flat", "Flat"], ["island", "Island"], ["islands", "Islands"], ["pills", "Pills"], ["notch", "Notch"], ["dynamic", "Dynamic"], ["edge", "Edge"]]; current: ep.bc.style === "google" ? "dynamic" : (ep.bc.style || "islands")
                    onChosen: function(v) { ep.setBar("style", v) } }
                Label { text: Tr.t("Edge") }
                Pills { options: [["top", "Top"], ["bottom", "Bottom"], ["left", "Left"], ["right", "Right"]]; current: ep.bc.position || "top"; onChosen: function(v) { ep.setBar("position", v) } }
                Switchy { label: Tr.t("Auto-hide"); on: ep.bc.autohide === true; onFlipped: function(v) { ep.setBar("autohide", v) } }
                Label { text: Tr.t("Modules (click to show or hide)") }
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 6
                    Repeater {
                        model: ep.modules
                        delegate: Rectangle {
                            readonly property bool on: ep.hasMod(modelData.k)
                            width: (parent.width - 6) / 2; height: 34
                            radius: Look.sq ? 0 : (on ? 17 : 10)
                            color: on ? pal.container : (mm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                            Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                            MIcon { x: 10; anchors.verticalCenter: parent.verticalCenter; size: 15; name: modelData.i; glyph: modelData.g; filled: parent.on; color: parent.on ? pal.inkContainer : pal.dim }
                            Text { x: 32; width: parent.width - 40; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: modelData.n
                                color: parent.on ? pal.inkContainer : pal.fg; font.family: Fonts.main; font.pixelSize: 12 }
                            MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ep.toggleMod(modelData.k) }
                        }
                    }
                }
            }

            // ---- the visualizer (cava)
            Section {
                id: viz
                key: "visualizer"
                order: 4
                readonly property var w: ep.root && ep.root.wins["visualizer"] ? ep.root.wins["visualizer"] : null
                readonly property bool vOn: ep.root ? ep.root.enabledOf("visualizer") : false
                icon: "graphic_eq"; glyph: ""; title: Tr.t("Visualizer")
                sub: vOn ? ((viz.w && viz.w.flp ? Tr.t("Top") : Tr.t("Bottom")) + "  ·  " + (ep.root ? ep.root.styleOf("visualizer") : "")) : Tr.t("Off")
                Switchy { label: Tr.t("On"); on: viz.vOn; onFlipped: function(v) { if (v) ep.root.addWidget("visualizer"); else ep.root.removeWidget("visualizer") } }
                Label { text: Tr.t("Screen edge") }
                Pills { options: [["bottom", "Bottom"], ["top", "Top"]]; current: viz.w && viz.w.flp ? "top" : "bottom"
                    onChosen: function(v) {
                        const w = viz.w; if (!w) return
                        w.flp = v === "top"; w.py = v === "top" ? 0 : ep.root.sh - w.fh
                        ep.root.wset("visualizer", "flip", w.flp ? "on" : "off"); ep.root.saveGeom("visualizer")
                    } }
                Label { text: Tr.t("Style") }
                Pills { options: [["bars", "Bars"], ["mirror", "Mirror"], ["wave", "Wave"], ["dots", "Dots"]]; current: ep.root ? ep.root.styleOf("visualizer") : "bars"
                    onChosen: function(v) { ep.root.setStyle("visualizer", v) } }
                Label { text: Tr.t("Colors") }
                Pills { options: [["accent", "Theme"], ["gradient", "Gradient"], ["rainbow", "Rainbow"], ["mono", "Mono"]]
                    current: ep.root ? ep.root.optOf("visualizer", "color", "accent") : "accent"
                    onChosen: function(v) { ep.root.setOpt("visualizer", "color", v) } }
                Label { text: Tr.t("Bars") }
                Pills { options: [["16", "16"], ["32", "32"], ["48", "48"], ["64", "64"]]
                    current: ep.root ? String(ep.root.optOf("visualizer", "bars", 64)) : "64"
                    onChosen: function(v) { ep.root.setOpt("visualizer", "bars", v) } }
                Label { text: Tr.t("How high they go") }
                Pills { options: [["1", "Calm"], ["1.4", "Normal"], ["2", "High"], ["2.8", "Max"]]
                    current: ep.root ? String(ep.root.optOf("visualizer", "gain", "1.4")) : "1.4"
                    onChosen: function(v) { ep.root.setOpt("visualizer", "gain", v) } }
                Label { text: Tr.t("Bar ends") }
                Pills { options: [["square", "Square"], ["rounded", "Rounded"], ["pill", "Pill"]]
                    current: ep.root ? ep.root.optOf("visualizer", "shape", "square") : "square"
                    onChosen: function(v) { ep.root.setOpt("visualizer", "shape", v) } }
                Label { text: Tr.t("Space between") }
                Pills { options: [["thin", "Thin"], ["normal", "Normal"], ["wide", "Wide"]]
                    current: ep.root ? ep.root.optOf("visualizer", "gap", "normal") : "normal"
                    onChosen: function(v) { ep.root.setOpt("visualizer", "gap", v) } }
                Label { text: Tr.t("Height  ·  ") + Math.round(viz.w ? viz.w.fh : 180) + Tr.t(" px") }
                Item {
                    width: parent.width; height: 30
                    readonly property real f: viz.w ? Math.max(0, Math.min(1, (viz.w.fh - 60) / 640)) : 0.2
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 10; radius: Look.sq ? 0 : (5); color: pal.cardHi }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.max(10, parent.width * parent.f); height: 10; radius: Look.sq ? 0 : (5); color: pal.primary }
                    Rectangle { x: parent.width * parent.f - 2; anchors.verticalCenter: parent.verticalCenter; width: 4; height: 24; radius: Look.sq ? 0 : (2); color: pal.primary }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        function set(x) {
                            const w = viz.w; if (!w) return
                            const h = Math.round(60 + Math.max(0, Math.min(1, x / width)) * 640)
                            w.fh = h; if (!w.flp) w.py = ep.root.sh - h
                        }
                        onPressed: function(m) { set(m.x) }
                        onPositionChanged: function(m) { if (pressed) set(m.x) }
                        onReleased: ep.root.saveGeom("visualizer")
                    }
                }
            }

            // ---- the dock (V4.89; it was a window of its own before)
            Section {
                id: secDock
                key: "dock"
                order: 5
                readonly property var d: ep.dk ? ep.dk.dc : ({})
                icon: "dock_to_bottom"; glyph: String.fromCodePoint(0xF10A9); title: Tr.t("Dock")
                sub: !ep.dk || !ep.dk.on ? Tr.t("Off") : (Tr.t(ep.cap(ep.dk.edge)) + "  ·  " + Tr.t(ep.cap(ep.dk.style)) + "  ·  " + (secDock.d.apps || []).length + Tr.t(" pinned"))
                Switchy { label: Tr.t("Show the dock"); on: !!ep.dk && ep.dk.on; onFlipped: function(v) { ep.dk.setKey("enabled", v) } }
                Label { text: Tr.t("Position") }
                MiniTiles { kind: "pos"; options: [["bottom", "Bottom"], ["left", "Left"], ["right", "Right"]]
                    current: ep.dk ? ep.dk.edge : "bottom"; edge: current; sty: ep.dk ? ep.dk.style : "floating"
                    onChosen: function(v) { ep.dk.setKey("position", v) } }
                Label { text: Tr.t("Style") }
                MiniTiles { kind: "style"; options: [["floating", "Floating"], ["pills", "Pills"], ["full", "Full"]]
                    current: ep.dk ? ep.dk.style : "floating"; edge: ep.dk ? ep.dk.edge : "bottom"; sty: current
                    onChosen: function(v) { ep.dk.setKey("style", v) } }
                Label { text: Tr.t("When it shows") }
                Pills { options: [["always", Tr.t("Always")], ["auto", Tr.t("When the pointer comes")]]
                    current: secDock.d.hover !== false ? "auto" : "always"
                    onChosen: function(v) { ep.dk.setKey("hover", v === "auto") } }
                Slide { label: Tr.t("Icon size"); unit: " px"; lo: 24; hi: 64; value: ep.dk ? ep.dk.icon : 34
                    onMoved: function(v) { ep.dk.preview("iconSize", Math.round(v)) }
                    onDone: function(v) { ep.dk.setKey("iconSize", Math.round(v)) } }
                Slide { label: Tr.t("Space between apps"); unit: " px"; lo: 0; hi: 24; value: ep.dk ? ep.dk.gap : 6
                    onMoved: function(v) { ep.dk.preview("gap", Math.round(v)) }
                    onDone: function(v) { ep.dk.setKey("gap", Math.round(v)) } }
                Slide { label: Tr.t("See-through"); unit: " %"; lo: 0; hi: 80
                    value: Math.round((1 - (secDock.d.opacity !== undefined ? Number(secDock.d.opacity) : 0.78)) * 100)
                    onMoved: function(v) { ep.dk.preview("opacity", (1 - Math.round(v) / 100).toFixed(2)) }
                    onDone: function(v) { ep.dk.setKey("opacity", (1 - Math.round(v) / 100).toFixed(2)) } }
                Slide { label: Tr.t("Magnify under the pointer"); unit: " %"; lo: 0; hi: 100; value: secDock.d.magnify !== undefined ? Number(secDock.d.magnify) : 0
                    onMoved: function(v) { ep.dk.preview("magnify", Math.round(v / 5) * 5) }
                    onDone: function(v) { ep.dk.setKey("magnify", Math.round(v / 5) * 5) } }
                Label { text: Tr.t("Modules") + "  ·  " + Tr.t("like the icons of a phone's status bar") }
                Grid {
                    width: parent.width
                    columns: 3
                    spacing: 6
                    Repeater {
                        model: [["pin", "Pin", "keep", 0xF0403], ["launcher", "All apps", "apps", 0xF003B], ["music", "Music", "music_note", 0xF075A], ["clock", "Clock", "schedule", 0xF0954], ["battery", "Battery", "battery_full", 0xF0079],
                                ["volume", "Volume", "volume_up", 0xF057E], ["network", "Wi-Fi", "wifi", 0xF05A9], ["bluetooth", "Bluetooth", "bluetooth", 0xF00AF],
                                ["weather", "Weather", "partly_cloudy_day", 0xF0595], ["sysmon", "CPU & RAM", "memory", 0xF035B], ["search", "App search", "search", 0xF0349],
                                ["notifications", "Notifications", "notifications", 0xF009A], ["control", "Control center", "tune", 0xF062E], ["power", "Session", "power_settings_new", 0xF0425]]
                        delegate: Rectangle {
                            id: mt
                            required property var modelData
                            readonly property var cur: ep.dk ? ep.dk.order : []
                            readonly property int at: cur.filter(function(x) { return x !== "apps" }).indexOf(modelData[0])
                            readonly property bool on: at >= 0
                            width: (parent.width - 12) / 3; height: 70
                            radius: Look.sq ? 0 : (on ? 20 : 14)
                            color: on ? pal.container : (mtm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                            border.width: on ? 2 : 0; border.color: pal.primary
                            Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: mtm.pressed ? 0.94 : 1
                            Behavior on scale { NumberAnimation { duration: 140 } }
                            MIcon { anchors.horizontalCenter: parent.horizontalCenter; y: 13; size: 21; name: mt.modelData[2]; glyph: String.fromCodePoint(mt.modelData[3])
                                color: mt.on ? pal.inkContainer : pal.fg }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 42; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                text: Tr.t(mt.modelData[1]); color: mt.on ? pal.inkContainer : pal.fg; font.family: Fonts.main; font.pixelSize: 11 }
                            // its place in the row (the order you picked them in)
                            Rectangle { visible: mt.on; x: parent.width - 20; y: 5; width: 16; height: 16; radius: Look.sq ? 0 : (8); color: pal.primary
                                Text { anchors.centerIn: parent; text: mt.at + 1; color: pal.inkPrimary; font.family: Fonts.main; font.pixelSize: 9; font.weight: Font.Bold } }
                            MouseArea { id: mtm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const k = mt.modelData[0]
                                    const l = mt.cur.filter(function(x) { return x !== k })
                                    // a new one: the pin goes first, the others at the end
                                    if (!mt.on) { if (k === "pin") l.unshift(k); else l.push(k) }
                                    if (!mt.on && k === "music" && secDock.d.media === false) ep.dk.setKey("media", true)
                                    if (!mt.on && k === "pin" && secDock.d.pinButton === false) ep.dk.setKey("pinButton", true)
                                    if (!mt.on && k === "launcher" && secDock.d.appsButton === false) ep.dk.setKey("appsButton", true)
                                    ep.dk.setKey("mods", l.join(","))
                                } }
                        }
                    }
                }

                // the order: the dock in small; ← → move a part, past your apps it goes to their other side
                Label { text: Tr.t("Order") + "  ·  " + Tr.t("← → move a part, also past your apps") }
                Flow {
                    width: parent.width
                    spacing: 5
                    move: Transition { NumberAnimation { properties: "x,y"; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                    Repeater {
                        model: ep.dk ? ep.dk.order : []
                        delegate: Rectangle {
                            id: oc
                            required property string modelData
                            required property int index
                            readonly property bool appsPart: modelData === "apps"
                            readonly property var info: ({ apps: ["Apps", 0xF003B, "apps"], pin: ["Pin", 0xF0403, "keep"], launcher: ["All apps", 0xF003B, "apps"], music: ["Music", 0xF075A, "music_note"],
                                clock: ["Clock", 0xF0954, "schedule"], battery: ["Battery", 0xF0079, "battery_full"], volume: ["Volume", 0xF057E, "volume_up"], network: ["Wi-Fi", 0xF05A9, "wifi"],
                                bluetooth: ["Bluetooth", 0xF00AF, "bluetooth"], weather: ["Weather", 0xF0595, "partly_cloudy_day"], sysmon: ["CPU & RAM", 0xF035B, "memory"], search: ["App search", 0xF0349, "search"],
                                notifications: ["Notifications", 0xF009A, "notifications"], control: ["Control center", 0xF062E, "tune"], power: ["Session", 0xF0425, "power_settings_new"] })[modelData] || [modelData, 0x3F, "help"]
                            height: 34
                            width: appsPart ? apT.implicitWidth + 44 : 34 + 30 + 30
                            radius: Look.sq ? 0 : (17)
                            color: appsPart ? pal.primary : Qt.rgba(1, 1, 1, 0.08)
                            Row {
                                visible: oc.appsPart
                                anchors.centerIn: parent; spacing: 6
                                MIcon { anchors.verticalCenter: parent.verticalCenter; size: 15; name: "apps"; glyph: String.fromCodePoint(0xF003B); color: pal.inkPrimary }
                                Text { id: apT; anchors.verticalCenter: parent.verticalCenter; text: Tr.t("Your apps"); color: pal.inkPrimary; font.family: Fonts.main; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }
                            Row {
                                visible: !oc.appsPart
                                anchors.centerIn: parent; spacing: 0
                                TinyBtn { width: 30; height: 30; sym: ep.dk && ep.dk.vert ? "arrow_upward" : "arrow_back"; glyph: String.fromCodePoint(0xF004D)
                                    dimmed: oc.index === 0; onPicked: ep.moveMod(oc.index, -1) }
                                Item { width: 34; height: 30
                                    MIcon { anchors.centerIn: parent; size: 16; name: oc.info[2]; glyph: String.fromCodePoint(oc.info[1]); color: pal.fg }
                                    HoverHandler { id: och }
                                    ToolTipLite { show: och.hovered; text: Tr.t(oc.info[0]) } }
                                TinyBtn { width: 30; height: 30; sym: ep.dk && ep.dk.vert ? "arrow_downward" : "arrow_forward"; glyph: String.fromCodePoint(0xF0054)
                                    dimmed: ep.dk && oc.index === ep.dk.order.length - 1; onPicked: ep.moveMod(oc.index, 1) }
                            }
                        }
                    }
                }
                Label { text: Tr.t("Pinned apps") + "  ·  " + (secDock.d.apps || []).length }
                Column {
                    width: parent.width
                    spacing: 3
                    Repeater {
                        model: secDock.d.apps || []
                        delegate: Rectangle {
                            id: pr
                            required property string modelData
                            required property int index
                            readonly property var e: DesktopEntries.heuristicLookup(modelData)
                            readonly property int n: (secDock.d.apps || []).length
                            width: parent.width; height: 44
                            topLeftRadius: Look.sq ? 0 : (index === 0 ? 16 : 6); topRightRadius: Look.sq ? 0 : (topLeftRadius)
                            bottomLeftRadius: Look.sq ? 0 : (index === n - 1 ? 16 : 6); bottomRightRadius: Look.sq ? 0 : (bottomLeftRadius)
                            color: prm.containsMouse ? pal.cardHi : pal.card
                            Behavior on color { ColorAnimation { duration: 120 } }
                            MouseArea { id: prm; anchors.fill: parent; hoverEnabled: true }
                            AppIcon { x: 8; anchors.verticalCenter: parent.verticalCenter; size: 30
                                name: pr.e ? (pr.e.icon || "") : pr.modelData; keys: [pr.modelData, pr.e ? pr.e.id : ""]
                                look: ep.dk ? ep.dk.look : "original"; shape: ep.dk ? ep.dk.shape : ""; colors: pal }
                            Text { x: 46; width: parent.width - 46 - 96; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                                text: pr.e ? pr.e.name : pr.modelData; color: pal.fg; font.family: Fonts.main; font.pixelSize: 12 }
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                                spacing: 0
                                TinyBtn { sym: ep.dk && ep.dk.vert ? "arrow_upward" : "arrow_back"; glyph: String.fromCodePoint(ep.dk && ep.dk.vert ? 0xF005D : 0xF004D)
                                    dimmed: pr.index === 0; onPicked: ep.moveApp(pr.index, -1) }
                                TinyBtn { sym: ep.dk && ep.dk.vert ? "arrow_downward" : "arrow_forward"; glyph: String.fromCodePoint(ep.dk && ep.dk.vert ? 0xF0045 : 0xF0054)
                                    dimmed: pr.index === pr.n - 1; onPicked: ep.moveApp(pr.index, 1) }
                                TinyBtn { sym: "close"; glyph: String.fromCodePoint(0xF0156); danger: true; onPicked: ep.unpinApp(pr.modelData) }
                            }
                        }
                    }
                }
                // add apps: search them here and pin them with +
                Rectangle {
                    id: addBox
                    width: parent.width; height: 42; radius: Look.sq ? 0 : (ep.addOpen ? 21 : 14)
                    color: ep.addOpen ? pal.cardHi : (abm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                    border.width: addField.activeFocus ? 2 : 0; border.color: pal.primary
                    Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    MIcon { x: 13; anchors.verticalCenter: parent.verticalCenter; size: 17; name: ep.addOpen ? "search" : "add_circle"
                        glyph: String.fromCodePoint(ep.addOpen ? 0xF0349 : 0xF0415); color: ep.addOpen ? pal.fg : pal.primary }
                    Text { visible: !ep.addOpen; x: 40; anchors.verticalCenter: parent.verticalCenter; text: Tr.t("Add apps ...")
                        color: pal.primary; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium }
                    MouseArea { id: abm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor
                        onClicked: { ep.addOpen = true; addField.forceActiveFocus() } }
                    TextInput {
                        id: addField
                        visible: ep.addOpen
                        x: 40; width: parent.width - 52; anchors.verticalCenter: parent.verticalCenter
                        color: pal.fg; font.family: Fonts.main; font.pixelSize: 13
                        selectionColor: pal.primary; selectedTextColor: pal.inkPrimary
                        clip: true
                        onTextChanged: ep.q = text
                        Keys.onEscapePressed: { if (text !== "") text = ""; else { ep.addOpen = false; focus = false } }
                        Keys.onReturnPressed: if (ep.found.length > 0) ep.pinEntry(ep.found[0])
                        Text { visible: addField.text === ""; text: Tr.t("Search apps"); color: pal.dim; font: addField.font }
                    }
                }
                Column {
                    visible: ep.addOpen
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: ep.found
                        delegate: Rectangle {
                            id: fr
                            required property var modelData
                            readonly property bool pinned: ep.pinnedId(fr.modelData)
                            width: parent.width; height: 40; radius: Look.sq ? 0 : (14)
                            color: frm.containsMouse ? pal.card : "transparent"
                            AppIcon { x: 8; anchors.verticalCenter: parent.verticalCenter; size: 26
                                name: fr.modelData.icon || ""; keys: [fr.modelData.id, fr.modelData.name]
                                look: ep.dk ? ep.dk.look : "original"; shape: ep.dk ? ep.dk.shape : ""; colors: pal }
                            Text { x: 42; width: parent.width - 84; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                                text: fr.modelData.name; color: pal.fg; font.family: Fonts.main; font.pixelSize: 12 }
                            Rectangle {
                                anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                                width: 30; height: 30; radius: Look.sq ? 0 : (15)
                                color: fr.pinned ? pal.primary : (frm.containsMouse ? pal.cardHi : pal.card)
                                MIcon { anchors.centerIn: parent; size: 15; name: fr.pinned ? "check" : "add"; glyph: String.fromCodePoint(fr.pinned ? 0xF012C : 0xF0415)
                                    color: fr.pinned ? pal.inkPrimary : pal.fg }
                            }
                            MouseArea { id: frm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (fr.pinned) ep.unpinApp(ep.entryId(fr.modelData)); else ep.pinEntry(fr.modelData) } }
                        }
                    }
                    Text { visible: ep.found.length === 0; leftPadding: 8; text: Tr.t("No app with that name"); color: pal.dim; font.family: Fonts.main; font.pixelSize: 11 }
                }
                LinkRow { text: Tr.t("More dock settings"); onPicked: ep.settingsPage(14) }
            }

            // ---- how app icons look (V4.89)
            Section {
                id: secIcons
                key: "icons"
                order: 6
                icon: "interests"; glyph: String.fromCodePoint(0xF0831); title: Tr.t("Icons")
                sub: Tr.t(ep.lookName(ep.dk ? ep.dk.look : "original")) + "  ·  " + Tr.t(ep.cap(ep.dk && ep.dk.shape !== "" ? ep.dk.shape : "no shape"))
                     + "  ·  " + (ep.iconCfg.theme ? ep.packName(ep.iconCfg.theme) : Tr.t("System icons"))
                onOpenChanged: if (open) ep.loadPacks()
                // how the dock looks with it
                Rectangle {
                    width: parent.width; height: 66; radius: Look.sq ? 0 : (24)
                    color: Qt.rgba(0, 0, 0, 0.22)
                    border.width: 1; border.color: pal.line
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Repeater {
                            model: ep.samples
                            delegate: AppIcon { size: 40; name: modelData.n; keys: modelData.k; colors: pal
                                look: ep.dk ? ep.dk.look : "original"; shape: ep.dk ? ep.dk.shape : "" }
                        }
                    }
                }
                Label { text: Tr.t("Style") }
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 6
                    Repeater {
                        model: [["original", "Original"], ["tinted", "Wallpaper"], ["themed", "Themed"], ["filled", "Filled"], ["mono", "Mono"], ["grey", "Grey"]]
                        delegate: Rectangle {
                            id: lt
                            required property var modelData
                            readonly property bool on: (ep.dk ? ep.dk.look : "original") === modelData[0]
                            width: (parent.width - 6) / 2; height: 78
                            radius: Look.sq ? 0 : (on ? 22 : 16)
                            // the chosen one: an outline, not a fill (its icons' own shapes would melt into it)
                            color: on ? Qt.rgba(0, 0, 0, 0.28) : (ltm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                            border.width: on ? 2 : 0; border.color: pal.primary
                            Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; y: 10
                                spacing: 5
                                Repeater {
                                    model: ep.samples.slice(0, 3)
                                    delegate: AppIcon { size: 32; name: modelData.n; keys: modelData.k; colors: pal; look: lt.modelData[0]
                                        shape: ep.dk && ep.dk.shape !== "" ? ep.dk.shape : (lt.modelData[0] === "themed" || lt.modelData[0] === "filled" || lt.modelData[0] === "mono" ? "circle" : "") }
                                }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 52; text: Tr.t(lt.modelData[1])
                                color: lt.on ? pal.primary : pal.fg; font.family: Fonts.main; font.pixelSize: 12; font.weight: lt.on ? Font.DemiBold : Font.Normal }
                            MouseArea { id: ltm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ep.setIcons("look", lt.modelData[0])
                                    // the themed looks need something to sit on: a circle, unless a shape is chosen
                                    const sign = lt.modelData[0] === "themed" || lt.modelData[0] === "filled" || lt.modelData[0] === "mono"
                                    if (sign && ep.dk && ep.dk.shape === "") ep.setIcons("shape", "circle")
                                } }
                        }
                    }
                }
                Label { text: Tr.t("Shape") }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: ["", "squircle", "circle", "cookie", "cookie4", "flower", "clover", "sun", "softburst", "puffy"]
                        delegate: Rectangle {
                            id: sc
                            required property string modelData
                            readonly property bool on: (ep.dk ? ep.dk.shape : "") === modelData
                            width: 48; height: 48; radius: Look.sq ? 0 : (on ? 24 : 14)
                            color: on ? pal.container : (scm.containsMouse ? pal.cardHi : Qt.rgba(1, 1, 1, 0.05))
                            border.width: on ? 2 : 0; border.color: pal.primary
                            Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                            Blob {
                                visible: sc.modelData !== ""
                                anchors.centerIn: parent; width: 30; height: 30
                                kind: sc.modelData === "squircle" ? "square" : (sc.modelData || "circle")
                                corner: 0.34
                                color: sc.on ? pal.primary : pal.dim
                                rotation: scm.containsMouse ? 25 : 0
                                Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                            }
                            MIcon { visible: sc.modelData === ""; anchors.centerIn: parent; name: "block"; glyph: ""; size: 20; color: sc.on ? pal.primary : pal.dim }
                            MouseArea { id: scm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: ep.setIcons("shape", sc.modelData === "" ? "none" : sc.modelData) }
                        }
                    }
                }
                Label { text: Tr.t("Icon pack") }
                Column {
                    width: parent.width
                    spacing: 3
                    Repeater {
                        model: [{ id: "", name: Tr.t("System icons"), f: [] }].concat(ep.packs)
                        delegate: Rectangle {
                            id: pk
                            required property var modelData
                            required property int index
                            readonly property bool on: (ep.iconCfg.theme || "") === modelData.id
                            width: parent.width; height: 46
                            topLeftRadius: Look.sq ? 0 : (index === 0 ? 16 : 6); topRightRadius: Look.sq ? 0 : (topLeftRadius)
                            bottomLeftRadius: Look.sq ? 0 : (index === ep.packs.length ? 16 : 6); bottomRightRadius: Look.sq ? 0 : (bottomLeftRadius)
                            color: on ? pal.container : (pkm.containsMouse ? pal.cardHi : pal.card)
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Row {
                                x: 10; anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Repeater {
                                    model: pk.modelData.f
                                    delegate: Image { width: 22; height: 22; sourceSize.width: 44; sourceSize.height: 44; asynchronous: true
                                        source: modelData !== "" ? "file://" + modelData : "" }
                                }
                                MIcon { visible: pk.modelData.id === ""; size: 20; name: "computer"; glyph: String.fromCodePoint(0xF0379); color: pk.on ? pal.inkContainer : pal.dim }
                            }
                            Text { x: pk.modelData.id === "" ? 40 : 108; width: parent.width - x - 34; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                                text: pk.modelData.name; color: pk.on ? pal.inkContainer : pal.fg; font.family: Fonts.main; font.pixelSize: 12; font.weight: pk.on ? Font.DemiBold : Font.Normal }
                            MIcon { visible: pk.on; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                size: 17; name: "check"; glyph: String.fromCodePoint(0xF012C); color: pal.primary }
                            MouseArea { id: pkm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: ep.setIcons("theme", pk.modelData.id === "" ? "none" : pk.modelData.id) }
                        }
                    }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap; topPadding: 4; leftPadding: 4
                        text: ep.packsBusy ? Tr.t("Looking for icon packs ...")
                            : Tr.t("More packs: install them from your package manager, e.g. papirus-icon-theme or tela-circle-icon-theme, then open this tab again.")
                        color: pal.dim; font.family: Fonts.main; font.pixelSize: 11
                    }
                }
                LinkRow { text: Tr.t("Back to the dock's own look"); visible: (ep.iconCfg.look || "auto") !== "auto" || (ep.iconCfg.shape || "auto") !== "auto"
                    sym: "restart_alt"; glyph: ""
                    onPicked: { ep.setIcons("look", "auto"); ep.setIcons("shape", "auto") } }
            }
        }
    }
}
