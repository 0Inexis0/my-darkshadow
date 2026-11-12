import Quickshell
import Quickshell.Io
import QtQuick

// Desktop widget "System": a small pill with CPU, RAM, disk and swap. A click opens a card under it with each one
// in its own tile: how much is used, a bar, and the numbers (rice-stats). Another click (or the pill) folds it.
Item {
    id: sy
    property var pal: null
    property real bg: 1
    property bool running: true
    property var st: ({})
    property bool open: false
    // 0 folded .. 1 open (the widget's window grows with it: shell.qml reads wantH)
    property real ex: open ? 1 : 0
    Behavior on ex { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: sy.open ? Look.emph : Look.accel } }
    readonly property real pillH: 56
    readonly property real cardH: 208
    readonly property real wantH: pillH + (cardH + 10) * ex
    readonly property color fg: pal ? pal.fg : "#F6F5F4"
    readonly property color fg3: pal ? pal.fg3 : "#8a8a8f"
    readonly property color acc: pal ? pal.primary : "#9ec9bd"

    Process {
        command: [Quickshell.env("HOME") + "/.local/bin/rice-stats", "2"]
        running: sy.running
        stdout: SplitParser { onRead: function(l) { try { sy.st = JSON.parse(l) } catch (e) { } } }
    }
    function gb(v) { return v === undefined ? "?" : (v >= 100 ? Math.round(v) : Number(v).toFixed(1)) }
    readonly property var items: [
        { k: "cpu", n: "CPU", icon: "memory", g: 0xF035B, v: st.cpu || 0, d: st.temp ? st.temp + "°C" : "" },
        { k: "ram", n: "RAM", icon: "memory_alt", g: 0xF061A, v: st.ram || 0, d: gb(st.ramu) + " / " + gb(st.ramt) + " GB" },
        { k: "disk", n: Tr.t("Disk"), icon: "hard_drive", g: 0xF02CA, v: st.disk || 0, d: gb(st.disku) + " / " + gb(st.diskt) + " GB" },
        { k: "swap", n: "Swap", icon: "swap_horiz", g: 0xF04E1, v: st.swap || 0, d: st.swapt ? gb(st.swapu) + " / " + gb(st.swapt) + " GB" : Tr.t("Off") }
    ]

    // ---- the pill
    Item {
        id: pill
        width: parent.width; height: sy.pillH
        Card { anchors.fill: parent; k: sy.bg; pal: sy.pal; radius: height / 2; property real blurRadius: height / 2 }
        Row {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: sy.items
                delegate: Item {
                    width: (pill.width - 28 - 18) / 4; height: 40
                    Rectangle { anchors.fill: parent; radius: height / 2; color: sy.pal ? sy.pal.chipHover : Qt.rgba(1, 1, 1, 0.16); opacity: pm.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } } }
                    Row {
                        anchors.centerIn: parent; spacing: 5
                        // a small ring that fills with the use
                        Item {
                            width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                            Canvas {
                                id: ring
                                anchors.fill: parent
                                readonly property real v: modelData.v / 100
                                onVChanged: requestPaint()
                                readonly property color c: sy.acc
                                onCChanged: requestPaint()
                                onPaint: {
                                    const g = getContext("2d"); g.reset()
                                    g.lineWidth = 2.5; g.lineCap = "round"
                                    g.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.22); g.beginPath(); g.arc(12, 12, 10, 0, Math.PI * 2); g.stroke()
                                    if (v > 0.005) { g.strokeStyle = c; g.beginPath(); g.arc(12, 12, 10, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, v)); g.stroke() }
                                }
                            }
                            MIcon { anchors.centerIn: parent; size: 12; name: modelData.icon; glyph: String.fromCodePoint(modelData.g); color: sy.fg }
                        }
                        T { anchors.verticalCenter: parent.verticalCenter; kind: "number"; text: modelData.v + "%"; font.pixelSize: 13; font.weight: Font.DemiBold; color: sy.fg }
                    }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sy.open = !sy.open }
                }
            }
        }
    }

    // ---- the card with the details
    Item {
        id: more
        y: sy.pillH + 10
        width: parent.width; height: sy.cardH
        visible: sy.ex > 0.01
        opacity: Math.min(1, sy.ex * 1.6)
        transform: [Scale { origin.y: 0; origin.x: more.width / 2; yScale: 0.85 + 0.15 * sy.ex; xScale: 0.96 + 0.04 * sy.ex }, Translate { y: (1 - sy.ex) * -12 }]
        Card { anchors.fill: parent; k: sy.bg; pal: sy.pal }
        Grid {
            anchors.fill: parent; anchors.margins: 10
            columns: 2; spacing: 8
            Repeater {
                model: sy.items
                delegate: Rectangle {
                    width: (more.width - 20 - 8) / 2; height: (more.height - 20 - 8) / 2
                    radius: 20
                    color: sy.pal ? sy.pal.chip : Qt.rgba(1, 1, 1, 0.08)
                    MIcon { x: 14; y: 12; size: 18; name: modelData.icon; glyph: String.fromCodePoint(modelData.g); color: sy.acc }
                    T { anchors.right: parent.right; anchors.rightMargin: 14; y: 10; kind: "number"; text: modelData.v + "%"; font.pixelSize: 18; font.weight: Font.DemiBold; color: sy.fg }
                    Column {
                        x: 14; y: 40; width: parent.width - 28; spacing: 1
                        T { text: modelData.n; font.pixelSize: 13; font.weight: Font.DemiBold; color: sy.fg }
                        T { width: parent.width; elide: Text.ElideRight; text: modelData.d; font.pixelSize: 10; color: sy.fg3 }
                    }
                    // how much is used
                    Rectangle {
                        x: 14; width: parent.width - 28; height: 6; radius: 3
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                        color: Qt.rgba(sy.acc.r, sy.acc.g, sy.acc.b, 0.2)
                        Rectangle { width: Math.max(6, parent.width * Math.min(1, modelData.v / 100)); height: 6; radius: 3; color: modelData.v >= 90 ? (sy.pal ? sy.pal.warn : "#e06c75") : sy.acc
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
                    }
                }
            }
        }
        MouseArea { anchors.fill: parent; z: -1; onClicked: sy.open = false }
    }
}
