import QtQuick

// One settings page. The new page rises in (or drops in, going up the list) while the old one fades away.
Item {
    id: slot
    property int idx: 0
    property int cur: 0
    readonly property bool on: idx === cur
    default property alias content: inner.data

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    y: on ? 0 : (idx < cur ? -36 : 36)
    scale: on ? 1 : 0.985
    opacity: on ? 1 : 0
    visible: opacity > 0.01
    enabled: on
    z: on ? 1 : 0
    Behavior on y { NumberAnimation { duration: slot.on ? 460 : 220; easing.type: Easing.BezierSpline
        easing.bezierCurve: slot.on ? [0.05, 0.7, 0.1, 1, 1, 1] : [0.3, 0, 0.8, 0.15, 1, 1] } }
    Behavior on scale { NumberAnimation { duration: slot.on ? 460 : 220; easing.type: Easing.OutCubic } }
    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: slot.on ? 60 : 0 }
            NumberAnimation { duration: slot.on ? 300 : 150; easing.type: Easing.OutCubic }
        }
    }

    Item { id: inner; anchors.fill: parent }
}
