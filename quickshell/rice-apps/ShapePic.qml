import QtQuick
import QtQuick.Effects

// A picture (an album cover ...) cut to one of our shapes.
Item {
    id: sp
    property string source: ""
    property string kind: "cookie"
    property int res: 320
    property color fill: Theme.surfaceHigh
    readonly property bool ready: img.status === Image.Ready
    Image {
        id: img
        anchors.fill: parent
        source: sp.source
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        sourceSize.width: sp.res
        sourceSize.height: sp.res
    }
    Shape { id: msk; anchors.fill: parent; kind: sp.kind; color: "white"; visible: false; layer.enabled: true; layer.smooth: true }
    Shape { anchors.fill: parent; kind: sp.kind; color: sp.fill; visible: !sp.ready }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: msk
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        visible: sp.ready
    }
}
