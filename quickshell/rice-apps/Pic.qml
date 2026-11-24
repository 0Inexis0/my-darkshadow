import QtQuick

// A picture with round corners that fills its box (cropped like PreserveAspectCrop), drawn by round.frag:
// cheap enough for a grid of hundreds of them. `fit: true` shows all of it instead (no cropping).
Item {
    id: p
    property string source: ""
    property real radius: 12
    property int res: 256
    property bool fit: false
    readonly property alias status: img.status
    readonly property real iw: img.implicitWidth
    readonly property real ih: img.implicitHeight
    Image {
        id: img
        visible: false
        source: p.source
        asynchronous: true
        cache: true
        smooth: true
        sourceSize.width: p.res
        sourceSize.height: p.res
    }
    ShaderEffect {
        visible: img.status === Image.Ready
        readonly property real ka: img.implicitWidth / Math.max(1, img.implicitHeight)
        readonly property real kb: p.width / Math.max(1, p.height)
        // fit: the box shrinks to the picture's shape; else the picture is cropped to the box
        width: p.fit ? (ka > kb ? p.width : p.height * ka) : p.width
        height: p.fit ? (ka > kb ? p.width / ka : p.height) : p.height
        anchors.centerIn: parent
        property variant source: img
        property size box: Qt.size(width, height)
        property real radius: Math.min(p.radius, width / 2, height / 2)
        property vector2d sc: p.fit ? Qt.vector2d(1, 1) : (ka > kb ? Qt.vector2d(kb / ka, 1) : Qt.vector2d(1, ka / kb))
        property vector2d off: Qt.vector2d((1 - sc.x) / 2, (1 - sc.y) / 2)
        fragmentShader: Qt.resolvedUrl("round.frag.qsb")
    }
}
