import QtQuick

// Cards of one dashboard tab on a grid (12 columns). The order and sizes come from your layout;
// in edit mode you remove, add, resize (cycle sizes) and drag cards onto each other to swap them.
Item {
    id: g
    property var d
    property string tabId: ""
    property var catalog: []        // [{ id, name, icon, glyph, sizes: [[w, h], ...] }]
    property var defaults: []       // [{ id, w, h }]
    property var comps: ({})        // id -> Component (a DCard)
    property int cols: 12
    property int rows: 2
    property bool live: false
    readonly property bool editing: d && d.editing && d.tab === tabId
    readonly property real gap: 12
    readonly property real cw: (width - (cols - 1) * gap) / cols
    readonly property real rh: (height - (rows - 1) * gap) / rows

    readonly property var layout: d && d.layouts && d.layouts[tabId] ? d.layouts[tabId] : defaults
    readonly property var packed: pack(layout)

    function info(id) { for (let i = 0; i < catalog.length; i++) if (catalog[i].id === id) return catalog[i]; return null }
    // first free spot, row by row
    function pack(l) {
        const used = []
        for (let r = 0; r < rows; r++) { used.push([]); for (let c = 0; c < cols; c++) used[r].push(false) }
        const pos = {}, out = []
        for (let i = 0; i < l.length; i++) {
            const it = l[i]
            if (!info(it.id)) continue
            const w = Math.max(1, Math.min(cols, it.w)), h = Math.max(1, Math.min(rows, it.h))
            let done = false
            for (let r = 0; r + h <= rows && !done; r++) {
                for (let c = 0; c + w <= cols && !done; c++) {
                    let free = true
                    for (let y = r; y < r + h && free; y++) for (let x = c; x < c + w && free; x++) if (used[y][x]) free = false
                    if (free) {
                        for (let y = r; y < r + h; y++) for (let x = c; x < c + w; x++) used[y][x] = true
                        pos[it.id] = { x: c, y: r, w: w, h: h, order: i }
                        done = true
                    }
                }
            }
            if (!done) out.push(it.id)
        }
        return { pos: pos, out: out }
    }
    function hidden() {
        const inL = layout.map(function(x) { return x.id })
        return catalog.filter(function(c) { return inL.indexOf(c.id) < 0 || packed.out.indexOf(c.id) >= 0 })
    }
    function save(l) { d.saveLayout(tabId, l) }
    function add(id) {
        const c = info(id)
        const base = layout.filter(function(x) { return x.id !== id })
        for (let i = 0; i < c.sizes.length; i++) {
            const t = base.concat([{ id: id, w: c.sizes[i][0], h: c.sizes[i][1] }])
            if (pack(t).pos[id]) { save(t); return true }
        }
        d.toast("No room for " + c.name + ". Remove or shrink a card first.")
        return false
    }
    function remove(id) { save(layout.filter(function(x) { return x.id !== id })) }
    function resize(id) {
        const c = info(id), cur = layout.filter(function(x) { return x.id === id })[0]
        if (!c || !cur) return
        let k = 0
        for (let i = 0; i < c.sizes.length; i++) if (c.sizes[i][0] === cur.w && c.sizes[i][1] === cur.h) k = i
        for (let s = 1; s < c.sizes.length; s++) {
            const sz = c.sizes[(k + s) % c.sizes.length]
            const t = layout.map(function(x) { return x.id === id ? { id: id, w: sz[0], h: sz[1] } : x })
            if (pack(t).out.length <= packed.out.length && pack(t).pos[id]) { save(t); return }
        }
        d.toast("No other size fits here")
    }
    function swap(a, b) {
        const t = layout.slice()
        const i = t.findIndex(function(x) { return x.id === a }), j = t.findIndex(function(x) { return x.id === b })
        if (i < 0 || j < 0) return
        const tmp = t[i]; t[i] = t[j]; t[j] = tmp
        save(t)
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
    Component.onCompleted: { sync(); if (d) d.registerGrid(tabId, g) }

    property string dragId: ""
    property real dragX: 0
    property real dragY: 0
    property string overId: ""

    Repeater {
        model: lm
        delegate: Item {
            id: cell
            readonly property string cid: model.cid
            readonly property var pp: g.packed.pos[cid] || ({ x: 0, y: 0, w: 1, h: 1, order: 0 })
            readonly property bool dragging: g.dragId === cid
            x: dragging ? g.dragX : pp.x * (g.cw + g.gap)
            y: dragging ? g.dragY : pp.y * (g.rh + g.gap)
            width: pp.w * g.cw + (pp.w - 1) * g.gap
            height: pp.h * g.rh + (pp.h - 1) * g.gap
            z: dragging ? 10 : 1
            Behavior on x { enabled: !cell.dragging; NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            Behavior on y { enabled: !cell.dragging; NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
            Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
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
                border.color: g.overId === cell.cid ? g.d.p.primary : Qt.rgba(0.5, 0.5, 0.5, 0.45)
                Rectangle {
                    visible: cell.width >= 150
                    anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8
                    width: nm.implicitWidth + 16; height: 22; radius: 11
                    color: g.d.p.primary
                    DText { id: nm; anchors.centerIn: parent; text: (g.info(cell.cid) || {}).name || cell.cid; font.pixelSize: 10; font.weight: Font.DemiBold; color: g.d.p.onPrimary }
                }
            }
            MouseArea {
                visible: g.editing
                anchors.fill: parent
                cursorShape: cell.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real sx: 0
                property real sy: 0
                property bool moved: false
                onPressed: function(m) { const p = mapToItem(g, m.x, m.y); sx = p.x - cell.x; sy = p.y - cell.y; moved = false }
                onPositionChanged: function(m) {
                    const p = mapToItem(g, m.x, m.y)
                    if (!moved && Math.abs(p.x - sx - cell.x) + Math.abs(p.y - sy - cell.y) < 6) return
                    if (!moved) { moved = true; g.dragX = cell.x; g.dragY = cell.y; g.dragId = cell.cid }
                    g.dragX = p.x - sx; g.dragY = p.y - sy
                    // which card is under the pointer
                    let over = ""
                    for (const id in g.packed.pos) {
                        if (id === cell.cid) continue
                        const q = g.packed.pos[id]
                        const x0 = q.x * (g.cw + g.gap), y0 = q.y * (g.rh + g.gap)
                        const x1 = x0 + q.w * g.cw + (q.w - 1) * g.gap, y1 = y0 + q.h * g.rh + (q.h - 1) * g.gap
                        if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1) over = id
                    }
                    g.overId = over
                }
                onReleased: {
                    const over = g.overId
                    g.dragId = ""; g.overId = ""
                    if (moved && over) g.swap(cell.cid, over)
                }
            }
            Row {
                visible: g.editing && !cell.dragging
                // small cards: buttons at the bottom, in the middle
                x: cell.width >= 150 ? cell.width - width - 8 : (cell.width - width) / 2
                y: cell.width >= 150 ? 8 : cell.height - height - 8
                spacing: 6
                EBtn { icon: "open_in_full"; glyph: ""; onClicked: g.resize(cell.cid) }
                EBtn { icon: "close"; glyph: ""; danger: true; onClicked: g.remove(cell.cid) }
            }
        }
    }

    component EBtn: Rectangle {
        id: eb
        property string icon: ""
        property string glyph: ""
        property bool danger: false
        signal clicked()
        width: 28; height: 28; radius: 14
        color: danger ? (em.containsMouse ? "#e0505a" : "#c4444d") : (em.containsMouse ? Qt.lighter(g.d.p.primary, 1.1) : g.d.p.primary)
        scale: em.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        MIcon { anchors.centerIn: parent; name: eb.icon; glyph: eb.glyph; size: 15; color: eb.danger ? "#ffffff" : g.d.p.onPrimary }
        MouseArea { id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: eb.clicked() }
    }
}
