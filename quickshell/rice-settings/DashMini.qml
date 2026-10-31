import QtQuick

// A tiny drawing of the dashboard in one of its looks (Settings > Dashboard > Theme).
Item {
    id: m
    property string look: "shadow"
    property string acc: "#9ec9bd"
    function hx(c) { const s = String(c).replace("#", ""); return [parseInt(s.substr(0, 2), 16) / 255, parseInt(s.substr(2, 2), 16) / 255, parseInt(s.substr(4, 2), 16) / 255] }
    function mix(a, b, k, al) { const x = hx(a), y = hx(b); return Qt.rgba(x[0] * (1 - k) + y[0] * k, x[1] * (1 - k) + y[1] * k, x[2] * (1 - k) + y[2] * k, al === undefined ? 1 : al) }
    readonly property var p: look === "graphite" ? ({ bg: "#1c1c1f", card: "#28282c", pri: mix(acc, "#ffffff", 0.42), cont: mix(acc, "#2a2a2e", 0.74), txt: "#ECECEE", r: 0.1, tab: "underline" })
        : look === "aurora" ? ({ bg: mix(acc, "#06060a", 0.86), card: mix(acc, "#16161c", 0.78), pri: mix(acc, "#ffffff", 0.2), cont: mix(acc, "#16161c", 0.55), txt: "#EEEAF2", r: 0.13, tab: "pill" })
        : look === "frost" ? ({ bg: "#f4f4f6", card: "#e6e6ea", pri: "#18181b", cont: "#dcdce1", txt: "#18181b", r: 0.1, tab: "segment" })
        : ({ bg: "#0e0e10", card: Qt.rgba(1, 1, 1, 0.06), pri: "#F6F5F4", cont: Qt.rgba(1, 1, 1, 0.12), txt: "#F6F5F4", r: 0.09, tab: "segment" })
    readonly property real u: width / 100

    Rectangle {
        anchors.fill: parent
        radius: m.p.r * m.width
        color: m.p.bg
        border.width: 1
        border.color: Qt.rgba(0.5, 0.5, 0.5, 0.15)
    }
    // tabs
    Rectangle { visible: m.p.tab === "segment"; x: 4 * m.u; y: 3 * m.u; width: 92 * m.u; height: 9 * m.u; radius: height / 2; color: m.p.card }
    Rectangle {
        x: m.p.tab === "underline" ? 9 * m.u : 5 * m.u; y: m.p.tab === "underline" ? 11 * m.u : 3.6 * m.u
        width: m.p.tab === "underline" ? 12 * m.u : 22 * m.u; height: m.p.tab === "underline" ? 1 * m.u : 7.8 * m.u
        radius: height / 2
        color: m.p.tab === "pill" ? m.p.cont : m.p.pri
    }
    Repeater {
        model: 4
        Rectangle { x: (8 + index * 23) * m.u; y: 6.6 * m.u; width: 10 * m.u; height: 1.6 * m.u; radius: height / 2
            color: index === 0 && m.p.tab === "segment" ? (m.look === "frost" ? "#ffffff" : "#0d0d0d") : m.p.txt; opacity: index === 0 ? 0.9 : 0.35 }
    }
    // cards
    component C: Rectangle { radius: m.p.r * m.width * 0.6; color: m.p.card }
    C { x: 4 * m.u; y: 15 * m.u; width: 24 * m.u; height: 12 * m.u
        Rectangle { x: 3 * m.u; y: 3 * m.u; width: 6 * m.u; height: 6 * m.u; radius: width / 2; color: m.p.cont } }
    C { x: 30 * m.u; y: 15 * m.u; width: 40 * m.u; height: 12 * m.u
        Rectangle { x: 3 * m.u; y: 2 * m.u; width: 8 * m.u; height: 8 * m.u; radius: width / 2; color: m.p.cont }
        Rectangle { x: 14 * m.u; y: 4 * m.u; width: 18 * m.u; height: 1.8 * m.u; radius: height / 2; color: m.p.txt; opacity: 0.7 } }
    C { x: 72 * m.u; y: 15 * m.u; width: 24 * m.u; height: 36 * m.u
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 3 * m.u; width: 14 * m.u; height: 14 * m.u; radius: 3 * m.u; color: m.p.cont }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 28 * m.u; width: 9 * m.u; height: 4 * m.u; radius: height / 2; color: m.p.pri } }
    C { x: 4 * m.u; y: 29 * m.u; width: 10 * m.u; height: 22 * m.u
        Rectangle { anchors.centerIn: parent; width: 4 * m.u; height: 10 * m.u; radius: 1 * m.u; color: m.p.pri; opacity: 0.8 } }
    C { x: 16 * m.u; y: 29 * m.u; width: 44 * m.u; height: 22 * m.u
        Grid { x: 3 * m.u; y: 4 * m.u; columns: 7; spacing: 2.4 * m.u
            Repeater { model: 21; Rectangle { width: 3.4 * m.u; height: 3.4 * m.u; radius: width / 2; color: index === 12 ? m.p.pri : m.p.txt; opacity: index === 12 ? 1 : 0.25 } } } }
    C { x: 62 * m.u; y: 29 * m.u; width: 8 * m.u; height: 22 * m.u
        Column { anchors.centerIn: parent; spacing: 1.2 * m.u
            Repeater { model: 3; Rectangle { width: 5 * m.u; height: 5 * m.u; radius: width / 2; color: "transparent"; border.width: 0.9 * m.u; border.color: m.p.pri } } } }
}
