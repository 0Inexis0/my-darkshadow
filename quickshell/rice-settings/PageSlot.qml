import QtQuick

// One settings page. Material "fade through": the old page fades away quickly,
// then the new one fades in while it grows slightly and rises into place.
Item {
    id: slot
    property int idx: 0
    property int cur: 0
    readonly property bool on: idx === cur
    default property alias content: inner.data

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    visible: inner.opacity > 0.01
    enabled: on
    z: on ? 1 : 0

    Item {
        id: inner
        width: parent.width
        height: parent.height
        opacity: slot.on ? 1 : 0
        scale: slot.on ? 1 : (slot.idx < slot.cur ? 0.97 : 0.95)
        y: slot.on ? 0 : 18
        transformOrigin: Item.Top
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: slot.on ? 90 : 0 }
                NumberAnimation { duration: slot.on ? 260 : 90; easing.type: slot.on ? Easing.OutCubic : Easing.InCubic }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: slot.on ? 90 : 0 }
                NumberAnimation { duration: slot.on ? 420 : 90; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
            }
        }
        Behavior on y {
            SequentialAnimation {
                PauseAnimation { duration: slot.on ? 90 : 0 }
                NumberAnimation { duration: slot.on ? 420 : 90; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
            }
        }
    }
}
