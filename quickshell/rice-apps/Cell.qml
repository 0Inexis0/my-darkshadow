import QtQuick

// Files: one file in the grid.
Item {
    id: c
    required property int index
    required property string fileName
    required property string filePath
    required property bool fileIsDir
    required property var fileSize
    required property var fileModified
    property var fv
    readonly property var fa: fv.fa
    width: GridView.view.cellWidth
    height: GridView.view.cellHeight
    readonly property bool selected: fa.sel[filePath] === true
    readonly property bool cut: fa.cutSet[filePath] === true
    readonly property string kind: Theme.kind(fileName, fileIsDir)
    readonly property bool dropOn: da.containsDrag && !(selected && da.drag.source)
    readonly property real tileW: width - 28
    function want() { if (kind === "video" || kind === "pdf") fv.needThumb(filePath) }
    // V4.93: it pops in when a folder opens (one after another, from the top left of what you see)
    property real pop: 1
    SequentialAnimation {
        id: popA
        PropertyAction { target: c; property: "pop"; value: 0 }
        PauseAnimation { duration: Math.min(14, Math.max(0, c.index - Math.floor(c.GridView.view.contentY / c.height) * Math.max(1, Math.floor(c.GridView.view.width / c.width)))) * Theme.d(18) }
        NumberAnimation { target: c; property: "pop"; to: 1; duration: Theme.d(380); easing.type: Easing.OutBack; easing.overshoot: 1.3 }
    }
    Connections { target: c.fv; function onNavTickChanged() { popA.restart() } }
    opacity: pop
    scale: 0.86 + 0.14 * pop
    // V4.93: the picture lifts a little under the pointer
    property real lift: ma.pressed ? 0.95 : (ma.containsMouse ? 1.04 : 1)
    Behavior on lift { NumberAnimation { duration: Theme.d(220); easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    onFilePathChanged: want()
    Component.onCompleted: want()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.sq ? 0 : (Theme.rL)
        color: c.selected ? Theme.secondaryContainer : (c.dropOn ? Theme.alpha(Theme.primary, 0.16) : "transparent")
        border.width: c.dropOn ? 2 : 0
        border.color: Theme.primary
        Behavior on color { ColorAnimation { duration: 120 } }
        Layer { area: ma; ink: c.selected ? Theme.inkSecondaryC : Theme.ink }
    }
    FileTile {
        id: tile
        x: (c.width - width) / 2
        y: 10
        transform: Scale { origin.x: tile.width / 2; origin.y: tile.height / 2; xScale: c.lift; yScale: c.lift }
        width: c.tileW
        height: Math.round(c.tileW * 0.86)
        path: c.filePath
        name: c.fileName
        isDir: c.fileIsDir
        thumb: c.fa.thumbs[c.filePath] || ""
        symbol: c.fileIsDir ? (c.fa.symbols[c.filePath] || "") : ""
        hover: ma.containsMouse || c.dropOn
        opacity: c.cut ? 0.45 : 1
        scale: ma.pressed && ma.pressedButtons & Qt.LeftButton ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    Ic {
        visible: c.fa.starred.indexOf(c.filePath) >= 0
        anchors.right: tile.right; anchors.top: tile.top; anchors.topMargin: -4
        name: "star"; size: 18; color: Theme.tertiary
    }
    T {
        anchors.top: tile.bottom; anchors.topMargin: 6
        x: 8; width: c.width - 16
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: 2
        elide: Text.ElideRight
        text: c.fileName
        role: "label"
        font.weight: 450
        lineHeight: 0.95
        color: c.selected ? Theme.inkSecondaryC : Theme.ink
        opacity: c.cut ? 0.6 : 1
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.margins: 4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: true
        drag.target: ghost
        drag.threshold: 8
        onPressed: function(m) { c.fv.press(c.index, m); if (m.button === Qt.LeftButton) tile.grabToImage(function(r) { ghost.Drag.imageSource = r.url }, Qt.size(64, 56)) }
        onReleased: function(m) { c.fv.release(c.index, m, drag.active) }
        onClicked: function(m) {
            if (m.button === Qt.RightButton) c.fv.menuAt(c.index, ma, m)
            else if (m.button === Qt.MiddleButton && c.fileIsDir) Sys.app("files", [c.filePath])
        }
        onDoubleClicked: function(m) { if (m.button === Qt.LeftButton) c.fa.openSel() }
    }
    Item {
        id: ghost
        width: 64; height: 56
        Drag.active: ma.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.hotSpot: Qt.point(32, 28)
        Drag.mimeData: ma.drag.active ? { "text/uri-list": c.fv.uris() } : ({})
        Drag.onDragFinished: function(a) { ghost.x = 0; ghost.y = 0 }
    }
    DropArea {
        id: da
        anchors.fill: parent
        enabled: c.fileIsDir && c.fa.mode !== "trash"
        onEntered: function(d) { if (d.source === ghost || c.selected && d.source !== null && d.source !== undefined) d.accepted = false }
        onDropped: function(d) { c.fa.dropInto(c.filePath, d) }
    }
}
