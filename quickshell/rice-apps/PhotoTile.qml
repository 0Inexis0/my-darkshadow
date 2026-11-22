import QtQuick

// Photos: one picture of the timeline. A click opens it; the circle in its corner (or Ctrl + click, or a long press)
// chooses it, and then clicks choose more. Drag it into another app to give it the file.
Item {
    id: t
    property var ph
    property int i: 0
    property real size: 150
    readonly property var x_: ph.shown[i] || ({ path: "", video: false })
    readonly property bool chosen: ph.sel[x_.path] === true
    readonly property bool fav: ph.favs.indexOf(x_.path) >= 0
    width: size
    height: size
    onX_Changed: if (x_.video) ph.needThumb(x_.path)
    Component.onCompleted: if (x_.video) ph.needThumb(x_.path)

    Rectangle {
        id: box
        anchors.centerIn: parent
        width: t.chosen ? t.size * 0.84 : t.size
        height: width
        radius: t.chosen ? Theme.rL : Theme.rXS
        color: Theme.surfaceHigh
        Behavior on width { NumberAnimation { duration: Theme.d(220); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        Behavior on radius { NumberAnimation { duration: Theme.d(220) } }
        Pic {
            id: pic
            anchors.fill: parent
            radius: parent.radius
            res: Math.ceil(t.size * 1.5)
            source: Theme.url(t.x_.video ? (t.ph.thumbs[t.x_.path] || "") : t.x_.path)
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: "#000000"; opacity: ma.containsMouse && !t.chosen ? 0.12 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } } }
        // the top of it darker while the pointer is on it, so the circle shows on light pictures
        Rectangle {
            width: parent.width; height: 44; radius: parent.radius
            opacity: (ma.containsMouse || t.ph.selecting) && !t.chosen ? 1 : 0
            gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.4) } GradientStop { position: 1; color: "transparent" } }
        }
        Rectangle {
            visible: t.x_.video
            anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
            width: 26; height: 26; radius: 13
            color: Qt.rgba(0, 0, 0, 0.5)
            Ic { anchors.centerIn: parent; name: "play_arrow"; size: 18; color: "white" }
        }
        Ic {
            visible: t.fav
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 6
            name: "favorite"; size: 18; color: "white"
            style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.3)
        }
    }
    // the circle: choose it
    Rectangle {
        x: 6; y: 6
        width: 24; height: 24; radius: 12
        visible: ma.containsMouse || t.ph.selecting
        color: t.chosen ? Theme.primary : "transparent"
        border.width: t.chosen ? 0 : 2
        border.color: "white"
        Ic { anchors.centerIn: parent; visible: t.chosen; name: "check"; size: 17; color: Theme.inkPrimary }
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: t.ph.toggle(t.x_.path) }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        pressAndHoldInterval: 450
        drag.target: ghost
        drag.threshold: 10
        property bool held: false
        onPressed: { held = false; pic.grabToImage(function(r) { ghost.Drag.imageSource = r.url }, Qt.size(72, 72)) }
        onPressAndHold: function(m) { if (m.button === Qt.LeftButton && !drag.active) { held = true; t.ph.toggle(t.x_.path) } }
        onClicked: function(m) {
            if (held) return
            if (m.button === Qt.RightButton) { t.ph.tileMenu(t.x_, ma, m.x, m.y); return }
            if (t.ph.selecting || (m.modifiers & Qt.ControlModifier)) t.ph.toggle(t.x_.path)
            else t.ph.openItem(t.i)
        }
    }
    Item {
        id: ghost
        width: 72; height: 72
        Drag.active: ma.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.proposedAction: Qt.CopyAction
        Drag.hotSpot: Qt.point(36, 36)
        Drag.mimeData: ma.drag.active ? { "text/uri-list": t.ph.uris(t.x_) } : ({})
        Drag.onDragFinished: function(a) { ghost.x = 0; ghost.y = 0 }
    }
}
