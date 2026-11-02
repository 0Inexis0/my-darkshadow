import Quickshell
import Quickshell.Io
import QtQuick

// Audio visualizer (cava). No background; styles: bars (round pills), mirror, wave, dots.
// colors: accent (your theme color), gradient (it shifts along the bars), rainbow, mono (white, or black on a light wallpaper).
// flip: grow downwards instead of upwards.
Item {
    id: vz
    property bool running: true
    property string style: "bars"
    property string colorMode: "accent"
    property bool flip: false
    property var pal: null            // the widget's palette: tells if the wallpaper behind is light
    property var bars: []
    readonly property int count: 64
    readonly property real pitch: width / count
    readonly property real gap: style === "dots" ? 4 : (style === "wave" ? 3 : Math.max(3, Math.min(14, pitch * 0.34)))
    readonly property real bw: Math.max(1, (width - gap * (count - 1)) / count)

    readonly property bool lightBg: pal ? pal.light : false
    readonly property color acc: Look.accent
    readonly property real hue: acc.hslHue < 0 ? 0 : acc.hslHue
    readonly property real sat: acc.hslSaturation < 0.08 ? acc.hslSaturation : Math.max(0.5, Math.min(0.95, acc.hslSaturation))
    readonly property real tone: lightBg ? 0.38 : 0.72
    // the color of bar i (0..count-1)
    function colorAt(i) {
        const t = count > 1 ? i / (count - 1) : 0
        switch (colorMode) {
        case "gradient": return Qt.hsla((hue + 0.22 * t) % 1, Math.max(sat, 0.55), tone, 1)
        case "rainbow": return Qt.hsla(t * 0.85, 0.75, lightBg ? 0.42 : 0.68, 1)
        case "mono": return lightBg ? Qt.rgba(0.08, 0.08, 0.1, 1) : Qt.rgba(1, 1, 1, 1)
        default: return Qt.hsla(hue, sat, tone, 1)
        }
    }
    function css(c, a) { return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")" }
    onColorModeChanged: cv.requestPaint()
    onLightBgChanged: cv.requestPaint()
    onAccChanged: cv.requestPaint()

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

    // bars and mirror: round pills that fade toward their base (cheap on the GPU)
    Row {
        visible: vz.style === "bars" || vz.style === "mirror"
        anchors.fill: parent
        spacing: vz.gap
        Repeater {
            model: vz.count
            delegate: Item {
                id: bar
                width: vz.bw
                height: vz.height
                readonly property real v: vz.bars[index] !== undefined ? vz.bars[index] / 100 : 0
                readonly property color c: vz.colorAt(index)
                // opacity at the top, middle and bottom end of the pill: the tip is strong, the base fades
                readonly property real aTop: vz.style === "mirror" ? 0.9 : (vz.flip ? 0.28 : 0.92)
                readonly property real aBot: vz.style === "mirror" ? 0.9 : (vz.flip ? 0.92 : 0.28)
                readonly property real aMid: vz.style === "mirror" ? 0.34 : (aTop + aBot) / 2
                Rectangle {
                    width: bar.width
                    height: Math.max(width, vz.height * bar.v)
                    radius: width / 2
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0; color: Qt.rgba(bar.c.r, bar.c.g, bar.c.b, bar.aTop) }
                        GradientStop { position: 0.5; color: Qt.rgba(bar.c.r, bar.c.g, bar.c.b, bar.aMid) }
                        GradientStop { position: 1; color: Qt.rgba(bar.c.r, bar.c.g, bar.c.b, bar.aBot) }
                    }
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
                // the fill fades toward the base; the colors run along the wave
                const fill = c.createLinearGradient(0, 0, W, 0)
                const line = c.createLinearGradient(0, 0, W, 0)
                for (let s = 0; s <= 8; s++) {
                    const col = vz.colorAt(Math.round(s / 8 * (n - 1)))
                    fill.addColorStop(s / 8, vz.css(col, 0.30))
                    line.addColorStop(s / 8, vz.css(col, 0.95))
                }
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
                c.fillStyle = fill
                c.fill()
                c.beginPath()
                c.moveTo(pts[0][0], pts[0][1])
                for (let i = 1; i < n; i++) {
                    const mx = (pts[i - 1][0] + pts[i][0]) / 2, my = (pts[i - 1][1] + pts[i][1]) / 2
                    c.quadraticCurveTo(pts[i - 1][0], pts[i - 1][1], mx, my)
                }
                c.lineWidth = 3
                c.lineCap = "round"
                c.strokeStyle = line
                c.stroke()
            } else {
                const d = Math.max(2, Math.min(vz.bw, 10))
                const step = d + 3
                for (let i = 0; i < n; i++) {
                    const v = (b[i] || 0) / 100
                    const k = Math.max(1, Math.round(v * H / step))
                    const x = i * (vz.bw + vz.gap) + vz.bw / 2
                    const col = vz.colorAt(i)
                    for (let j = 0; j < k; j++) {
                        const y = vz.flip ? d / 2 + j * step : H - d / 2 - j * step
                        c.fillStyle = vz.css(col, (0.35 + 0.6 * (1 - j / Math.max(1, k))).toFixed(2))
                        c.beginPath()
                        c.arc(x, y, d / 2, 0, Math.PI * 2)
                        c.fill()
                    }
                }
            }
        }
    }
}
