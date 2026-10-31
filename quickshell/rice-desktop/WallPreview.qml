import Quickshell
import Quickshell.Wayland
import QtQuick

// Wallpaper preview: while you scroll through wallpapers in the dashboard, the desktop shows the one
// you are on. Leave (Esc) and your wallpaper comes back; set one and it stays.
PanelWindow {
    id: wv
    property string path: ""
    property string shown: ""
    property bool flip: false
    visible: path !== "" || a.opacity > 0.01 || b.opacity > 0.01
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "rice-wallpreview"
    mask: Region { item: none }
    Item { id: none; width: 0; height: 0 }

    // two pictures that cross-fade
    onPathChanged: {
        if (path === "") { a.opacity = 0; b.opacity = 0; shown = ""; return }
        if (path === shown) return
        shown = path
        flip = !flip
        const next = flip ? a : b
        next.source = "file://" + path
    }
    component Pic: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: wv.width
        sourceSize.height: wv.height
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    }
    Pic { id: a; onStatusChanged: if (status === Image.Ready && wv.flip && wv.path !== "") { a.opacity = 1; b.opacity = 0 } }
    Pic { id: b; onStatusChanged: if (status === Image.Ready && !wv.flip && wv.path !== "") { b.opacity = 1; a.opacity = 0 } }
}
