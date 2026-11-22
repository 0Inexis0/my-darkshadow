import QtQuick

// V4.98 Minimal mode (Look.sq): a plain frame round a panel, a menu, the bar, the dock or a widget, like the window
// frames of a classic floating window manager: "double" is a dark line with the theme color inside it, "single" the
// color only, "thin" one quiet line. Put it inside the card: Frame { }
Item {
    anchors.fill: parent
    visible: Look.sq && Look.frameIn > 0
    z: 1000
    Rectangle {
        anchors.fill: parent
        visible: Look.frameOut > 0
        color: "transparent"
        border.width: Look.frameOut
        border.color: "#0b0b0b"
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: Look.frameOut
        color: "transparent"
        border.width: Look.frameIn
        border.color: Look.frameColor
    }
}
