import Quickshell
import Quickshell.Io
import QtQuick

// Audio visualizer (cava). No background; styles: bars, mirror, wave, dots.
// flip: grow downwards instead of upwards.
Item {
    id: vz
    property bool running: true
    property string style: "bars"
    property bool flip: false
    property var bars: []
    readonly property int count: 64
    readonly property real gap: style === "dots" ? 4 : 3
    readonly property real bw: Math.max(1, (width - gap * (count - 1)) / count)

    Process {
        command: [Quickshell.env("HOME") + "/.local/bin/rice-cava"]
        running: vz.running && vz.visible
        stdout: SplitParser {
            onRead: function(line) {
                const p = line.split(";").filter(function(s) { return s.length > 0 }).map(Number)
                if (p.length > 0) { vz.bars = p; if (vz.style === "wave" || vz.style === "dots") cv.requestPaint() }
            }
        }
    }

    // bars and mirror: plain rectangles (cheap on the GPU)
    Row {
        visible: vz.style === "bars" || vz.style === "mirror"
        anchors.fill: parent
        spacing: vz.gap
        Repeater {
            model: vz.count
            delegate: Item {
                width: vz.bw
                height: vz.height
                readonly property real v: vz.bars[index] !== undefined ? vz.bars[index] / 100 : 0
                Rectangle {
                    width: parent.width
                    height: Math.max(3, (vz.style === "mirror" ? vz.height : vz.height) * parent.v)
                    radius: Math.min(width / 2, 4)
                    color: "#F6F5F4"
                    opacity: 0.35 + 0.55 * parent.v
                    y: vz.style === "mirror" ? (vz.height - height) / 2 : (vz.flip ? 0 : vz.height - height)
                    Behavior on height { NumberAnimation { duration: 70 } }
                }
            }
        }
    }

    // wave and dots: drawn
    Canvas {
        id: cv
        visible: vz.style === "wave" || vz.style === "dots"
        anchors.fill: parent
        onVisibleChanged: requestPaint()
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const n = vz.count, W = width, H = height, b = vz.bars
            if (!b || b.length === 0) return
            if (vz.style === "wave") {
                const pts = []
                for (let i = 0; i < n; i++) {
                    const v = (b[i] || 0) / 100
                    const x = i * W / (n - 1)
                    pts.push([x, vz.flip ? v * H * 0.95 : H - v * H * 0.95])
                }
                const base = vz.flip ? 0 : H
                const grad = c.createLinearGradient(0, vz.flip ? H : 0, 0, base)
                grad.addColorStop(0, "rgba(246,245,244,0.05)")
                grad.addColorStop(1, "rgba(246,245,244,0.35)")
                c.beginPath()
                c.moveTo(0, base)
                c.lineTo(pts[0][0], pts[0][1])
                for (let i = 1; i < n; i++) {
                    const mx = (pts[i - 1][0] + pts[i][0]) / 2, my = (pts[i - 1][1] + pts[i][1]) / 2
                    c.quadraticCurveTo(pts[i - 1][0], pts[i - 1][1], mx, my)
                }
                c.lineTo(W, pts[n - 1][1])
                c.lineTo(W, base)
                c.closePath()
                c.fillStyle = grad
                c.fill()
                c.beginPath()
                c.moveTo(pts[0][0], pts[0][1])
                for (let i = 1; i < n; i++) {
                    const mx = (pts[i - 1][0] + pts[i][0]) / 2, my = (pts[i - 1][1] + pts[i][1]) / 2
                    c.quadraticCurveTo(pts[i - 1][0], pts[i - 1][1], mx, my)
                }
                c.lineWidth = 2.5
                c.strokeStyle = "rgba(246,245,244,0.9)"
                c.stroke()
            } else {
                const d = Math.max(2, Math.min(vz.bw, 8))
                const step = d + 3
                for (let i = 0; i < n; i++) {
                    const v = (b[i] || 0) / 100
                    const k = Math.max(1, Math.round(v * H / step))
                    const x = i * (vz.bw + vz.gap) + vz.bw / 2
                    for (let j = 0; j < k; j++) {
                        const y = vz.flip ? d / 2 + j * step : H - d / 2 - j * step
                        c.fillStyle = "rgba(246,245,244," + (0.3 + 0.6 * (1 - j / Math.max(1, k))).toFixed(2) + ")"
                        c.beginPath()
                        c.arc(x, y, d / 2, 0, Math.PI * 2)
                        c.fill()
                    }
                }
            }
        }
    }
}
