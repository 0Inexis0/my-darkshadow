import Quickshell
import Quickshell.Io
import QtQuick

// Desktop widget Weather, style "Pills" (V4.95): the weather as a stack of pills of different widths, the
// temperature in the big one in the theme color, then the sky, the wind and the air (rice-weather json, every half hour).
Item {
    id: wp
    property var pal: null
    property real bg: 1
    property bool running: true
    property var w: null
    readonly property color fg: pal ? pal.fg : "#F6F5F4"
    readonly property color fg3: pal ? pal.fg3 : "#8a8a8f"
    readonly property color acc: pal ? pal.primary : "#9ec9bd"
    readonly property color pill: pal ? (bg > 0.02 ? pal.shapeFill : pal.chip) : "#22262a"
    readonly property bool night: { const h = new Date().getHours(); return h < 6 || h >= 19 }
    readonly property real u: width / 260

    Process {
        id: fetch
        command: [Quickshell.env("HOME") + "/.local/bin/rice-weather", "json"]
        stdout: StdioCollector { onStreamFinished: { try { const j = JSON.parse(text.trim().split("\n").pop()); if (j && j.temp !== undefined) wp.w = j } catch (e) { } } }
    }
    Timer { interval: 1800000; running: wp.running; repeat: true; triggeredOnStart: true; onTriggered: if (!fetch.running) fetch.running = true }

    // a pill comes in from the left, one after another
    component Pill: Rectangle {
        id: pl
        property int n: 0
        property real grow: 0
        height: 52 * wp.u; radius: height / 2
        border.width: wp.pal ? wp.pal.edgeWidth : 0; border.color: wp.pal ? wp.pal.edge : "transparent"
        opacity: grow
        transform: Translate { x: (1 - pl.grow) * -24 }
        Component.onCompleted: inT.start()
        Timer { id: inT; interval: 70 * pl.n; onTriggered: pl.grow = 1 }
        Behavior on grow { NumberAnimation { duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.decel } }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8 * wp.u
        // now: the temperature
        Pill {
            n: 0
            width: wp.width; height: 92 * wp.u
            color: wp.acc
            Row {
                x: 24 * wp.u; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                T { kind: "number"; text: wp.w ? String(wp.w.temp) : "--"; font.pixelSize: 56 * wp.u; font.weight: Font.DemiBold
                    color: wp.pal ? wp.pal.inkOn : "#10201c" }
                T { kind: "number"; text: "°"; font.pixelSize: 30 * wp.u; y: 6 * wp.u; color: wp.pal ? wp.pal.inkOn : "#10201c" }
            }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 14 * wp.u; anchors.verticalCenter: parent.verticalCenter
                width: 64 * wp.u; height: width; radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.22)
                WxIcon { anchors.centerIn: parent; size: 34 * wp.u; cond: wp.w ? wp.w.cond : ""; night: wp.night; color: wp.pal ? wp.pal.inkOn : "#10201c" }
            }
        }
        // the sky, and where
        Pill {
            n: 1
            width: wp.width * 0.86
            color: wp.pill
            T { x: 22 * wp.u; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 40 * wp.u; elide: Text.ElideRight
                text: wp.w ? wp.w.cond + (wp.w.place ? " · " + wp.w.place : "") : Tr.t("Looking outside...")
                font.pixelSize: 15 * wp.u; font.weight: Font.DemiBold; color: wp.fg }
        }
        Row {
            spacing: 8 * wp.u
            // wind
            Pill {
                n: 2
                width: (wp.width * 0.92 - 8 * wp.u) / 2
                color: wp.pill
                Row {
                    anchors.centerIn: parent; spacing: 6 * wp.u
                    MIcon { anchors.verticalCenter: parent.verticalCenter; size: 17 * wp.u; name: "air"; glyph: String.fromCodePoint(0xF059D); color: wp.acc }
                    T { anchors.verticalCenter: parent.verticalCenter; kind: "number"; font.pixelSize: 14 * wp.u; font.weight: Font.DemiBold; color: wp.fg
                        text: wp.w ? wp.w.wind + (wp.w.unit === "F" ? " mph" : " km/h") : "--" }
                }
            }
            // the air
            Pill {
                n: 3
                width: (wp.width * 0.92 - 8 * wp.u) / 2
                color: wp.pill
                Row {
                    anchors.centerIn: parent; spacing: 6 * wp.u
                    MIcon { anchors.verticalCenter: parent.verticalCenter; size: 17 * wp.u; name: "humidity_percentage"; glyph: String.fromCodePoint(0xF058E); color: wp.acc }
                    T { anchors.verticalCenter: parent.verticalCenter; kind: "number"; font.pixelSize: 14 * wp.u; font.weight: Font.DemiBold; color: wp.fg
                        text: wp.w ? wp.w.hum + "%" : "--" }
                }
            }
        }
        // the day
        Pill {
            n: 4
            width: wp.width * 0.7
            color: wp.pill
            T { anchors.centerIn: parent; kind: "number"; font.pixelSize: 14 * wp.u; font.weight: Font.DemiBold; color: wp.fg3
                text: wp.w ? "↑ " + wp.w.hi + "°   ↓ " + wp.w.lo + "°   " + Tr.t("Feels") + " " + wp.w.feels + "°" : "" }
        }
    }
}
