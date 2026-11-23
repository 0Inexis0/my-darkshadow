import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

// The dock (Settings > Dock), rebuilt in V3.22. Two layer windows:
//   - the dock itself, which only exists while it is shown, at its full size (it never resizes while it moves);
//   - with "Show on hover", a thin invisible strip along the screen edge that brings it back.
// Bottom, left or right edge. Pinned apps from desktop.json, then every open app; the song that plays; apps button.
Scope {
    id: dock
    property var dc: ({})
    // V4.89: how app icons look (Edit mode > Icons, desktop.json "icons") and the desktop shell (it opens Edit mode)
    property var ic: ({})
    property var desk: null
    function editDock(sec) { if (desk) desk.startEditing(sec) }
    property bool pinned: false
    property bool hovering: false
    readonly property bool on: dc.enabled === true
    readonly property bool autoHide: dc.hover !== false
    readonly property bool reveal: on && !Infinite.hideUi && (!autoHide || pinned || hovering || apps.open || edit.open || editing)
    // Settings > Dock > Keep room for it: while the dock stays out (no hover-to-reveal, or held open with its pin),
    // windows keep away from it, like they do from the bar (an open browser ends above it, not under it)
    readonly property bool reserve: on && dc.reserve !== false && (!autoHide || pinned)
    readonly property string edge: dc.position === "left" || dc.position === "right" ? dc.position : "bottom"
    readonly property bool vert: edge === "left" || edge === "right"
    readonly property real alpha: Look.flat ? 1 : (dc.opacity !== undefined ? Number(dc.opacity) : 0.78)
    // the app icons (AppIcon.qml): Edit mode > Icons, else Settings > Dock: in a neutral grey (Tint), in a shade of your
    // wallpaper (Match the wallpaper, the default) or as they come
    readonly property string look: {
        const l = ic && ic.look ? ic.look : "auto"
        if (l !== "auto") return l
        return dc.tint === true ? "grey" : (dc.shade !== false ? "tinted" : "original")
    }
    // V4.87: its look (right click on the dock > Edit dock): floating, pills (every app on a tile of its own) or full
    // (the whole edge); the icon size, the room between apps and a shape each app sits on
    readonly property string style: dc.style === "pills" || dc.style === "full" ? dc.style : "floating"
    // the shape every app sits on: Edit mode > Icons (V4.89), else the dock's own (V4.87)
    readonly property string shape: {
        const s = ic && ic.shape !== undefined ? ic.shape : "auto"
        if (s !== "auto") return s === "none" ? "" : s
        return dc.iconShape || (style === "pills" ? "squircle" : "")
    }
    readonly property int icon: Math.max(24, Math.min(64, dc.iconSize || 34))     // app icon size
    // V4.89: the shape takes the icon's own room (it made the dock bigger before; now the picture sits inside it)
    readonly property int tile: icon
    readonly property int gap: dc.gap !== undefined ? Math.max(0, Math.min(24, dc.gap)) : 6
    readonly property int cell: tile + 12   // room for one app along the dock
    readonly property int thick: tile + 26  // the dock's width across
    property bool editing: false

    // 0 = hidden, 1 = shown; the window stays until the slide is over
    property real t: reveal ? 1 : 0
    Behavior on t { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    property bool initDone: false
    // Settings > Dock > Pinned at startup: at the start, and at once when you switch it (V4.95; before, it waited for the
    // next start, so the switch looked like it did nothing)
    property bool lastPinStart: false
    onDcChanged: {
        if (!initDone && dc.enabled !== undefined) { pinned = dc.pinnedStartup === true; lastPinStart = pinned; initDone = true; return }
        const ps = dc.pinnedStartup === true
        if (initDone && ps !== lastPinStart) { lastPinStart = ps; pinned = ps }
    }
    // it only hides when the pointer is really off the dock (a stray "exited" while the dock grows or while an icon
    // is clicked made it hide and come back over and over)
    Timer { id: hideTimer; interval: 700; onTriggered: if (!dockMouse.containsMouse && !dock.overPanelItems && !apps.overPanel) dock.hovering = false }
    // V5.01: the pointer on the dock's own card, its apps and modules included. A module or an icon with its own
    // hover took the hover from dockMouse (it lies under the card): the dock hid under the pointer and came back,
    // over and over, when you went from an empty spot of the dock onto an icon
    property bool overPanelItems: false
    DockApps { id: apps; dock: dock }
    DockEdit { id: edit; dock: dock; appsMenu: apps }
    NPal { id: pal; theme: "shell"; alpha: dock.alpha }
    function setKey(k, v) {
        const n = JSON.parse(JSON.stringify(dc))
        // the modules come as a list ("clock,battery" or "none" for desktop-set)
        n[k] = k === "mods" ? (v === "none" ? [] : String(v).split(",")) : v
        dc = n                                                           // at once; desktop.json says the same a moment later
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" dock \"$1\" \"$2\"", "_", k, String(v === "" ? "none" : v)])
    }
    // while a slider in Edit mode moves: the dock follows at once, desktop.json only when it is let go (setKey)
    function preview(k, v) { const n = JSON.parse(JSON.stringify(dc)); n[k] = v; dc = n }
    function idOf(it) { return it.entry ? (it.entry.id || "").replace(/\.desktop$/, "") : it.key }
    function isPinned(it) { return (dc.apps || []).indexOf(idOf(it)) >= 0 }
    function setApps(l) {
        const n = JSON.parse(JSON.stringify(dc)); n.apps = l; dc = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" dock-apps \"$1\"", "_", JSON.stringify(l)])
    }
    function pin(it, on) {
        const id = idOf(it), l = (dc.apps || []).filter(function(x) { return x !== id })
        if (on) l.push(id)
        setApps(l)
    }
    function move(it, d) {
        const l = (dc.apps || []).slice(), i = l.indexOf(idOf(it)), j = i + d
        if (i < 0 || j < 0 || j >= l.length) return
        const x = l[i]; l[i] = l[j]; l[j] = x
        setApps(l)
    }

    function pickPlayer() {
        const l = Mpris.players.values
        for (let i = 0; i < l.length; i++) if (l[i].isPlaying) return l[i]
        return l.length > 0 ? l[0] : null
    }
    readonly property var player: pickPlayer()
    // V4.92: the modules (Edit mode > Dock > Modules): "music" is the song that plays, the others are DockMod.qml
    readonly property var mods: Array.isArray(dc.mods) ? dc.mods : ["music"]
    readonly property var otherMods: mods.filter(function(m) { return m !== "music" && m !== "apps" && m !== "pin" && m !== "launcher" })
    readonly property bool showMedia: mods.indexOf("music") >= 0 && dc.media !== false && player !== null
    // V4.94: the whole row in order; "apps" is where your apps are. Before V4.94 the list had only the modules
    // (after the apps), with the pin before and the all-apps button after them
    readonly property var layout: {
        let l
        if (mods.indexOf("apps") < 0) {
            l = (dc.pinButton !== false ? ["pin"] : []).concat(["apps"]).concat(mods).concat(dc.appsButton !== false ? ["launcher"] : [])
        } else l = mods.slice()
        return l.filter(function(m) { return (m !== "pin" || dc.pinButton !== false) && (m !== "launcher" || dc.appsButton !== false) })
    }
    // the full order as Edit mode shows it (the pin and the all-apps button too, even when Settings hides them)
    readonly property var order: mods.indexOf("apps") >= 0 ? mods : (dc.pinButton !== false ? ["pin"] : []).concat(["apps"]).concat(mods).concat(dc.appsButton !== false ? ["launcher"] : [])
    property Item appsBlock: null
    Binding { target: BarSvc; property: "dockShown"; value: dock.on && dock.otherMods.some(function(m) { return m === "network" || m === "bluetooth" || m === "notifications" }) }

    // V4.92: magnify under the pointer, like the dock of macOS (Edit mode > Dock: 0 = off .. 100 = twice as big).
    // The apps near the pointer grow out of the dock, the closer the bigger, on a soft curve over about 2.5 apps.
    readonly property real mag: Math.max(0, Math.min(1, (dc.magnify !== undefined ? Number(dc.magnify) : 0) / 100))
    property real px: -100000              // the pointer along the dock, in the window
    property bool over: false               // the pointer is on the dock
    property real hovK: over && mag > 0 ? 1 : 0
    Behavior on hovK { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    readonly property real range: 2.6 * cell
    property var mf: []                     // how much each app grows (0 .. 1)
    readonly property real extraSum: { let s = 0; for (let i = 0; i < mf.length; i++) s += mf[i]; return s * cell * mag * hovK }
    function magnifyAt(p) {
        px = p
        if (mag <= 0) return
        const n = items.length
        // where the apps start in the row (whatever is before them does not grow), and the line before them
        const lead = (appsBlock ? (vert ? appsBlock.y : appsBlock.x) : 0) + (layout.indexOf("apps") > 0 && style !== "pills" ? 1 + gap : 0)
        // the dock grows to both sides: the pointer is taken back to where it would be on the dock at rest
        const lr = vert ? list.height : list.width
        const l0 = lr - extraSum
        const pl = p - (vert ? panelItem.y + list.y : panelItem.x + list.x)
        const pr = lr > 0 ? (pl - lr / 2) * (l0 / lr) + l0 / 2 : pl
        const out = []
        for (let i = 0; i < n; i++) {
            const c = lead + i * (cell + gap) + cell / 2
            const d = Math.abs(pr - c)
            out.push(d >= range ? 0 : (Math.cos(d / range * Math.PI) + 1) / 2)
        }
        mf = out
    }
    property Item panelItem: null

    function tid(t) { return Icons.appKey(t.appId, t.title) }
    function build() {
        // depends on the app list too: when it is read again the old entries are deleted, and the dock must not keep them
        const all = DesktopEntries.applications.values
        const tl = ToplevelManager.toplevels.values
        const out = []
        const used = {}
        const apps = dc.apps || []
        for (let i = 0; i < apps.length; i++) {
            const e = DesktopEntries.heuristicLookup(apps[i])
            if (!e) continue
            const ids = [apps[i].toLowerCase(), (e.id || "").toLowerCase(), (e.startupClass || "").toLowerCase()]
            let t = null
            for (let j = 0; j < tl.length; j++) {
                const id = tid(tl[j])
                if (id !== "" && ids.indexOf(id) >= 0) { t = tl[j]; break }
            }
            if (t) used[tid(t)] = true
            out.push({ entry: e, tl: t, key: apps[i] })
        }
        for (let j = 0; j < tl.length; j++) {
            const id = tid(tl[j])
            if (id === "" || used[id]) continue
            used[id] = true
            out.push({ entry: DesktopEntries.heuristicLookup(id.indexOf("darkshadow-") === 0 ? id : tl[j].appId), tl: tl[j], key: id })
        }
        return out
    }
    readonly property var items: build()
    function iconFor(it) {
        const n = it.entry ? it.entry.icon : (it.tl ? tid(it.tl) : "")
        const p = n !== "" ? Icons.get(n, true) : ""
        return p !== "" ? p : Icons.get("application-x-executable", true)
    }

    // the pin and apps buttons: the apps' shape (a rounded square without one)
    component DockTile: Item {
        property color color: "transparent"
        anchors.fill: parent
        Rectangle { anchors.fill: parent; visible: dock.shape === ""; radius: Look.sq ? 0 : (width * 0.36); color: parent.color
            Behavior on color { ColorAnimation { duration: 140 } } }
        Blob { anchors.fill: parent; visible: dock.shape !== ""; kind: dock.shape === "squircle" ? "square" : dock.shape; corner: 0.34; color: parent.color }
    }

    // ---------------- the strip that brings the dock back ----------------
    PanelWindow {
        screen: Mon.screen
        id: strip
        visible: dock.on && dock.autoHide && !dock.reveal && dock.t < 0.05
        color: "transparent"
        anchors { bottom: dock.edge === "bottom"; left: dock.edge === "left"; right: dock.edge === "right" }
        implicitWidth: dock.vert ? 3 : Math.max(200, panel.width)
        implicitHeight: dock.vert ? Math.max(200, panel.height) : 3
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "rice-dock-edge"
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { hideTimer.stop(); dock.hovering = true }
        }
    }

    // ---------------- the dock ----------------
    PanelWindow {
        screen: Mon.screen
        id: dockWin
        visible: dock.on && (dock.reveal || dock.t > 0.01)
        color: "transparent"
        anchors {
            bottom: dock.edge === "bottom" || (dock.vert && dock.style === "full")
            top: dock.vert && dock.style === "full"
            left: dock.edge === "left" || (!dock.vert && dock.style === "full")
            right: dock.edge === "right" || (!dock.vert && dock.style === "full")
        }
        // the full style: the window spans the edge by its anchors (its length comes from the screen, not the panel)
        // with magnifying on: room for the apps that grow out of the dock, and a window that keeps its size while they
        // do (it changed with every move of the pointer before it had that room)
        readonly property real popOut: dock.mag > 0 ? Math.ceil(dock.tile * dock.mag) + 8 : 0
        readonly property real grow: dock.mag > 0 ? Math.ceil(2.2 * dock.cell * dock.mag) : 0
        implicitWidth: dock.style === "full" ? (dock.vert ? panel.width + popOut : 0) : (dock.vert ? panel.width + 18 + popOut : panel.width - dock.extraSum + 24 + grow)
        implicitHeight: dock.style === "full" ? (dock.vert ? 0 : panel.height + popOut) : (dock.vert ? panel.height - dock.extraSum + 24 + grow : panel.height + 18 + popOut)
        // only the dock itself takes clicks then (not the room around it for the growing apps)
        mask: dock.mag > 0 ? magRegion : null
        Region { id: magRegion; item: panel }
        exclusionMode: dock.reserve ? ExclusionMode.Normal : ExclusionMode.Ignore
        // the panel's width across and its 10 px from the edge
        exclusiveZone: dock.reserve ? dock.thick + (dock.style === "full" ? 0 : 10) : 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "rice-dock"
        // niri: blur behind the dock while it is out (Hyprland blurs this layer with its own rule)
        NiriBlur { win: dockWin; items: [panel]; radius: Look.sq ? 0 : (panel.radius); on: dock.t > 0.95 && dock.dc.background !== false }

        MouseArea {
            id: dockMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            // while it slides away, a window that appears or moves under a still pointer says "entered" by itself:
            // only a real movement of the pointer brings the dock back then
            onEntered: { hideTimer.stop(); if (dock.reveal) dock.hovering = true }
            onPositionChanged: function(m) {
                hideTimer.stop(); dock.hovering = true
                const q = mapToItem(panel, m.x, m.y)
                dock.over = q.x >= 0 && q.y >= 0 && q.x <= panel.width && q.y <= panel.height
                dock.magnifyAt(dock.vert ? m.y : m.x)
            }
            onExited: { dock.over = dock.overPanelItems; if (dock.autoHide && !edit.open) hideTimer.restart() }
        }

        Rectangle {
            id: panel
            Frame { }      // V4.98 Minimal mode
            HoverHandler {
                id: panelHover
                onHoveredChanged: {
                    dock.overPanelItems = hovered
                    dock.over = hovered
                    if (hovered) { hideTimer.stop(); if (dock.reveal) dock.hovering = true }
                    else if (dock.autoHide && !edit.open && !dockMouse.containsMouse) hideTimer.restart()
                }
                // the magnifying follows the pointer over the icons and modules too
                onPointChanged: if (hovered && dock.mag > 0) { const q = panel.mapToItem(dockMouse, point.position.x, point.position.y); dock.magnifyAt(dock.vert ? q.y : q.x) }
            }
            Component.onCompleted: dock.panelItem = panel
            // sits 10 px from its edge; hidden = slid out over that edge
            readonly property real away: (dock.vert ? width : height) + 14
            readonly property bool full: dock.style === "full"
            readonly property real m: full ? 0 : 10
            x: dock.vert ? (dock.edge === "left" ? m : parent.width - width - m) : (full ? 0 : (parent.width - width) / 2)
            y: dock.vert ? (full ? 0 : (parent.height - height) / 2) : parent.height - height - m
            transform: Translate {
                x: dock.edge === "left" ? -panel.away * (1 - dock.t) : (dock.edge === "right" ? panel.away * (1 - dock.t) : 0)
                y: dock.edge === "bottom" ? panel.away * (1 - dock.t) : 0
            }
            opacity: 0.4 + 0.6 * dock.t
            width: dock.vert ? dock.thick : (full ? parent.width : list.implicitWidth + 20)
            height: dock.vert ? (full ? parent.height : list.implicitHeight + 20) : dock.thick
            radius: Look.sq ? 0 : (full ? 0 : Math.min(dock.thick / 2, 26))
            readonly property bool bare: dock.dc.background === false || dock.style === "pills"
            color: bare ? "transparent" : pal.surface
            border.width: bare || full ? 0 : 1
            border.color: pal.line
            Behavior on radius { NumberAnimation { duration: 240 } }
            // a right click on the dock: its menu (Edit dock, Add apps)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: function(m) { const p = mapToItem(null, m.x, m.y); edit.menuAt(null, p.x, p.y, dockWin) }
            }

            // V4.94: the dock is a row in the order you set (Edit mode > Dock > Modules): the pin, your apps, the song,
            // the modules and the all-apps button, each on either side of the apps. A part that comes grows in,
            // the others slide aside to make room
            Transition { id: slideT; NumberAnimation { properties: "x,y"; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
            Grid {
                id: list
                anchors.centerIn: parent
                spacing: dock.gap
                columns: dock.vert ? 1 : 1000
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter
                // (not while the apps grow under the pointer: the row would lag behind it)
                move: dock.hovK > 0.001 ? null : slideT
                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260 }
                        NumberAnimation { property: "scale"; from: 0.3; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 2 }
                    }
                }
                Repeater {
                    model: dock.layout
                    delegate: Loader {
                        id: part
                        required property string modelData
                        required property int index
                        Component.onCompleted: if (modelData === "apps") dock.appsBlock = part
                        sourceComponent: modelData === "pin" ? pinC : (modelData === "apps" ? appsC : (modelData === "music" ? musicC
                                         : (modelData === "launcher" ? launcherC : modC)))
                        // a module that has nothing to show (the song while nothing plays) takes no room
                        visible: modelData !== "music" || dock.showMedia
                        property string kind: modelData
                    }
                }
            }

            // ---- the parts
            Component { id: modC
                DockMod { kind: parent ? parent.kind : ""; host: dock; np: pal }
            }
            Component { id: pinC
                Item {
                    width: dock.tile; height: dock.tile
                    DockTile { color: dock.pinned ? pal.primary : (pinM.containsMouse ? pal.cardHi : pal.card) }
                    MIcon { anchors.centerIn: parent; name: "keep"; glyph: String.fromCodePoint(0xF0403); size: 18
                        color: dock.pinned ? pal.inkPrimary : pal.fg; rotation: dock.pinned ? 0 : 45
                        Behavior on rotation { RotationAnimator { duration: 200 } } }
                    MouseArea { id: pinM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dock.pinned = !dock.pinned }
                }

            }
            Component { id: launcherC
                Item {
                    width: dock.tile; height: dock.tile
                    DockTile { color: appsM.containsMouse ? pal.cardHi : pal.card }
                    MIcon { anchors.centerIn: parent; name: "apps"; glyph: String.fromCodePoint(0xF003B); size: 18; color: pal.fg }
                    MouseArea { id: appsM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        // the dock's own app menu (Settings > Dock > App menu), else the launcher
                        onClicked: { if (dock.dc.appMenu !== false) apps.open = !apps.open; else Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-launch\""]) } }
                }
            }
            Component { id: musicC
                Rectangle {
                    readonly property bool pill: dock.style === "pills"
                    width: mediaG.width + (pill ? 20 : 0)
                    height: mediaG.height + (pill ? 16 : 0)
                    radius: Look.sq ? 0 : (Math.min(width, height) / 2)
                    color: pill ? pal.surface : "transparent"
                    border.width: pill ? 1 : 0; border.color: pal.line
                Grid {
                    id: mediaG
                    anchors.centerIn: parent
                    spacing: 8
                    columns: dock.vert ? 1 : 3
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter
                    RoundImage {
                        width: 38; height: 38; cornerRadius: 12; fallback: ""
                        source: dock.player && dock.player.trackArtUrl ? dock.player.trackArtUrl : ""
                    }
                    Column {
                        visible: dock.dc.nowText !== false && !dock.vert
                        width: 130
                        T { width: parent.width; elide: Text.ElideRight; font.pixelSize: 12; font.bold: true; text: dock.player ? (dock.player.trackTitle || "") : "" }
                        T { width: parent.width; elide: Text.ElideRight; font.pixelSize: 10; color: pal.dim; text: dock.player ? (dock.player.trackArtist || "") : "" }
                    }
                    Rectangle {
                        width: 34; height: 34; radius: Look.sq ? 0 : (17)
                        color: playM.containsMouse ? pal.cardHi : pal.card
                        Behavior on color { ColorAnimation { duration: 140 } }
                        MIcon { anchors.centerIn: parent; size: 16
                            name: dock.player && dock.player.isPlaying ? "pause" : "play_arrow"
                            glyph: String.fromCodePoint(dock.player && dock.player.isPlaying ? 0xF03E4 : 0xF040A) }
                        MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (dock.player) dock.player.togglePlaying() }
                    }
                }
                }

            }
            // the apps: their own row, with a thin line on each side that has something next to it
            Component { id: appsC
                Grid {
                    id: appsRow
                    spacing: dock.gap
                    columns: dock.vert ? 1 : 1000
                    horizontalItemAlignment: Grid.AlignHCenter
                    verticalItemAlignment: Grid.AlignVCenter
                    readonly property int at: dock.layout.indexOf("apps")
                    Rectangle { visible: appsRow.at > 0 && dock.style !== "pills"; width: dock.vert ? 30 : 1; height: dock.vert ? 1 : 30; color: pal.track }
                Repeater {
                    model: dock.items
                    delegate: Item {
                        id: app
                        required property var modelData
                        required property int index
                        // magnified: it takes more room along the dock and its icon grows out of the dock's far side
                        readonly property real k0: dock.mag * dock.hovK * (index < dock.mf.length ? dock.mf[index] : 0)
                        property real k: k0
                        Behavior on k { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
                        readonly property real len: dock.cell * (1 + k)
                        width: dock.vert ? dock.thick - 12 : len
                        height: dock.vert ? len : dock.thick - 12
                        z: k > 0.01 ? 2 : 1
                        readonly property bool running: modelData.tl !== null
                        readonly property bool act: !!modelData.tl && modelData.tl.activated
                        AppIcon {
                            id: ico
                            readonly property real s: dock.tile * (1 + app.k)
                            x: dock.edge === "left" ? (app.width - dock.tile) / 2 + 2 : (dock.edge === "right" ? (app.width + dock.tile) / 2 - s - 2 : (app.width - s) / 2)
                            y: dock.vert ? (app.height - s) / 2 : (app.height + dock.tile) / 2 - s - 2
                            size: s
                            name: modelData.entry ? (modelData.entry.icon || "") : (modelData.tl ? dock.tid(modelData.tl) : "")
                            keys: [modelData.key, modelData.entry ? modelData.entry.id : "", modelData.entry ? modelData.entry.name : "", modelData.tl ? dock.tid(modelData.tl) : ""]
                            look: dock.look
                            shape: dock.shape
                            colors: pal
                            hover: appM.containsMouse && dock.mag === 0
                            pressed: appM.pressed
                            active: app.act
                        }
                        // open: a dot, the focused one a longer line
                        Rectangle {
                            visible: app.running
                            radius: Look.sq ? 0 : (2)
                            color: app.act ? pal.primary : pal.fg
                            opacity: app.act ? 1 : 0.5
                            width: dock.vert ? 4 : (app.act ? 14 : 5)
                            height: dock.vert ? (app.act ? 14 : 5) : 4
                            x: dock.edge === "left" ? 0 : (dock.edge === "right" ? parent.width - width : (parent.width - width) / 2)
                            y: dock.vert ? (parent.height - height) / 2 : parent.height - height
                            Behavior on width { NumberAnimation { duration: 160 } }
                            Behavior on height { NumberAnimation { duration: 160 } }
                        }
                        MouseArea {
                            id: appM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(m) {
                                if (m.button === Qt.RightButton) { const p = mapToItem(null, m.x, m.y); edit.menuAt(modelData, p.x, p.y, dockWin); return }
                                if (modelData.tl) modelData.tl.activate()
                                else if (modelData.entry) modelData.entry.execute()
                            }
                        }
                    }
                }

                    Rectangle { visible: appsRow.at >= 0 && appsRow.at < dock.layout.length - 1 && dock.style !== "pills"; width: dock.vert ? 30 : 1; height: dock.vert ? 1 : 30; color: pal.track }
                }
            }
        }

        // a soft click on the dock's buttons (Settings > Sfx & sounds)
        SfxTap {}
    }
}
