import Quickshell
import Quickshell.Io
import QtQuick

// Desktop widget "Storage": used and free space of your home disk, with a ring around the disk icon.
Item {
    id: sw
    property var pal: null
    property real bg: 1
    property bool running: true
    property real used: 0
    property real free: 0
    readonly property real frac: used + free > 0 ? used / (used + free) : 0
    function gb(k) { const g = k / 1048576; return g >= 1000 ? (g / 1024).toFixed(1) + " TB" : Math.round(g) + " GB" }
    Process {
        id: df
        command: ["bash", "-c", "df -k --output=used,avail \"$HOME\" 2>/dev/null | tail -1"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim().split(/\s+/); sw.used = parseFloat(p[0]) || 0; sw.free = parseFloat(p[1]) || 0 } }
    }
    Timer { interval: 60000; running: sw.running; repeat: true; triggeredOnStart: true; onTriggered: df.running = true }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.pal ? (sw.bg > 0.02 ? sw.pal.shapeFill : "transparent") : "#22262a"
        border.width: sw.pal ? sw.pal.edgeWidth : 0; border.color: sw.pal ? sw.pal.edge : "transparent"
    }
    Column {
        x: 28; anchors.verticalCenter: parent.verticalCenter
        T { text: "Used"; font.pixelSize: 11; color: sw.pal ? sw.pal.fg3 : "#8a8a8f" }
        T { kind: "number"; text: sw.gb(sw.used); font.pixelSize: 18; font.weight: Font.DemiBold; color: sw.pal ? sw.pal.fg : "#F6F5F4" }
    }
    Column {
        anchors.right: parent.right; anchors.rightMargin: 28; anchors.verticalCenter: parent.verticalCenter
        T { anchors.right: parent.right; text: "Free"; font.pixelSize: 11; color: sw.pal ? sw.pal.fg3 : "#8a8a8f" }
        T { kind: "number"; anchors.right: parent.right; text: sw.gb(sw.free); font.pixelSize: 18; font.weight: Font.DemiBold; color: sw.pal ? sw.pal.fg : "#F6F5F4" }
    }
    Item {
        anchors.centerIn: parent
        width: parent.height - 12; height: width
        Canvas {
            anchors.fill: parent
            property real f: sw.frac
            onFChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const r = width / 2 - 3
                c.lineWidth = 4; c.lineCap = "round"
                c.strokeStyle = sw.pal ? sw.pal.track : "rgba(255,255,255,0.14)"
                c.beginPath(); c.arc(width / 2, height / 2, r, 0, Math.PI * 2); c.stroke()
                c.strokeStyle = sw.pal ? sw.pal.primary : "#9ec9bd"
                c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.01, f)); c.stroke()
            }
        }
        Blob { anchors.centerIn: parent; width: parent.width - 16; height: width; kind: "cookie"; color: sw.pal ? sw.pal.chip : Qt.rgba(1, 1, 1, 0.08) }
        MIcon { anchors.centerIn: parent; size: parent.width * 0.32; name: "storage"; glyph: ""; color: sw.pal ? sw.pal.fg : "#F6F5F4" }
    }
}
