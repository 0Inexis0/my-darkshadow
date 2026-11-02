import Quickshell
import Quickshell.Wayland
import QtQuick

// Full-screen transparent surface; only the widget rectangle receives input (mask).
// Outside the editor the widget only takes clicks (calendar arrows, timer, notes...). The editor moves it.
// The widget editor (EditorWindow.qml) changes px/py/sc/fw/fh/op/bgv/sty/flp live and saves on release.
PanelWindow {
    id: w
    property string wid: ""
    property var wc: ({})
    property int defX: 100
    property int defY: 100
    property int cw: 300          // natural size of the content
    property int ch: 200
    property bool free: false     // free width and height (visualizer) instead of scaling
    property int defW: 600
    property int defH: 160
    property int bw: 1920
    property int bh: 1080
    property bool active: true
    property bool draggable: true    // kept for old configs; moving is done in the widget editor
    property bool passive: false  // never takes clicks (visualizer)
    property bool editing: false
    // auto-hide (Settings > Desktop): fades out while windows are open, then the surface goes away
    property bool hidden: false
    property real fk: hidden ? 0 : 1
    Behavior on fk { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // current look; the editor changes these while you drag
    property real px: defX
    property real py: defY
    property real sc: 1
    property real fw: defW
    property real fh: defH
    property real op: 1
    property real bgv: 1
    property string sty: ""
    property bool flp: false
    property bool dragging: false
    property string vcolor: ""    // visualizer color (accent, gradient, rainbow, mono)
    property bool keys: false     // takes the keyboard when you click it (To-do, Notes)
    // brightness of the wallpaper behind this widget, and the colors that follow from it
    readonly property real lum: Look.lumAt(px, py, dispW, dispH, bw, bh)
    readonly property var pal: WPal { wall: w.lum; k: w.bgv }
    readonly property real dispW: free ? fw : cw * sc
    readonly property real dispH: free ? fh : ch * sc

    signal moved(string id, int x, int y)
    default property alias content: inner.data

    function adopt() {
        if (dragging) return
        px = wc.x !== undefined ? wc.x : defX
        py = wc.y !== undefined ? wc.y : defY
        sc = wc.scale !== undefined ? wc.scale : 1
        fw = wc.w !== undefined ? wc.w : defW
        fh = wc.h !== undefined ? wc.h : defH
        op = wc.opacity !== undefined ? wc.opacity : 1
        bgv = wc.bg !== undefined ? wc.bg : 1
        sty = wc.style !== undefined ? wc.style : ""
        flp = wc.flip === true
        vcolor = wc.color !== undefined ? wc.color : ""
    }
    onWcChanged: adopt()
    onDefXChanged: adopt()
    onDefYChanged: adopt()
    onDefWChanged: adopt()
    onDefHChanged: adopt()
    Component.onCompleted: adopt()

    visible: active && fk > 0.01
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    // above windows while you edit, so you can see what you change
    WlrLayershell.layer: editing ? WlrLayer.Top : WlrLayer.Bottom
    WlrLayershell.namespace: "rice-widget"
    // To-do and Notes: a click gives them the keyboard (typing), nothing takes it otherwise
    WlrLayershell.keyboardFocus: (keys && !editing) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // only the widget itself takes clicks; the visualizer (passive) and widgets in the editor take none,
    // so whatever is under them (other widgets, the desktop) stays clickable
    mask: Region { item: (w.passive || w.editing) ? nothing : holder }
    Item { id: nothing; width: 0; height: 0 }

    Item {
        id: holder
        x: w.px
        y: w.py
        width: w.dispW
        height: w.dispH
        opacity: w.op * w.fk
        scale: 0.96 + 0.04 * w.fk
        Behavior on opacity { enabled: !w.hidden && w.fk > 0.99; NumberAnimation { duration: 120 } }

        Item {
            id: inner
            width: w.free ? holder.width : w.cw
            height: w.free ? holder.height : w.ch
            scale: w.free ? 1 : w.sc
            transformOrigin: Item.TopLeft
        }

        // widgets are clicked, not dragged: moving and resizing happen in the widget editor only
        SfxTap {}
    }
}
