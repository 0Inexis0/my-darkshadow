import Quickshell
import QtQuick

// Desktop widget "Progress" (V4.95): how much of today, this week, this month and this year is gone, as thick
// pills that fill. Wakes once a minute.
Item {
    id: pg
    property var pal: null
    property real bg: 1
    property bool running: true
    property date now: new Date()
    readonly property real u: width / 300
    readonly property color fg: pal ? pal.fg : "#F6F5F4"
    readonly property color fg3: pal ? pal.fg3 : "#8a8a8f"
    Timer { interval: 60000; running: pg.running; repeat: true; triggeredOnStart: true; onTriggered: pg.now = new Date() }

    function parts(n) {
        const d0 = new Date(n.getFullYear(), n.getMonth(), n.getDate())
        const day = (n - d0) / 86400000
        const wd = (n.getDay() + 6) % 7          // Monday first
        const week = (wd + day) / 7
        const dim = new Date(n.getFullYear(), n.getMonth() + 1, 0).getDate()
        const month = (n.getDate() - 1 + day) / dim
        const y0 = new Date(n.getFullYear(), 0, 1), y1 = new Date(n.getFullYear() + 1, 0, 1)
        const year = (n - y0) / (y1 - y0)
        return [
            { n: Tr.t("Day"), v: day, s: Math.round((1 - day) * 24) + " h " + Tr.t("left") },
            { n: Tr.t("Week"), v: week, s: (7 - wd - 1) + " " + Tr.t("days left") },
            { n: Tr.t("Month"), v: month, s: (dim - n.getDate()) + " " + Tr.t("days left") },
            { n: String(n.getFullYear()), v: year, s: Math.round((y1 - n) / 86400000) + " " + Tr.t("days left") }
        ]
    }
    readonly property var rows: parts(now)

    Card { anchors.fill: parent; k: pg.bg; pal: pg.pal }

    Column {
        anchors.centerIn: parent
        width: parent.width - 36 * pg.u
        spacing: 10 * pg.u
        Repeater {
            model: pg.rows
            delegate: Item {
                width: parent.width; height: 36 * pg.u
                Rectangle {
                    id: tr
                    anchors.fill: parent
                    radius: height / 2
                    color: pg.pal ? pg.pal.track : Qt.rgba(1, 1, 1, 0.12)
                }
                Rectangle {
                    id: fill
                    height: parent.height; radius: height / 2
                    property real f: 0
                    width: Math.max(height, parent.width * f)
                    color: index === 3 ? (pg.pal ? pg.pal.tertiary : "#e8a28c") : (pg.pal ? pg.pal.primary : "#9ec9bd")
                    Component.onCompleted: f = Math.max(0, Math.min(1, modelData.v))
                    Behavior on f { NumberAnimation { duration: 900 + index * 120; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
                    Connections { target: pg; function onRowsChanged() { fill.f = Math.max(0, Math.min(1, pg.rows[index].v)) } }
                }
                T { x: 16 * pg.u; anchors.verticalCenter: parent.verticalCenter; text: modelData.n
                    font.pixelSize: 14 * pg.u; font.weight: Font.Bold
                    color: fill.width > implicitWidth + 24 * pg.u ? (index === 3 ? (pg.pal ? pg.pal.inkTertiary : "#3a1a12") : (pg.pal ? pg.pal.inkOn : "#10201c")) : pg.fg }
                T { anchors.right: parent.right; anchors.rightMargin: 16 * pg.u; anchors.verticalCenter: parent.verticalCenter
                    kind: "number"; text: Math.floor(modelData.v * 100) + "%"
                    font.pixelSize: 13 * pg.u; font.weight: Font.DemiBold
                    color: fill.width > parent.width - 50 * pg.u ? (index === 3 ? (pg.pal ? pg.pal.inkTertiary : "#3a1a12") : (pg.pal ? pg.pal.inkOn : "#10201c")) : pg.fg3 }
            }
        }
    }
}
