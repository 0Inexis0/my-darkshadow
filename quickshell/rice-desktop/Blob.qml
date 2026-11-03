import QtQuick

// A soft shape for the expressive widgets, drawn our own way:
//   cookie (scalloped circle), flower (round petals), clover (4 leaves), pentagon / hexagon / square (rounded
//   corners), sun (many small bumps), circle. Filled with `color`, optional outline. Drawn once, it only repaints
//   when its size, kind or color changes (turning it is done by rotating the item, which costs nothing).
Canvas {
    id: b
    property string kind: "cookie"
    property color color: "#33363a"
    property color line: "transparent"
    property real lineWidth: 0
    property real corner: 0.22          // polygons: how round the corners are (0 .. 0.5 of the side)
    readonly property var kinds: ["cookie", "flower", "clover", "pentagon", "hexagon", "square", "sun", "circle"]
    renderStrategy: Canvas.Cooperative
    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onLineChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // radius of a wavy shape at angle a, for a shape that fits in R
    function wave(a, R) {
        switch (kind) {
        case "cookie": return R * (0.93 + 0.07 * Math.cos(9 * a))
        case "flower": return R * (0.80 + 0.20 * Math.pow(Math.abs(Math.cos(4 * a)), 0.7))
        case "clover": return R * (0.70 + 0.30 * Math.pow(Math.abs(Math.cos(2 * a)), 0.55))
        case "sun": return R * (0.95 + 0.05 * Math.cos(16 * a))
        default: return R
        }
    }
    function sides() { return kind === "pentagon" ? 5 : (kind === "hexagon" ? 6 : (kind === "square" ? 4 : 0)) }

    onPaint: {
        const c = getContext("2d")
        c.reset()
        const cx = width / 2, cy = height / 2, R = Math.min(width, height) / 2 - Math.max(1, lineWidth)
        c.beginPath()
        const n = sides()
        if (n > 0) {
            // a polygon with round corners: arcTo from the middle of each side
            const rot = -Math.PI / 2 + (n === 4 ? Math.PI / 4 : 0)
            const Rp = R / (n === 4 ? 0.92 : 1)
            const pts = []
            for (let i = 0; i < n; i++) pts.push([cx + Rp * Math.cos(rot + i * 2 * Math.PI / n), cy + Rp * Math.sin(rot + i * 2 * Math.PI / n)])
            const side = Math.hypot(pts[1][0] - pts[0][0], pts[1][1] - pts[0][1])
            const rr = side * corner
            const m0 = [(pts[0][0] + pts[n - 1][0]) / 2, (pts[0][1] + pts[n - 1][1]) / 2]
            c.moveTo(m0[0], m0[1])
            for (let i = 0; i < n; i++) {
                const p = pts[i], q = pts[(i + 1) % n]
                c.arcTo(p[0], p[1], (p[0] + q[0]) / 2, (p[1] + q[1]) / 2, rr)
            }
        } else if (kind === "circle") {
            c.arc(cx, cy, R, 0, Math.PI * 2)
        } else {
            const steps = 240
            for (let i = 0; i <= steps; i++) {
                const a = i * 2 * Math.PI / steps
                const r = wave(a, R)
                const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a)
                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
        }
        c.closePath()
        c.fillStyle = color
        c.fill()
        if (lineWidth > 0) { c.strokeStyle = line; c.lineWidth = lineWidth; c.stroke() }
    }
}
