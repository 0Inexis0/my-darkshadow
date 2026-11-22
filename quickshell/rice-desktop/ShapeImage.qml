import QtQuick

// A picture (album art ...) cut into one of the soft shapes of Blob.qml: cookie, flower, circle ...
// Drawn on a canvas clipped by the shape, so it needs no graphics effects.
Item {
    id: si
    property string source: ""
    property string kind: "cookie"
    property color empty: "#2a2c30"
    property string fallbackIcon: "music_note"
    property string fallbackGlyph: ""
    property color fallbackColor: "#8a8a8f"
    property string loaded: ""
    // V4.96: the picture's shape from a tiny decode (createImageData made a full copy of the picture on every paint)
    property real ratio: 1
    Image {
        id: probe
        visible: false; asynchronous: true; cache: false
        sourceSize.width: 32
        source: si.source
        onStatusChanged: if (status === Image.Ready && implicitWidth > 0) { si.ratio = implicitHeight / implicitWidth; cv.requestPaint() }
    }
    Blob {
        id: shape
        anchors.fill: parent
        kind: si.kind
        color: si.empty
        visible: si.loaded === "" || si.loaded !== si.source
        MIcon { anchors.centerIn: parent; size: parent.width * 0.3; name: si.fallbackIcon; glyph: si.fallbackGlyph; color: si.fallbackColor }
    }
    Canvas {
        id: cv
        anchors.fill: parent
        visible: si.loaded !== "" && si.loaded === si.source
        renderStrategy: Canvas.Cooperative
        onImageLoaded: { if (isImageLoaded(si.source)) { si.loaded = si.source; requestPaint() } }
        onPaint: {
            const c = getContext("2d"); c.reset()
            if (si.source === "" || !isImageLoaded(si.source)) return
            shape.trace(c, width, height, 1)
            c.clip()
            // cover: fill the shape, keep the picture's proportions
            const iw = width, ih = width * si.ratio
            const k = Math.max(width / iw, height / ih)
            c.drawImage(si.source, (width - iw * k) / 2, (height - ih * k) / 2, iw * k, ih * k)
        }
        onWidthChanged: requestPaint()
    }
    // V4.96: the art of every song you played stayed loaded (a leak that grew all day); the last one is dropped now
    property string held: ""
    onSourceChanged: {
        if (held !== "" && held !== source) cv.unloadImage(held)
        held = source
        if (source === "") { loaded = ""; return }
        if (cv.isImageLoaded(source)) { loaded = source; cv.requestPaint() }
        else cv.loadImage(source)
    }
    onKindChanged: cv.requestPaint()
    Component.onCompleted: if (source !== "") { held = source; if (cv.isImageLoaded(source)) { loaded = source; cv.requestPaint() } else cv.loadImage(source) }
    Component.onDestruction: if (source !== "") cv.unloadImage(source)
}
