import Quickshell
import Quickshell.Io
import QtQuick

// Desktop widget "Gauge": one number in a soft shape (pentagon, cookie, flower ...) with a wavy ring that
// fills up: CPU, RAM, GPU, CPU temperature or battery. Settings > Desktop > Edit widgets: shape and value.
Item {
    id: gw
    property var pal: null
    property real bg: 1
    property bool running: true
    property string shape: "pentagon"
    property string metric: "cpu"
    property real val: 0                 // 0 .. 100
    property string big: "0"
    property string unit: "%"
    property string label: "CPU"
    property string sym: "\uf4bc"
    readonly property color fill: pal ? pal.primary : "#F6F5F4"
    readonly property color ink: pal ? pal.fg : "#F6F5F4"

    function take(j) {
        if (metric === "ram") { val = j.ram; big = String(j.ram); unit = "%"; label = "RAM · " + j.ramu + " GB"; sym = "\udb80\udf5b" }
        else if (metric === "gpu") { val = j.gpu; big = String(j.gpu); unit = "%"; label = j.gtemp ? "GPU · " + j.gtemp + "°" : "GPU"; sym = "\udb82\udcae" }
        else if (metric === "temp") { val = Math.min(100, j.temp); big = j.temp ? String(j.temp) : "–"; unit = "°C"; label = "CPU heat"; sym = "\uf2c9" }
        else { val = j.cpu; big = String(j.cpu); unit = "%"; label = j.temp ? "CPU · " + j.temp + "°" : "CPU"; sym = "\uf4bc" }
    }
    Process {
        command: [Quickshell.env("HOME") + "/.local/bin/rice-stats"]
        running: gw.running && gw.metric !== "battery"
        stdout: SplitParser { onRead: function(line) { try { gw.take(JSON.parse(line)) } catch (e) { } } }
    }
    // battery from sysfs, no extra program
    Timer {
        interval: 20000; repeat: true; triggeredOnStart: true
        running: gw.running && gw.metric === "battery"
        onTriggered: batProc.running = true
    }
    Process {
        id: batProc
        command: ["bash", "-c", "for b in /sys/class/power_supply/BAT*; do echo \"$(cat $b/capacity) $(cat $b/status)\"; break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ")
                const n = parseInt(p[0])
                gw.val = isNaN(n) ? 0 : n; gw.big = isNaN(n) ? "–" : String(n); gw.unit = "%"
                gw.label = p[1] === "Charging" ? "Charging" : "Battery"; gw.sym = p[1] === "Charging" ? "\udb80\udc84" : "\udb80\udc79"
            }
        }
    }

    // the shape, turning very slowly
    Blob {
        id: blob
        anchors.fill: parent
        kind: gw.shape
        color: gw.pal ? (gw.bg > 0.02 ? gw.pal.cardColor : "transparent") : "#2b2d31"
        line: gw.pal ? gw.pal.edge : "transparent"
        lineWidth: gw.pal && gw.pal.edgeWidth > 0 ? gw.pal.edgeWidth : 0
        RotationAnimator on rotation { from: 0; to: 360; duration: 120000; loops: Animation.Infinite; running: gw.running && !Look.lite && gw.shape !== "circle" }
    }
    // the ring
    Canvas {
        id: ring
        anchors.centerIn: parent
        width: parent.width * 0.7; height: width
        property real v: gw.val
        property real ph: 0
        Behavior on v { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        NumberAnimation on ph { from: 0; to: Math.PI * 2; duration: 2400; loops: Animation.Infinite; running: gw.running && !Look.lite }
        onVChanged: requestPaint()
        onPhChanged: requestPaint()
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const cx = width / 2, cy = height / 2, r = width / 2 - 8
            const t = Math.max(4, width * 0.045)
            const len = Math.PI * 2 * Math.max(0.005, Math.min(1, v / 100))
            const start = -Math.PI / 2
            c.lineCap = "round"; c.lineWidth = t
            c.strokeStyle = gw.pal ? gw.pal.track : Qt.rgba(1, 1, 1, 0.13)
            if (v < 99) { c.beginPath(); c.arc(cx, cy, r, start + len + 0.32, start + Math.PI * 2 - 0.32); c.stroke() }
            c.strokeStyle = gw.fill
            c.beginPath()
            const n = Math.max(10, Math.round(len * r / 2.5)), amp = 2.2 * Math.sin(Math.PI * Math.min(1, v / 100))
            for (let i = 0; i <= n; i++) {
                const a = start + len * i / n
                const rr = r + amp * Math.sin(a * 10 - ph)
                const x = cx + rr * Math.cos(a), y = cy + rr * Math.sin(a)
                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.stroke()
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 0
        T { kind: "icon"; anchors.horizontalCenter: parent.horizontalCenter; text: gw.sym; font.pixelSize: Math.round(gw.width * 0.08); color: gw.pal ? gw.pal.fg3 : "#8a8a8f" }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            T { kind: "number"; text: gw.big; font.pixelSize: Math.round(gw.width * 0.22); font.weight: Font.DemiBold; color: gw.ink }
            T { kind: "number"; text: gw.unit; font.pixelSize: Math.round(gw.width * 0.09); color: gw.pal ? gw.pal.fg2 : "#c8c8cc"; anchors.baseline: parent.children[0].baseline }
        }
        T { anchors.horizontalCenter: parent.horizontalCenter; text: gw.label; font.pixelSize: Math.round(gw.width * 0.065); font.weight: Font.Medium; color: gw.pal ? gw.pal.fg2 : "#c8c8cc" }
    }
}
