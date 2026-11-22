import QtQuick

// Files: the box you drag on the empty space to choose files (Ctrl adds to what is chosen). It scrolls when it
// reaches the top or the bottom. A right click on the empty space: the folder's menu.
MouseArea {
    id: b
    property var view
    property var fv
    readonly property var fa: fv.fa
    readonly property bool isGrid: view.cellWidth !== undefined
    parent: view.contentItem
    z: -1
    x: 0
    y: view.originY
    width: view.width
    height: Math.max(view.contentHeight + view.bottomMargin + (isGrid ? 0 : 40), view.height + Math.abs(view.originY))
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    preventStealing: true
    property point a: Qt.point(0, 0)
    property point p: Qt.point(0, 0)
    property bool on: false
    property bool add: false
    property var base: ({})
    property real vy: 0
    onPressed: function(m) {
        b.fa.forceActiveFocus()
        if (m.button !== Qt.LeftButton) return
        add = (m.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) !== 0
        base = add ? Object.assign({}, b.fa.sel) : ({})
        if (!add) b.fa.clearSel()
        a = Qt.point(m.x, m.y + y)
        p = a
        on = false
    }
    onPositionChanged: function(m) {
        if (!(pressedButtons & Qt.LeftButton)) return
        p = Qt.point(m.x, m.y + y)
        vy = p.y - view.contentY
        if (!on && Math.abs(p.x - a.x) + Math.abs(p.y - a.y) > 6) on = true
        if (on) pick()
    }
    onReleased: on = false
    onClicked: function(m) { if (m.button === Qt.RightButton) b.fv.bgMenu(b, m) }
    function pick() {
        const x0 = Math.min(a.x, p.x), x1 = Math.max(a.x, p.x), y0 = Math.min(a.y, p.y), y1 = Math.max(a.y, p.y)
        const n = view.count, idx = []
        if (isGrid) {
            const cw = view.cellWidth, ch = view.cellHeight, cols = Math.max(1, Math.floor(view.width / cw))
            const c0 = Math.max(0, Math.floor(x0 / cw)), c1 = Math.min(cols - 1, Math.floor(x1 / cw))
            const r0 = Math.max(0, Math.floor(y0 / ch)), r1 = Math.floor(y1 / ch)
            for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) { const i = r * cols + c; if (i < n) idx.push(i) }
        } else {
            const r0 = Math.max(0, Math.floor(y0 / 44)), r1 = Math.min(n - 1, Math.floor(y1 / 44))
            for (let r = r0; r <= r1; r++) idx.push(r)
        }
        b.fa.selectSet(idx, add, base)
    }
    Timer {
        interval: 30
        repeat: true
        running: b.on
        onTriggered: {
            const v = b.view, edge = 36
            let d = 0
            if (b.vy < edge) d = -Math.min(24, (edge - b.vy) / 2)
            else if (b.vy > v.height - edge) d = Math.min(24, (b.vy - v.height + edge) / 2)
            if (d === 0) return
            const max = Math.max(v.originY, v.contentHeight + v.originY - v.height + v.bottomMargin)
            const ny = Math.max(v.originY, Math.min(max, v.contentY + d))
            if (ny === v.contentY) return
            v.contentY = ny
            b.p = Qt.point(b.p.x, b.vy + v.contentY)
            b.pick()
        }
    }
    Rectangle {
        visible: b.on
        x: Math.min(b.a.x, b.p.x)
        y: Math.min(b.a.y, b.p.y) - b.y
        width: Math.abs(b.p.x - b.a.x)
        height: Math.abs(b.p.y - b.a.y)
        radius: 6
        color: Theme.alpha(Theme.primary, 0.14)
        border.width: 1
        border.color: Theme.alpha(Theme.primary, 0.7)
    }
}
