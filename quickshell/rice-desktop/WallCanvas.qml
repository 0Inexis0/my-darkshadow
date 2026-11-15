import Quickshell
import Quickshell.Wayland
import QtQuick

// Infinite Desktop: the wallpaper moves with the canvas, slower than the windows (parallax), so moving around feels
// like travelling over a big picture. It is the same picture as the wallpaper, drawn over it while Infinite Desktop
// is on: it starts exactly where the wallpaper is, grows a little (room to move) and goes back the same way when
// you turn it off, so there is no jump. At the edge of that room it slows down instead of stopping hard.
// (Settings > Desktop > Infinite Desktop > The wallpaper moves with it)
PanelWindow {
    id: wc
    screen: Mon.screen
    property string path: ""
    readonly property bool picture: /\.(png|jpe?g|webp|bmp|avif|jxl)$/i.test(path)
    readonly property bool want: Infinite.here && Infinite.wallOn && picture && !Look.lite
    // 0: the plain wallpaper, 1: the canvas wallpaper (bigger, moving)
    property real k: want ? 1 : 0
    Behavior on k { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }

    // the surface stays (see-through) while the feature is on, and only the picture in it comes and goes. Mapping and
    // unmapping the surface every time (and on the picture's loading state, which changed with it: a binding loop)
    // crashed Qt's Wayland client (QWaylandWindow::calculateExposure, seen on Artix with NVIDIA)
    visible: picture && Wm.hypr && Infinite.wallOn && !Look.lite
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "rice-wallcanvas"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { }

    // how much bigger than the screen (room to move), a little less when you zoom out
    readonly property real grow: 1 + 0.42 * k * (0.75 + 0.25 * Math.max(0.2, Math.min(1, Infinite.zoom)))
    // how far the picture goes for one pixel the windows go
    readonly property real depth: 0.22
    // soft edge: free in the middle, slower and slower near the end of the room
    function soft(v, room) { return room <= 1 ? 0 : room * Math.tanh(v / room) }
    readonly property real roomX: (grow - 1) * width / 2
    readonly property real roomY: (grow - 1) * height / 2
    readonly property real tx: k * soft(Infinite.ox * depth, roomX)
    readonly property real ty: k * soft(Infinite.oy * depth, roomY)
    // live (SUPER + ALT + mouse): it follows closely; a glide (keys, the next window) or a zoom: a slower glide
    property real px: tx
    property real py: ty
    Behavior on px { NumberAnimation { duration: Infinite.live ? 120 : 520; easing.type: Easing.OutCubic } }
    Behavior on py { NumberAnimation { duration: Infinite.live ? 120 : 520; easing.type: Easing.OutCubic } }

    Image {
        id: img
        width: wc.width * wc.grow
        height: wc.height * wc.grow
        x: Math.round((wc.width - width) / 2 + wc.px)
        y: Math.round((wc.height - height) / 2 + wc.py)
        visible: wc.k > 0.001 && status === Image.Ready
        source: wc.path !== "" && wc.picture ? "file://" + wc.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        // decoded once, big enough for the largest size it is drawn at
        sourceSize.width: Math.round(wc.width * 1.45)
    }
}
