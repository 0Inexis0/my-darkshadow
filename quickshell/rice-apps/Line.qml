import QtQuick

// Files: one file in the list.
Item {
    id: c
    required property int index
    required property string fileName
    required property string filePath
    required property bool fileIsDir
    required property var fileSize
    required property var fileModified
    property var fv
    // V4.93: it slides in when a folder opens (one after another)
    property real pop: 1
    SequentialAnimation {
        id: popA
        PropertyAction { target: c; property: "pop"; value: 0 }
        PauseAnimation { duration: Math.min(12, Math.max(0, c.index - Math.floor(c.ListView.view.contentY / Math.max(1, c.height)))) * Theme.d(20) }
        NumberAnimation { target: c; property: "pop"; to: 1; duration: Theme.d(360); easing.type: Easing.OutCubic }
    }
    Connections { target: c.fv; function onNavTickChanged() { popA.restart() } }
    opacity: pop
    transform: Translate { x: (1 - c.pop) * 26 }
    property var lv
    readonly property var fa: fv.fa
    width: lv.width
    height: 44
    readonly property bool selected: fa.sel[filePath] === true
    readonly property bool cut: fa.cutSet[filePath] === true
    readonly property string kind: Theme.kind(fileName, fileIsDir)
    readonly property bool dropOn: da.containsDrag && !(selected && da.drag.source)
    function want() { if (kind === "video" || kind === "pdf") fv.needThumb(filePath) }
    onFilePathChanged: want()
    Component.onCompleted: want()

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1; anchors.bottomMargin: 1
        radius: height / 2
        color: c.selected ? Theme.secondaryContainer : (c.dropOn ? Theme.alpha(Theme.primary, 0.16) : "transparent")
        border.width: c.dropOn ? 2 : 0
        border.color: Theme.primary
        Layer { area: ma; ink: c.selected ? Theme.inkSecondaryC : Theme.ink }
    }
    FileTile {
        id: tile
        x: 14; anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30
        path: c.filePath; name: c.fileName; isDir: c.fileIsDir
        thumb: c.fa.thumbs[c.filePath] || ""
        symbol: c.fileIsDir ? (c.fa.symbols[c.filePath] || "") : ""
        hover: ma.containsMouse || c.dropOn
        opacity: c.cut ? 0.45 : 1
    }
    T {
        x: 56
        width: c.width - x - c.lv.cDate - c.lv.cSize - 8
        anchors.verticalCenter: parent.verticalCenter
        text: c.fileName
        elide: Text.ElideMiddle
        color: c.selected ? Theme.inkSecondaryC : Theme.ink
        opacity: c.cut ? 0.6 : 1
        Ic { visible: c.fa.starred.indexOf(c.filePath) >= 0; name: "star"; size: 15; color: Theme.tertiary
             x: Math.min(parent.implicitWidth, parent.width) + 6; anchors.verticalCenter: parent.verticalCenter }
    }
    T {
        visible: c.lv.cDate > 0
        x: c.width - c.lv.cDate - c.lv.cSize + 12
        width: c.lv.cDate - 16
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.when(c.fileModified)
        role: "label"; font.weight: 400
        color: Theme.inkVar
    }
    T {
        visible: c.lv.cSize > 0
        x: c.width - c.lv.cSize
        width: c.lv.cSize - 16
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
        text: c.fileIsDir ? "—" : Theme.size(Number(c.fileSize))
        role: "label"; font.weight: 400
        color: Theme.inkVar
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: true
        drag.target: ghost
        drag.threshold: 8
        onPressed: function(m) { c.fv.press(c.index, m); if (m.button === Qt.LeftButton) tile.grabToImage(function(r) { ghost.Drag.imageSource = r.url }, Qt.size(40, 40)) }
        onReleased: function(m) { c.fv.release(c.index, m, drag.active) }
        onClicked: function(m) {
            if (m.button === Qt.RightButton) c.fv.menuAt(c.index, ma, m)
            else if (m.button === Qt.MiddleButton && c.fileIsDir) Sys.app("files", [c.filePath])
        }
        onDoubleClicked: function(m) { if (m.button === Qt.LeftButton) c.fa.openSel() }
    }
    Item {
        id: ghost
        width: 40; height: 40
        Drag.active: ma.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.hotSpot: Qt.point(20, 20)
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
