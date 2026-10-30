import QtQuick

Item {
    id: ck
    property string clockStyle: "digital"
    property string mode: "draggable"
    property string wallpaper: ""
    property int bw: 1920
    property int bh: 1080
    property date now: new Date()
    property real fx: -1
    property real fy: -1
    readonly property int natW: clockStyle === "cookie" ? 260 : (clockStyle === "pixel" ? 270 : 200)
    readonly property int natH: clockStyle === "cookie" ? 260 : (clockStyle === "pixel" ? 100 : 310)

    function pad(n) { return n < 10 ? "0" + n : "" + n }
    readonly property string hh: pad(now.getHours())
    readonly property string mm: pad(now.getMinutes())

    Timer { interval: 1000; running: true; repeat: true; onTriggered: ck.now = new Date() }

    // ---- digital
    Column {
        visible: ck.clockStyle === "digital"
        anchors.centerIn: parent
        spacing: -42
        T { kind: "number"; text: ck.hh; font.pixelSize: 150; font.bold: true; color: "#F6F5F4"; opacity: 0.85; anchors.horizontalCenter: parent.horizontalCenter }
        T { kind: "number"; text: ck.mm; font.pixelSize: 150; font.bold: true; color: "#F6F5F4"; opacity: 0.45; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // ---- cookie
    Canvas {
        id: cookie
        visible: ck.clockStyle === "cookie"
        anchors.centerIn: parent
        width: 250
        height: 250
        property real sec: ck.now.getSeconds()
        onSecChanged: requestPaint()
        onVisibleChanged: requestPaint()
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const cx = 125, cy = 125, R = 112
            c.fillStyle = "rgba(44,44,48,0.82)"
            c.beginPath()
            for (let i = 0; i <= 360; i++) {
                const a = i * Math.PI / 180
                const r = R * (1 + 0.05 * Math.cos(12 * a))
                const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a)
                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.closePath()
            c.fill()
            c.fillStyle = "rgba(255,255,255,0.35)"
            for (let h = 0; h < 12; h++) {
                const a = h * Math.PI / 6
                c.beginPath()
                c.arc(cx + 88 * Math.sin(a), cy - 88 * Math.cos(a), h % 3 === 0 ? 4 : 2.5, 0, Math.PI * 2)
                c.fill()
            }
            const d = ck.now
            const hAng = ((d.getHours() % 12) + d.getMinutes() / 60) * Math.PI / 6
            const mAng = (d.getMinutes() + d.getSeconds() / 60) * Math.PI / 30
            const sAng = d.getSeconds() * Math.PI / 30
            c.lineCap = "round"
            c.strokeStyle = "#F6F5F4"
            c.lineWidth = 9
            c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + 46 * Math.sin(hAng), cy - 46 * Math.cos(hAng)); c.stroke()
            c.lineWidth = 6
            c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + 72 * Math.sin(mAng), cy - 72 * Math.cos(mAng)); c.stroke()
            c.strokeStyle = "rgba(246,245,244,0.55)"
            c.lineWidth = 2
            c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + 82 * Math.sin(sAng), cy - 82 * Math.cos(sAng)); c.stroke()
            c.fillStyle = "#F6F5F4"
            c.beginPath(); c.arc(cx, cy, 6, 0, Math.PI * 2); c.fill()
        }
    }

    // ---- pixel
    Canvas {
        id: pixel
        visible: ck.clockStyle === "pixel"
        anchors.centerIn: parent
        readonly property int cell: 14
        width: 17 * cell
        height: 5 * cell
        property string txt: ck.hh + ck.mm
        onTxtChanged: requestPaint()
        onVisibleChanged: requestPaint()
        readonly property var glyphs: ({
            "0": ["111","101","101","101","111"], "1": ["010","110","010","010","111"],
            "2": ["111","001","111","100","111"], "3": ["111","001","111","001","111"],
            "4": ["101","101","111","001","001"], "5": ["111","100","111","001","111"],
            "6": ["111","100","111","101","111"], "7": ["111","001","001","001","001"],
            "8": ["111","101","111","101","111"], "9": ["111","101","111","001","111"],
            ":": ["0","1","0","1","0"]
        })
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const seq = [txt[0], txt[1], ":", txt[2], txt[3]]
            let x = 0
            c.fillStyle = "#F6F5F4"
            for (let s = 0; s < seq.length; s++) {
                const g = glyphs[seq[s]]
                if (!g) continue
                for (let r = 0; r < g.length; r++)
                    for (let q = 0; q < g[r].length; q++)
                        if (g[r][q] === "1") {
                            c.globalAlpha = s < 2 ? 0.9 : (s === 2 ? 0.6 : 0.5)
                            c.fillRect((x + q) * cell + 1, r * cell + 1, cell - 2, cell - 2)
                        }
                x += g[0].length + 1
            }
        }
    }

    // ---- wallpaper busyness analysis (used by "least/most busy")
    Canvas {
        id: an
        width: 128
        height: 72
        opacity: 0.01
        z: -1
        renderTarget: Canvas.Image
        property string src: (ck.mode !== "draggable" && ck.wallpaper !== "") ? "file://" + ck.wallpaper : ""
        onSrcChanged: if (src !== "") loadImage(src)
        Component.onCompleted: if (src !== "") loadImage(src)
        onImageLoaded: requestPaint()
        onPaint: {
            if (src === "" || !isImageLoaded(src)) return
            const c = getContext("2d")
            c.drawImage(src, 0, 0, width, height)
            const px = c.getImageData(0, 0, width, height).data
            const g = new Array(width * height)
            for (let i = 0; i < g.length; i++) g[i] = 0.3 * px[i * 4] + 0.59 * px[i * 4 + 1] + 0.11 * px[i * 4 + 2]
            const E = [0, 0, 0, 0, 0, 0, 0, 0, 0]
            for (let y = 1; y < height; y++)
                for (let x = 1; x < width; x++) {
                    const e = Math.abs(g[y * width + x] - g[y * width + x - 1]) + Math.abs(g[y * width + x] - g[(y - 1) * width + x])
                    const cx = Math.min(2, Math.floor(x / (width / 3)))
                    const cy = Math.min(2, Math.floor(y / (height / 3)))
                    E[cy * 3 + cx] += e
                }
            let best = 4
            for (let i = 0; i < 9; i++) {
                if (ck.mode === "leastBusy" ? E[i] < E[best] : E[i] > E[best]) best = i
            }
            ck.fx = ((best % 3) + 0.5) / 3
            ck.fy = (Math.floor(best / 3) + 0.5) / 3
        }
    }
}
