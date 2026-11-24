import QtQuick
import QtQuick.Effects

// A picture cut to one of our shapes (a cookie, a flower ... Appearance > Shapes); without a picture, the shape
// in the key color with a letter on it.
Item {
    id: si
    property string source: ""
    property string kind: Prefs.accentShape || "cookie"
    property string letter: ""
    property int res: 256
    property color fill: M3.primaryContainer
    property color ink: M3.inkPrimaryC
    readonly property bool ready: img.status === Image.Ready

    Image {
        id: img
        anchors.fill: parent
        source: si.source.length > 0 ? (si.source.indexOf("/") === 0 ? "file://" + si.source : si.source) : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        cache: false
        sourceSize.width: si.res
        sourceSize.height: si.res
    }
    Blob {
        id: msk
        anchors.fill: parent
        kind: si.kind
        color: "white"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: msk
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        visible: si.ready
    }
    Blob {
        anchors.fill: parent
        kind: si.kind
        color: si.fill
        visible: !si.ready
        T {
            scaled: false
            anchors.centerIn: parent
            text: si.letter
            font.pixelSize: parent.width * 0.4
            font.weight: Font.DemiBold
            color: si.ink
        }
    }
}
