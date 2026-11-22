import QtQuick

// The big play button: round while paused, a softer square while playing (Material 3 expressive shapes).
Rectangle {
    id: b
    property bool playing: false
    property real size: 72
    signal clicked()
    width: size * 1.28
    height: size
    radius: ma.pressed ? size * 0.22 : (playing ? size * 0.3 : size / 2)
    color: Theme.primary
    Behavior on radius { NumberAnimation { duration: Theme.d(360); easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    Behavior on color { ColorAnimation { duration: 400 } }
    scale: ma.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    Layer { area: ma; ink: Theme.inkPrimary }
    Ic { anchors.centerIn: parent; name: b.playing ? "pause" : "play_arrow"; size: b.size * 0.52; color: Theme.inkPrimary }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
