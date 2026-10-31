import QtQuick

// A card on the dashboard. Fades and rises in, one after another (order), when its tab shows.
Rectangle {
    id: c
    property var p
    property int order: 0
    property bool live: false
    property bool strong: false
    property real k: 0
    radius: p ? p.cardRadius : 18
    color: p ? (strong ? p.card2 : p.card) : "#1a1a1a"
    border.width: p && p.line ? 1 : 0
    border.color: p ? p.line : "transparent"
    opacity: k
    transform: Translate { y: (1 - c.k) * 14 }
    SequentialAnimation {
        id: inA
        PauseAnimation { duration: 40 + c.order * 45 }
        NumberAnimation { target: c; property: "k"; to: 1; duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
    }
    onLiveChanged: { if (live) { k = 0; inA.restart() } else { inA.stop(); k = 0 } }
    Component.onCompleted: if (live) inA.restart()
}
