import QtQuick

// A slider for the dashboard: a thick rounded track and a round knob. value goes from 0 to 1.
Item {
    id: s
    property var p
    property real value: 0
    property bool dragging: false
    property real dv: 0
    readonly property real v: dragging ? dv : value
    signal moved(real v)
    implicitHeight: 28
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 10; radius: 5; color: s.p ? s.p.track : "#333" }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.max(10, parent.width * s.v); height: 10; radius: 5; color: s.p ? s.p.primary : "#ccc" }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, parent.width * s.v - width / 2))
        width: s.dragging ? 24 : 20; height: width; radius: width / 2
        color: s.p ? s.p.primary : "#ccc"
        border.width: 3; border.color: s.p ? s.p.solidBg : "#111"
        Behavior on width { NumberAnimation { duration: 90 } }
    }
    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        function at(mx) { return Math.max(0, Math.min(1, mx / width)) }
        onPressed: function(m) { s.dv = at(m.x); s.dragging = true; s.moved(s.dv) }
        onPositionChanged: function(m) { if (pressed) { s.dv = at(m.x); s.moved(s.dv) } }
        onReleased: s.dragging = false
        onCanceled: s.dragging = false
    }
}
