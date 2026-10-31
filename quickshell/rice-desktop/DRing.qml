import QtQuick

// Round progress ring (0..100) with an open gap at the bottom, like Material 3 gauges.
Canvas {
    id: r
    property var p
    property real value: 0
    property real line: 6
    property bool gapped: true
    property color fg: p ? p.primary : "#F6F5F4"
    property color bgc: p ? p.track : Qt.rgba(1, 1, 1, 0.1)
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    onShownChanged: requestPaint()
    onFgChanged: requestPaint()
    onBgcChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.reset()
        const R = Math.min(width, height) / 2 - line / 2 - 1
        const cx = width / 2, cy = height / 2
        const gap = gapped ? 0.18 * Math.PI : 0
        const a0 = Math.PI / 2 + gap, span = 2 * Math.PI - 2 * gap
        const v = Math.max(0, Math.min(100, shown)) / 100
        c.lineCap = "round"
        c.lineWidth = line
        c.strokeStyle = bgc
        c.beginPath(); c.arc(cx, cy, R, a0 + span * v + (v > 0 ? 0.25 : 0), a0 + span); c.stroke()
        if (v > 0.005) {
            c.strokeStyle = fg
            c.beginPath(); c.arc(cx, cy, R, a0, a0 + span * v); c.stroke()
        }
    }
}
