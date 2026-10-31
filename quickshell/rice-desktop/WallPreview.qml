import Quickshell
import Quickshell.Wayland
import QtQuick

// Wallpaper preview: while you scroll through wallpapers in the dashboard, the desktop shows the one
// you are on. Leave (Esc) and your wallpaper comes back; set one and it stays.
// It lives on the background layer (just above the wallpaper itself), so the desktop widgets stay on top.
PanelWindow {
    id: wv
    property string path: ""
    readonly property string want: path === "" ? "" : "file://" + path
    visible: path !== "" || a.opacity > 0.01 || b.opacity > 0.01
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "rice-wallpreview"
    mask: Region { item: none }
    Item { id: none; width: 0; height: 0 }

    // two pictures that cross-fade. Whatever happens (fast scrolling, pictures that load out of order,
    // going back to one that is already loaded), the one on screen is always the one you are on.
    function showPic(p) {
        const o = p === a ? b : a
        p.z = 1; o.z = 0
        p.opacity = 1
        o.opacity = 0
    }
    onWantChanged: {
        if (want === "") { a.opacity = 0; b.opacity = 0; return }
        if (String(a.source) === want && a.status === Image.Ready) { showPic(a); return }
        if (String(b.source) === want && b.status === Image.Ready) { showPic(b); return }
        // load into the picture that is not on screen right now
        const free = a.opacity >= b.opacity ? b : a
        free.source = want
        if (free.status === Image.Ready && String(free.source) === want) showPic(free)
    }
    component Pic: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: wv.width
        sourceSize.height: wv.height
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        // only the picture you are on may come up
        onStatusChanged: if (status === Image.Ready && wv.want !== "" && String(source) === wv.want) wv.showPic(this)
    }
    Pic { id: a }
    Pic { id: b }
}
