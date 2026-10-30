import Quickshell
import Quickshell.Wayland
import QtQuick

// Full-screen transparent surface; only the widget rectangle receives input (mask).
// Dragging moves an item inside the surface, so nothing is resized or re-configured
// by the compositor while you drag (no shaking).
PanelWindow {
    id: w
    property string wid: ""
    property var wc: ({})
    property int defX: 100
    property int defY: 100
    property int cw: 300
    property int ch: 200
    property int bw: 1920
    property int bh: 1080
    property bool active: true
    property bool draggable: true
    property real px: defX
    property real py: defY
    property bool dragging: false
    signal moved(string id, int x, int y)
    default property alias content: holder.data

    function adopt() {
        if (dragging) return
        px = wc.x !== undefined ? wc.x : defX
        py = wc.y !== undefined ? wc.y : defY
    }
    onWcChanged: adopt()
    onDefXChanged: adopt()
    onDefYChanged: adopt()
    Component.onCompleted: adopt()

    visible: active
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "rice-widget"
    mask: Region { item: holder }

    Item {
        id: holder
        x: w.px
        y: w.py
        width: w.cw
        height: w.ch

        MouseArea {
            anchors.fill: parent
            enabled: w.draggable
            property real sx: 0
            property real sy: 0
            property real ox: 0
            property real oy: 0
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
            onPressed: function(m) {
                const g = mapToItem(null, m.x, m.y)
                sx = g.x; sy = g.y; ox = w.px; oy = w.py
                w.dragging = true
            }
            onPositionChanged: function(m) {
                if (!pressed) return
                const g = mapToItem(null, m.x, m.y)
                w.px = Math.max(0, Math.min(w.bw - w.cw, ox + g.x - sx))
                w.py = Math.max(0, Math.min(w.bh - w.ch, oy + g.y - sy))
            }
            onReleased: {
                w.dragging = false
                w.px = Math.round(w.px)
                w.py = Math.round(w.py)
                w.moved(w.wid, w.px, w.py)
            }
        }
    }
}
