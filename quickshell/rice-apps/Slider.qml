import QtQuick

// A Material 3 (expressive) slider: an active track, a gap, the handle as a tall bar, the rest of the track.
// `value` 0..1; `moved(v)` while dragging, `released(v)` when let go. `wavy` makes the active part a wave (Player).
Item {
    id: s
    property real value: 0
    property bool wavy: false
    property bool playing: false
    property real trackH: 16
    property color active: Theme.primary
    property color rest: Theme.secondaryContainer
    readonly property bool dragging: ma.pressed
    property real shown: ma.pressed ? dragV : value
    property real dragV: 0
    signal moved(real v)
    signal released(real v)
    implicitHeight: 40
    implicitWidth: 200
    readonly property real hx: 4 + shown * (width - 8)
    readonly property real gap: 6
    // the active part
    Rectangle {
        visible: !s.wavy
        x: 0; width: Math.max(0, s.hx - s.gap); height: s.trackH
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(height / 2, 8)
        color: s.active
    }
    Canvas {
        id: wave
        visible: s.wavy
        x: 0; width: Math.max(0, s.hx - s.gap); height: s.height
        property real ph: 0
        property real amp: s.playing ? 3 : 0
        Behavior on amp { NumberAnimation { duration: 400 } }
        onAmpChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPhChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            c.strokeStyle = s.active; c.lineWidth = 4; c.lineCap = "round"
            c.beginPath()
            const mid = height / 2
            for (let x = 2; x <= width - 2; x += 2) {
                const y = mid + Math.sin(x / 7 + ph) * amp
                if (x === 2) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.stroke()
        }
        Timer { interval: 40; repeat: true; running: s.wavy && s.playing && s.visible; onTriggered: wave.ph = (Date.now() % 1800) / 1800 * Math.PI * 2 }
    }
    // the rest
    Rectangle {
        x: s.hx + s.gap; width: Math.max(0, s.width - x); height: s.wavy ? 4 : s.trackH
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(height / 2, 8)
        color: s.rest
    }
    // the handle
    Rectangle {
        x: s.hx - width / 2
        width: ma.pressed ? 2 : 4
        height: s.wavy ? 22 : s.trackH + 18
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: s.active
        Behavior on width { NumberAnimation { duration: 120 } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.topMargin: -6; anchors.bottomMargin: -6
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function at(m) { return Math.max(0, Math.min(1, (m.x - 4) / Math.max(1, s.width - 8))) }
        onPressed: function(m) { s.dragV = at(m); s.moved(s.dragV) }
        onPositionChanged: function(m) { if (pressed) { s.dragV = at(m); s.moved(s.dragV) } }
        onReleased: function(m) { s.dragV = at(m); s.released(s.dragV) }
        onWheel: function(w) { const v = Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))); s.moved(v); s.released(v) }
    }
}
