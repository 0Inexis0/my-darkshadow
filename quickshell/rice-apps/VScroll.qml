import QtQuick

// A thin scroll bar for a Flickable (`flick`): shows while it moves or the pointer is near, can be dragged.
Item {
    id: v
    property var flick: null
    width: 10
    readonly property real ratio: flick && flick.contentHeight > 0 ? Math.min(1, flick.height / flick.contentHeight) : 1
    visible: ratio < 0.999
    opacity: (flick && flick.moving) || ma.containsMouse || ma.pressed ? 1 : 0.0
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Rectangle {
        id: knob
        x: 3; width: ma.containsMouse || ma.pressed ? 6 : 4
        radius: width / 2
        height: Math.max(28, v.height * v.ratio)
        y: v.flick ? (v.height - height) * Math.max(0, Math.min(1, (v.flick.contentY - v.flick.originY) / Math.max(1, v.flick.contentHeight - v.flick.height))) : 0
        color: Theme.alpha(Theme.inkVar, 0.55)
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        property real grab: 0
        onPressed: function(m) { grab = m.y - knob.y; if (grab < 0 || grab > knob.height) grab = knob.height / 2; move(m.y) }
        onPositionChanged: function(m) { if (pressed) move(m.y) }
        function move(y) {
            const f = v.flick; if (!f) return
            const k = Math.max(0, Math.min(1, (y - grab) / Math.max(1, v.height - knob.height)))
            f.contentY = f.originY + k * Math.max(0, f.contentHeight - f.height)
        }
    }
}
