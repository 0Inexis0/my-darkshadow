import QtQuick

// Desktop widget "Date": today's day in a soft shape (flower, cookie, clover ...), with the weekday and month.
Item {
    id: dw
    property var pal: null
    property real bg: 1
    property bool running: true
    property string shape: "flower"
    property var now: new Date()
    Timer { interval: 60000; running: dw.running; repeat: true; onTriggered: dw.now = new Date() }
    Blob {
        anchors.fill: parent
        kind: dw.shape
        color: dw.pal ? (dw.bg > 0.02 ? dw.pal.primary : "transparent") : "#c8d8ff"
        RotationAnimator on rotation { from: 0; to: -360; duration: 160000; loops: Animation.Infinite; running: dw.running && !Look.lite && dw.shape !== "circle" && dw.shape !== "square" }
    }
    Column {
        anchors.centerIn: parent
        spacing: -4
        readonly property color ink: dw.pal ? (dw.bg > 0.02 ? dw.pal.inkOn : dw.pal.fg) : "#111"
        T { anchors.horizontalCenter: parent.horizontalCenter; text: dw.now.toLocaleDateString(Qt.locale("en_US"), "ddd").toUpperCase()
            font.pixelSize: Math.round(dw.width * 0.085); font.weight: Font.Bold; font.letterSpacing: 2; color: parent.ink; opacity: 0.8 }
        T { kind: "number"; anchors.horizontalCenter: parent.horizontalCenter; text: dw.now.getDate()
            font.pixelSize: Math.round(dw.width * 0.36); font.weight: Font.DemiBold; color: parent.ink }
        T { anchors.horizontalCenter: parent.horizontalCenter; text: dw.now.toLocaleDateString(Qt.locale("en_US"), "MMMM")
            font.pixelSize: Math.round(dw.width * 0.08); font.weight: Font.Medium; color: parent.ink; opacity: 0.8 }
    }
}
