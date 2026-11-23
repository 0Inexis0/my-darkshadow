import QtQuick

// Files: the files themselves, as a grid of pictures or as a list with columns. Click selects (Ctrl adds, Shift a
// range), a double click opens, a drag on the empty space selects a box of them, a drag on a file moves it
// (into a folder here, or into another app: Ctrl copies).
FocusScope {
    id: fview
    property var fa
    readonly property var cur: fa.view === "grid" ? grid : list
    readonly property int cols: Math.max(1, Math.floor(grid.width / grid.cellWidth))
    // which files need a picture made (videos, PDFs): asked in groups
    property var want: []
    property var asked: ({})
    function needThumb(p) {
        if (fa.thumbs[p] !== undefined || asked[p]) return
        asked[p] = true
        want.push(p)
        thumbT.restart()
    }
    Timer { id: thumbT; interval: 120; onTriggered: fview.askThumbs() }
    function askThumbs() {
        if (want.length === 0) return
        const l = want.splice(0, 24)
        Sys.run(["thumbs"].concat(l), function(r) {
            if (!r) return
            const t = Object.assign({}, fview.fa.thumbs)
            for (const k in r) t[k] = r[k]
            fview.fa.thumbs = t
        })
        if (want.length > 0) thumbT.restart()
    }
    // V4.93: a new folder slides in (deeper: from the right, back up: from the left) and its files pop in one after
    // another, from the top left
    property int navTick: 0
    property int dir: 1
    property real enterK: 1
    property string lastCur: ""
    NumberAnimation { id: enterA; target: fview; property: "enterK"; from: 0; to: 1; duration: Theme.d(420); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
    Connections {
        target: fview.fa
        function onCurChanged() {
            const n = fview.fa.cur, o = fview.lastCur
            fview.dir = o !== "" && n.indexOf(o) !== 0 ? -1 : 1
            fview.lastCur = n
            fview.navTick++
            enterA.restart()
        }
    }
    Component.onCompleted: lastCur = fa.cur
    function forceFocus() { fa.forceActiveFocus() }
    onActiveFocusChanged: if (activeFocus) fa.forceActiveFocus()

    function press(i, m) {
        fa.forceActiveFocus()
        fa.mx = m.x; fa.my = m.y
        const e = fa.at(i); if (!e) return
        if (m.button === Qt.RightButton) {
            if (!fa.isSel(e.path)) fa.selectOnly(i)
            return
        }
        if (m.modifiers & Qt.ShiftModifier) fa.range(i, m.modifiers & Qt.ControlModifier)
        else if (m.modifiers & Qt.ControlModifier) fa.toggle(i)
        else if (!fa.isSel(e.path)) fa.selectOnly(i)
    }
    function release(i, m, moved) {
        // a plain click on one of several chosen files keeps only it
        if (!moved && m.button === Qt.LeftButton && !(m.modifiers & (Qt.ShiftModifier | Qt.ControlModifier)) && fa.selN > 1) fa.selectOnly(i)
    }
    function menuAt(i, item, m) {
        const e = fa.at(i); if (!e) return
        const p = item.mapToItem(fa, m.x, m.y)
        fa.mx = p.x; fa.my = p.y
        Ui.menu(fa.itemMenu(e), null, p.x, p.y)
    }
    function bgMenu(item, m) {
        const p = item.mapToItem(fa, m.x, m.y)
        fa.mx = p.x; fa.my = p.y
        Ui.menu(fa.folderMenu(), null, p.x, p.y)
    }
    function uris() {
        return fa.selPaths().map(function(p) { return Theme.url(p) }).join("\r\n") + "\r\n"
    }

    // ---------------------------------------------------------------- grid
    GridView {
        id: grid
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        visible: fview.fa.view === "grid"
        model: visible ? fview.fa.model : null
        readonly property int n: Math.max(1, Math.floor(width / fview.fa.zoom))
        cellWidth: Math.floor(width / n)
        cellHeight: Math.round(cellWidth * 0.86) + 44
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1
        highlightFollowsCurrentItem: false
        cacheBuffer: 400
        bottomMargin: 88
        // V5.00: no reused delegates and no add transition: with both, files of the folder you left stayed on
        // screen under the new ones (two names in one place); the pop-in of each file is its own animation
        reuseItems: false
        flickDeceleration: 4000
        maximumFlickVelocity: 5000
        opacity: 0.25 + 0.75 * fview.enterK
        transform: Translate { x: fview.dir * 34 * (1 - fview.enterK) }
        Band { view: grid; fv: fview }
        delegate: Cell { fv: fview }
        WheelHandler {
            acceptedModifiers: Qt.ControlModifier
            onWheel: function(w) { fview.fa.zoom = Math.max(72, Math.min(220, fview.fa.zoom + (w.angleDelta.y > 0 ? 12 : -12))) }
        }
    }
    VScroll { flick: grid; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; visible: grid.visible && ratio < 0.999 }

    // ---------------------------------------------------------------- list
    ListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 12; anchors.rightMargin: 12
        visible: fview.fa.view === "list"
        model: visible ? fview.fa.model : null
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1
        highlightFollowsCurrentItem: false
        cacheBuffer: 400
        bottomMargin: 88
        // V5.00: no reused delegates and no add transition: with both, files of the folder you left stayed on
        // screen under the new ones (two names in one place); the pop-in of each file is its own animation
        reuseItems: false
        headerPositioning: ListView.OverlayHeader
        flickDeceleration: 4000
        maximumFlickVelocity: 5000
        readonly property real cSize: width > 620 ? 100 : 0
        readonly property real cDate: width > 480 ? 150 : 0
        header: Rectangle {
            z: 3
            width: list.width; height: 40
            color: Theme.surfaceLow
            Row {
                anchors.fill: parent
                Col { text: "Name"; key: "name"; width: parent.width - list.cDate - list.cSize; leftPad: 56 }
                Col { text: fview.fa.mode === "trash" ? "Deleted" : "Modified"; key: "date"; width: list.cDate; visible: width > 0 }
                Col { text: "Size"; key: "size"; width: list.cSize; visible: width > 0; alignRight: true }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.outlineVariant }
        }
        opacity: 0.25 + 0.75 * fview.enterK
        transform: Translate { x: fview.dir * 34 * (1 - fview.enterK) }
        Band { view: list; fv: fview }
        delegate: Line { fv: fview; lv: list }
    }
    VScroll { flick: list; anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 40; anchors.bottom: parent.bottom; visible: list.visible && ratio < 0.999 }

    // files dropped from another app onto the empty space: into this folder
    DropArea {
        anchors.fill: parent
        z: -1
        enabled: fview.fa.mode === "folder"
        onDropped: function(d) { if (d.source === null || d.source === undefined) fview.fa.dropInto(fview.fa.cur, d) }
    }

    component Col: Item {
        id: col
        property string text: ""
        property string key: ""
        property real leftPad: 12
        property bool alignRight: false
        readonly property bool on: fview.fa.sortBy === key
        height: 40
        T { x: col.alignRight ? col.width - width - 16 : col.leftPad; anchors.verticalCenter: parent.verticalCenter; text: col.text; role: "label"
            color: col.on ? Theme.primary : Theme.inkVar
            Ic { visible: col.on; name: fview.fa.rev ? "arrow_upward" : "arrow_downward"; size: 15; color: Theme.primary
                 anchors.left: col.alignRight ? undefined : parent.right; anchors.right: col.alignRight ? parent.left : undefined
                 anchors.leftMargin: 4; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { if (col.on) fview.fa.rev = !fview.fa.rev; else { fview.fa.sortBy = col.key; fview.fa.rev = false } } }
    }
}
