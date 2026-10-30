import QtQuick

Item {
    id: sl
    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 0.01
    property real dragValue: 0
    property bool dragging: false
    readonly property real shown: dragging ? dragValue : (isFinite(value) ? value : from)
    signal released(real v)
    width: 200
    height: 24
    readonly property real pos: to > from ? Math.max(0, Math.min(1, (shown - from) / (to - from))) : 0

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: "#2a2a2a"
        Rectangle {
            width: parent.width * sl.pos
            height: parent.height
            radius: 2
            color: "#F6F5F4"
            Behavior on width { enabled: !sl.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }
    Rectangle {
        width: 16
        height: 16
        radius: 8
        color: "#F6F5F4"
        anchors.verticalCenter: parent.verticalCenter
        x: (sl.width - width) * sl.pos
        Behavior on x { enabled: !sl.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            const p = Math.max(0, Math.min(1, mx / sl.width))
            const raw = sl.from + p * (sl.to - sl.from)
            sl.dragValue = Math.round(raw / sl.step) * sl.step
        }
        onPressed: function(mouse) { sl.dragging = true; update(mouse.x) }
        onPositionChanged: function(mouse) { if (sl.dragging) update(mouse.x) }
        onReleased: { sl.dragging = false; sl.released(sl.dragValue) }
    }
}