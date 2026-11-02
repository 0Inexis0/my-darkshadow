import QtQuick

// Cards of one dashboard tab on a grid (12 columns). Every card has a place (x, y) and a size (w, h)
// in grid cells. In edit mode you can:
//   drag a card to an empty spot (or onto another card to swap them),
//   hold a card's edge or corner handle and drag to resize it,
//   click an empty spot (+) to put a card there, or remove a card with the x.
// Older layouts without places are packed row by row, like before.
Item {
    id: g
    property var d
    property string tabId: ""
    property var catalog: []        // [{ id, name, icon, glyph, sizes: [[w, h], ...], min: [w, h] }]
    property var defaults: []       // [{ id, x, y, w, h }]
    property var comps: ({})        // id -> Component (a DCard)
    property int cols: 12
    property int rows: 2
    property string layoutKey: ""   // where the layout is kept when it is not the tab id (the tall layout has its own)
    property real rowH: 0           // a fixed row height; 0 = the rows share the height
    readonly property string lkey: layoutKey !== "" ? layoutKey : tabId
    property bool live: false
    readonly property bool editing: d && d.editing && d.tab === tabId
    readonly property real gap: 12
    readonly property real cw: (width - (cols - 1) * gap) / cols
    readonly property real rh: rowH > 0 ? rowH : (height - (rows - 1) * gap) / rows

    readonly property var layout: d && d.layouts && d.layouts[lkey] ? d.layouts[lkey] : defaults
    readonly property var packed: pack(layout)

    function info(id) { for (let i = 0; i < catalog.length; i++) if (catalog[i].id === id) return catalog[i]; return null }
    function minOf(id) {
        const c = info(id)
        if (!c) return [1, 1]
        if (c.min) return c.min
        let w = 99, h = 99
        for (let i = 0; i < c.sizes.length; i++) { w = Math.min(w, c.sizes[i][0]); h = Math.min(h, c.sizes[i][1]) }
        return [Math.min(w, cols), Math.min(h, rows)]
    }
    function emptyGrid() {
        const u = []
        for (let r = 0; r < rows; r++) { u.push([]); for (let c = 0; c < cols; c++) u[r].push("") }
        return u
    }
    function fits(u, x, y, w, h, self) {
        if (x < 0 || y < 0 || x + w > cols || y + h > rows) return false
        for (let r = y; r < y + h; r++) for (let c = x; c < x + w; c++) if (u[r][c] !== "" && u[r][c] !== self) return false
        return true
    }
    function mark(u, x, y, w, h, id) { for (let r = y; r < y + h; r++) for (let c = x; c < x + w; c++) u[r][c] = id }

    // cards with a place go there; the rest take the first free spot, row by row
    function pack(l) {
        const u = emptyGrid(), pos = {}, out = []
        const later = []
        for (let i = 0; i < l.length; i++) {
            const it = l[i]
            if (!info(it.id) || pos[it.id]) continue
            const w = Math.max(1, Math.min(cols, it.w)), h = Math.max(1, Math.min(rows, it.h))
            if (it.x !== undefined && it.y !== undefined && fits(u, it.x, it.y, w, h, "")) {
                mark(u, it.x, it.y, w, h, it.id)
                pos[it.id] = { x: it.x, y: it.y, w: w, h: h, order: i }
            } else later.push({ it: it, w: w, h: h, i: i })
        }
        for (let k = 0; k < later.length; k++) {
            const o = later[k]
            let done = false
            for (let r = 0; r + o.h <= rows && !done; r++)
                for (let c = 0; c + o.w <= cols && !done; c++)
                    if (fits(u, c, r, o.w, o.h, "")) { mark(u, c, r, o.w, o.h, o.it.id); pos[o.it.id] = { x: c, y: r, w: o.w, h: o.h, order: o.i }; done = true }
            if (!done) out.push(o.it.id)
        }
        const free = []
        for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) if (u[r][c] === "") free.push({ x: c, y: r })
        return { pos: pos, out: out, used: u, free: free }
    }
    // what is on the grid now, with places
    function current() {
        const t = []
        for (const id in packed.pos) { const q = packed.pos[id]; t.push({ id: id, x: q.x, y: q.y, w: q.w, h: q.h, o: q.order }) }
        t.sort(function(a, b) { return a.o - b.o })
        return t.map(function(q) { return { id: q.id, x: q.x, y: q.y, w: q.w, h: q.h } })
    }
    function hidden() {
        return catalog.filter(function(c) { return !packed.pos[c.id] })
    }
    function save(l) { d.saveLayout(lkey, l) }

    // the biggest of the card's sizes that fits with (cx, cy) inside it
    function placeAt(id, cx, cy) {
        const c = info(id)
        const u = packed.used
        const sizes = c.sizes.concat([minOf(id)])
        for (let i = 0; i < sizes.length; i++) {
            const w = Math.min(cols, sizes[i][0]), h = Math.min(rows, sizes[i][1])
            for (let dy = 0; dy < h; dy++) for (let dx = 0; dx < w; dx++) {
                const x = cx - dx, y = cy - dy
                if (fits(u, x, y, w, h, "")) return { x: x, y: y, w: w, h: h }
            }
        }
        return null
    }
    function addAt(id, cx, cy) {
        const s = placeAt(id, cx, cy)
        if (!s) { d.toast("No room here for " + info(id).name + ". Pick a bigger empty spot."); return false }
        save(current().concat([{ id: id, x: s.x, y: s.y, w: s.w, h: s.h }]))
        return true
    }
    function add(id) {
        const c = info(id)
        const u = packed.used
        const sizes = c.sizes.concat([minOf(id)])
        for (let i = 0; i < sizes.length; i++) {
            const w = Math.min(cols, sizes[i][0]), h = Math.min(rows, sizes[i][1])
            for (let r = 0; r + h <= rows; r++) for (let x = 0; x + w <= cols; x++)
                if (fits(u, x, r, w, h, "")) { save(current().concat([{ id: id, x: x, y: r, w: w, h: h }])); return true }
        }
        d.toast("No room for " + c.name + ". Remove or shrink a card first.")
        return false
    }
    function remove(id) { save(current().filter(function(x) { return x.id !== id })) }
    function moveTo(id, x, y) {
        const q = packed.pos[id]
        if (!q || !fits(packed.used, x, y, q.w, q.h, id)) return false
        save(current().map(function(it) { return it.id === id ? { id: id, x: x, y: y, w: it.w, h: it.h } : it }))
        return true
    }
    function setSize(id, w, h) {
        save(current().map(function(it) { return it.id === id ? { id: id, x: it.x, y: it.y, w: w, h: h } : it }))
    }
    function swap(a, b) {
        const A = packed.pos[a], B = packed.pos[b]
        if (!A || !B) return
        // swap places; each keeps its size if it fits there, else they trade sizes too
        const u = emptyGrid()
        for (const id in packed.pos) if (id !== a && id !== b) { const q = packed.pos[id]; mark(u, q.x, q.y, q.w, q.h, id) }
        let na = { x: B.x, y: B.y, w: A.w, h: A.h }, nb = { x: A.x, y: A.y, w: B.w, h: B.h }
        const ok = function(p, q) {
            const v = u.map(function(r) { return r.slice() })
            if (!fits(v, p.x, p.y, p.w, p.h, "")) return false
            mark(v, p.x, p.y, p.w, p.h, "a")
            return fits(v, q.x, q.y, q.w, q.h, "")
        }
        if (!ok(na, nb)) { na = { x: B.x, y: B.y, w: B.w, h: B.h }; nb = { x: A.x, y: A.y, w: A.w, h: A.h } }
        save(current().map(function(it) {
            if (it.id === a) return { id: a, x: na.x, y: na.y, w: na.w, h: na.h }
            if (it.id === b) return { id: b, x: nb.x, y: nb.y, w: nb.w, h: nb.h }
            return it
        }))
    }

    // stable list of visible cards (delegates stay alive while they move)
    ListModel { id: lm }
    function sync() {
        const ids = Object.keys(packed.pos)
        for (let i = lm.count - 1; i >= 0; i--) if (ids.indexOf(lm.get(i).cid) < 0) lm.remove(i)
        for (let i = 0; i < ids.length; i++) {
            let f = false
            for (let j = 0; j < lm.count; j++) if (lm.get(j).cid === ids[i]) f = true
            if (!f) lm.append({ cid: ids[i] })
        }
    }
    onPackedChanged: sync()
    onEditingChanged: { pickAt = null; dragId = ""; rsId = "" }
    Component.onCompleted: { sync(); if (d) d.registerGrid(tabId, g) }

    function cellX(c) { return c * (g.cw + g.gap) }
    function cellY(r) { return r * (g.rh + g.gap) }
    function spanW(w) { return w * g.cw + (w - 1) * g.gap }
    function spanH(h) { return h * g.rh + (h - 1) * g.gap }

    // moving
    property string dragId: ""
    property real dragX: 0
    property real dragY: 0
    property string overId: ""
    property var drop: null          // { x, y } free spot under a dragged card
    // resizing
    property string rsId: ""
    property int rsW: 1
    property int rsH: 1
    // the + menu on an empty spot
    property var pickAt: null        // { x, y }

    // ---------- empty spots (edit mode) ----------
    Repeater {
        model: g.editing ? g.packed.free : []
        delegate: Rectangle {
            id: slot
            readonly property bool picked: g.pickAt && g.pickAt.x === modelData.x && g.pickAt.y === modelData.y
            x: g.cellX(modelData.x) + 2; y: g.cellY(modelData.y) + 2
            width: g.cw - 4; height: g.rh - 4
            radius: Math.min(14, width / 3)
            color: sm.containsMouse || slot.picked ? Qt.rgba(0.5, 0.5, 0.5, 0.16) : Qt.rgba(0.5, 0.5, 0.5, 0.06)
            border.width: 1
            border.color: slot.picked ? g.d.p.primary : Qt.rgba(0.5, 0.5, 0.5, sm.containsMouse ? 0.5 : 0.22)
            Behavior on color { ColorAnimation { duration: 120 } }
            opacity: g.dragId !== "" || g.rsId !== "" ? 0.35 : 1
            MIcon { anchors.centerIn: parent; name: "add"; glyph: "+"; size: Math.min(20, slot.width * 0.5); color: g.d.p.sub; opacity: sm.containsMouse || slot.picked ? 1 : 0.55 }
            MouseArea {
                id: sm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (g.hidden().length === 0) { g.d.toast("Every card is already on. Remove one with × to swap it for another."); return }
                    g.pickAt = slot.picked ? null : { x: modelData.x, y: modelData.y }
                }
            }
        }
    }

    // where a dragged card will land
    Rectangle {
        visible: g.dragId !== "" && g.drop !== null && g.overId === ""
        readonly property var q: g.packed.pos[g.dragId] || ({ w: 1, h: 1 })
        x: g.drop ? g.cellX(g.drop.x) : 0; y: g.drop ? g.cellY(g.drop.y) : 0
        width: g.spanW(q.w); height: g.spanH(q.h)
        radius: g.d.p.cardRadius
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 2; border.color: g.d.p.primary
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    Repeater {
        model: lm
        delegate: Item {
            id: cell
            readonly property string cid: model.cid
            readonly property var pp: g.packed.pos[cid] || ({ x: 0, y: 0, w: 1, h: 1, order: 0 })
            readonly property bool dragging: g.dragId === cid
            readonly property bool sizing: g.rsId === cid
            readonly property int gw: sizing ? g.rsW : pp.w
            readonly property int gh: sizing ? g.rsH : pp.h
            x: dragging ? g.dragX : g.cellX(pp.x)
            y: dragging ? g.dragY : g.cellY(pp.y)
            width: g.spanW(gw)
            height: g.spanH(gh)
            z: dragging || sizing ? 10 : 1
            Behavior on x { enabled: !cell.dragging; NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            Behavior on y { enabled: !cell.dragging; NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            Behavior on width { NumberAnimation { duration: cell.sizing ? 140 : 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            Behavior on height { NumberAnimation { duration: cell.sizing ? 140 : 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            scale: dragging ? 1.03 : (g.editing && g.overId === cid ? 0.96 : 1)
            Behavior on scale { NumberAnimation { duration: 160 } }

            Loader {
                anchors.fill: parent
                sourceComponent: g.comps[cell.cid] || null
                onLoaded: { item.order = cell.pp.order; item.live = Qt.binding(function() { return g.live }) }
            }

            // ---------- edit mode ----------
            Rectangle {
                visible: g.editing
                anchors.fill: parent
                radius: g.d.p.cardRadius
                color: g.overId === cell.cid ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                border.width: 2
                border.color: g.overId === cell.cid || cell.sizing ? g.d.p.primary : Qt.rgba(0.5, 0.5, 0.5, 0.45)
                Rectangle {
                    visible: cell.width >= 150
                    anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8
                    width: nm.implicitWidth + 16; height: 22; radius: 11
                    color: g.d.p.primary
                    DText { id: nm; anchors.centerIn: parent; text: (g.info(cell.cid) || {}).name || cell.cid; font.pixelSize: 10; font.weight: Font.DemiBold; color: g.d.p.inkOn }
                }
            }
            // move: hold and drag
            MouseArea {
                visible: g.editing
                anchors.fill: parent
                cursorShape: cell.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real sx: 0
                property real sy: 0
                property bool moved: false
                onPressed: function(m) { const p = mapToItem(g, m.x, m.y); sx = p.x - cell.x; sy = p.y - cell.y; moved = false; g.pickAt = null }
                onPositionChanged: function(m) {
                    const p = mapToItem(g, m.x, m.y)
                    if (!moved && Math.abs(p.x - sx - cell.x) + Math.abs(p.y - sy - cell.y) < 6) return
                    if (!moved) { moved = true; g.dragX = cell.x; g.dragY = cell.y; g.dragId = cell.cid }
                    g.dragX = p.x - sx; g.dragY = p.y - sy
                    // a card under the pointer: swap with it
                    let over = ""
                    for (const id in g.packed.pos) {
                        if (id === cell.cid) continue
                        const q = g.packed.pos[id]
                        const x0 = g.cellX(q.x), y0 = g.cellY(q.y)
                        if (p.x >= x0 && p.x <= x0 + g.spanW(q.w) && p.y >= y0 && p.y <= y0 + g.spanH(q.h)) over = id
                    }
                    g.overId = over
                    // otherwise: the nearest free spot for the card's top-left corner
                    const tx = Math.round(g.dragX / (g.cw + g.gap)), ty = Math.round(g.dragY / (g.rh + g.gap))
                    let best = null, bd = 1e9
                    for (let yy = 0; yy + cell.pp.h <= g.rows; yy++) for (let xx = 0; xx + cell.pp.w <= g.cols; xx++) {
                        const dd = Math.abs(xx - tx) + Math.abs(yy - ty) * 1.2
                        if (dd < bd && dd <= 3 && g.fits(g.packed.used, xx, yy, cell.pp.w, cell.pp.h, cell.cid)) { bd = dd; best = { x: xx, y: yy } }
                    }
                    g.drop = best
                }
                onReleased: {
                    const over = g.overId, dr = g.drop
                    g.dragId = ""; g.overId = ""; g.drop = null
                    if (!moved) return
                    if (over) g.swap(cell.cid, over)
                    else if (dr && (dr.x !== cell.pp.x || dr.y !== cell.pp.y)) g.moveTo(cell.cid, dr.x, dr.y)
                }
            }
            // remove
            Rectangle {
                visible: g.editing && !cell.dragging
                x: cell.width >= 150 ? cell.width - width - 8 : (cell.width - width) / 2
                y: cell.width >= 150 ? 8 : 8
                width: 28; height: 28; radius: 14
                color: xm.containsMouse ? "#e0505a" : "#c4444d"
                scale: xm.pressed ? 0.9 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                MIcon { anchors.centerIn: parent; name: "close"; glyph: ""; size: 15; color: "#ffffff" }
                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: g.remove(cell.cid) }
            }
            // resize: hold an edge or the corner and drag
            Grip { host: cell; kind: "right" }
            Grip { host: cell; kind: "bottom" }
            Grip { host: cell; kind: "corner" }
            // size while resizing
            Rectangle {
                visible: cell.sizing
                anchors.centerIn: parent
                width: szT.implicitWidth + 22; height: 30; radius: 15
                color: g.d.p.primary
                DText { id: szT; anchors.centerIn: parent; text: g.rsW + " × " + g.rsH; font.pixelSize: 13; font.weight: Font.DemiBold; color: g.d.p.inkOn }
            }

        }
    }

    // ---------- the + menu: pick a card for this spot ----------
    Rectangle {
        id: menu
        readonly property var hid: g.pickAt ? g.hidden() : []
        visible: g.editing && g.pickAt !== null
        z: 20
        width: 220
        height: Math.min(g.height, mcol.implicitHeight + 16)
        radius: 16
        color: g.d.p.solidBg
        border.width: 1
        border.color: g.d.p.dark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1)
        readonly property real ax: g.pickAt ? g.cellX(g.pickAt.x) + g.cw / 2 : 0
        readonly property real ay: g.pickAt ? g.cellY(g.pickAt.y) : 0
        x: Math.max(0, Math.min(g.width - width, ax - width / 2))
        y: Math.max(0, Math.min(g.height - height, ay))
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Column {
            id: mcol
            x: 8; y: 8
            width: parent.width - 16
            spacing: 2
            DText { text: "Put here"; font.pixelSize: 11; color: g.d.p.sub; leftPadding: 8; bottomPadding: 4 }
            Repeater {
                model: menu.hid
                Rectangle {
                    width: mcol.width; height: 34; radius: 10
                    color: mi.containsMouse ? g.d.p.card2 : "transparent"
                    DText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; font.pixelSize: 13; color: g.d.p.text }
                    MouseArea {
                        id: mi
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { const at = g.pickAt; g.pickAt = null; g.addAt(modelData.id, at.x, at.y) }
                    }
                }
            }
        }
    }

    component Grip: Item {
        id: gr
        property Item host
        property string kind: "corner"
        readonly property bool wide: kind !== "bottom"
        readonly property bool tall: kind !== "right"
        visible: g.editing && !gr.host.dragging && (kind === "corner" || (kind === "right" ? gr.host.width >= 90 : gr.host.height >= 90))
        width: kind === "bottom" ? Math.min(60, gr.host.width * 0.4) : (kind === "right" ? 14 : 26)
        height: kind === "right" ? Math.min(60, gr.host.height * 0.4) : (kind === "bottom" ? 14 : 26)
        x: kind === "bottom" ? (gr.host.width - width) / 2 : gr.host.width - width + (kind === "right" ? 5 : 3)
        y: kind === "right" ? (gr.host.height - height) / 2 : gr.host.height - height + (kind === "bottom" ? 5 : 3)
        z: 5
        Rectangle {
            // a pill on the edges, a round knob in the corner
            anchors.centerIn: parent
            width: gr.kind === "corner" ? 18 : (gr.kind === "right" ? 6 : parent.width)
            height: gr.kind === "corner" ? 18 : (gr.kind === "bottom" ? 6 : parent.height)
            radius: Math.min(width, height) / 2
            color: gm.containsMouse || gm.pressed ? g.d.p.primary : Qt.rgba(0.62, 0.62, 0.66, 0.9)
            border.width: gr.kind === "corner" ? 3 : 0
            border.color: g.d.p.solidBg
            scale: gm.pressed ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
            id: gm
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            preventStealing: true
            cursorShape: gr.kind === "corner" ? Qt.SizeFDiagCursor : (gr.kind === "right" ? Qt.SizeHorCursor : Qt.SizeVerCursor)
            onPressed: { g.pickAt = null; g.rsW = gr.host.pp.w; g.rsH = gr.host.pp.h; g.rsId = gr.host.cid }
            onPositionChanged: function(m) {
                if (!pressed) return
                const p = mapToItem(g, m.x, m.y)
                const mn = g.minOf(gr.host.cid)
                let w = gr.host.pp.w, h = gr.host.pp.h
                if (gr.wide) w = Math.max(mn[0], Math.min(g.cols - gr.host.pp.x, Math.round((p.x - g.cellX(gr.host.pp.x) + g.gap) / (g.cw + g.gap))))
                if (gr.tall) h = Math.max(mn[1], Math.min(g.rows - gr.host.pp.y, Math.round((p.y - g.cellY(gr.host.pp.y) + g.gap) / (g.rh + g.gap))))
                // grow only into free cells; shrink back step by step until it fits
                while (!g.fits(g.packed.used, gr.host.pp.x, gr.host.pp.y, w, h, gr.host.cid) && (w > mn[0] || h > mn[1])) {
                    if (w > g.rsW && w > mn[0]) w--
                    else if (h > g.rsH && h > mn[1]) h--
                    else if (w > mn[0]) w--
                    else h--
                }
                if (g.fits(g.packed.used, gr.host.pp.x, gr.host.pp.y, w, h, gr.host.cid)) { g.rsW = w; g.rsH = h }
            }
            onReleased: {
                const w = g.rsW, h = g.rsH
                g.rsId = ""
                if (w !== gr.host.pp.w || h !== gr.host.pp.h) g.setSize(gr.host.cid, w, h)
            }
        }
    }
}
