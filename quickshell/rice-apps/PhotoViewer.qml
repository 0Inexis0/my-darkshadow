import QtQuick

// Photos: the viewer. The picture fits the window over a soft wash of its own colors; the wheel zooms where the
// pointer is, dragging moves a zoomed picture, a double click goes between "fit" and 1:1. Left / Right, the strip
// at the bottom, I for the details, Space for a slideshow, R turns it, Delete moves it to the trash.
Item {
    id: v
    property var ph
    property var list: []
    property int idx: 0
    property bool open: false
    property bool info: false
    property bool chrome: true
    property bool playing: false
    property int turn: 0
    property real zoom: 1                   // 1 = fits the window
    property real ox: 0
    property real oy: 0
    readonly property var cur: list[idx] || ({ path: "", video: false, t: 0, size: 0 })
    readonly property string name: cur.path.replace(/^.*\//, "")
    property var ex: ({})
    visible: shade.opacity > 0.01
    focus: open

    function show(l, i) {
        list = l; idx = Math.max(0, Math.min(l.length - 1, i))
        open = true; chrome = true; hideT.restart()
        reset()
        forceActiveFocus()
    }
    function close() { open = false; playing = false; info = false; ph.forceActiveFocus() }
    function go(d) {
        if (list.length === 0) return
        idx = (idx + d + list.length) % list.length
        reset()
    }
    function reset() { zoom = 1; ox = 0; oy = 0; turn = 0; ex = ({}); if (info) loadInfo() }
    onIdxChanged: if (open && info) loadInfo()
    function loadInfo() { const p = cur.path; if (p === "" || cur.video) return; Sys.run(["exif", p], function(r) { if (r && v.cur.path === p) v.ex = r }) }
    onInfoChanged: if (info) loadInfo()
    function poke() { chrome = true; hideT.restart() }
    Timer { id: hideT; interval: 2600; onTriggered: if (!barHover.containsMouse && !stripHover.containsMouse) v.chrome = false }
    Timer { interval: 4000; repeat: true; running: v.playing && v.open; onTriggered: v.go(1) }
    // the picture is drawn this big at zoom 1
    readonly property real fitK: {
        const iw = img.implicitWidth, ih = img.implicitHeight
        if (iw <= 0 || ih <= 0) return 1
        const sw = turn % 180 === 0 ? iw : ih, sh = turn % 180 === 0 ? ih : iw
        return Math.min(stage.width / sw, stage.height / sh, 1.0 * Math.max(1, 2))
    }
    function zoomAt(f, px, py) {
        const nz = Math.max(1, Math.min(12, zoom * f))
        const k = nz / zoom
        // keep the point under the pointer where it is
        ox = (ox - (px - stage.width / 2)) * k + (px - stage.width / 2)
        oy = (oy - (py - stage.height / 2)) * k + (py - stage.height / 2)
        zoom = nz
        clamp()
    }
    function clamp() {
        if (zoom <= 1.0001) { ox = 0; oy = 0; return }
        const w = (turn % 180 === 0 ? img.width : img.height) * zoom, h = (turn % 180 === 0 ? img.height : img.width) * zoom
        const mx = Math.max(0, (w - stage.width) / 2), my = Math.max(0, (h - stage.height) / 2)
        ox = Math.max(-mx, Math.min(mx, ox)); oy = Math.max(-my, Math.min(my, oy))
    }

    Keys.onPressed: function(k) {
        if (Ui.busy()) return
        poke()
        if (k.key === Qt.Key_Escape) { if (zoom > 1) reset(); else close() }
        else if (k.key === Qt.Key_Left) go(-1)
        else if (k.key === Qt.Key_Right) go(1)
        else if (k.key === Qt.Key_Space) playing = !playing
        else if (k.key === Qt.Key_I) info = !info
        else if (k.key === Qt.Key_R) { turn = (turn + 90) % 360; ox = 0; oy = 0 }
        else if (k.key === Qt.Key_Plus || k.key === Qt.Key_Equal) zoomAt(1.4, stage.width / 2, stage.height / 2)
        else if (k.key === Qt.Key_Minus) zoomAt(1 / 1.4, stage.width / 2, stage.height / 2)
        else if (k.key === Qt.Key_0) reset()
        else if (k.key === Qt.Key_F) ph.fav([cur.path], ph.favs.indexOf(cur.path) < 0)
        else if (k.key === Qt.Key_Delete) trashIt()
        else if ((k.modifiers & Qt.ControlModifier) && k.key === Qt.Key_C) ph.copyImage(cur.path)
        else return
        k.accepted = true
    }
    function trashIt() {
        const p = cur.path
        ph.trash([p], function() {
            const l = v.list.filter(function(x) { return x.path !== p })
            if (l.length === 0) { v.close(); return }
            v.list = l
            v.idx = Math.min(v.idx, l.length - 1)
            v.reset()
        })
    }

    Rectangle {
        id: shade
        anchors.fill: parent
        color: "#050506"
        opacity: v.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(220) } }
        // a soft wash of the picture's own colors behind it (a tiny copy of it, stretched)
        Image {
            anchors.fill: parent
            source: v.open && !v.cur.video ? Theme.url(v.cur.path) : (v.open && v.ph.thumbs[v.cur.path] ? Theme.url(v.ph.thumbs[v.cur.path]) : "")
            sourceSize.width: 24; sourceSize.height: 24
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            opacity: 0.38
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.35) } GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.05) } GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.45) } } }
    }
    Item {
        id: stage
        anchors.left: parent.left
        anchors.right: side.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 0
        clip: true
        visible: v.open
        Image {
            id: img
            source: v.open ? Theme.url(v.cur.video ? (v.ph.thumbs[v.cur.path] || "") : v.cur.path) : ""
            asynchronous: true
            autoTransform: true
            smooth: true
            mipmap: true
            readonly property real res: Math.min(4096, Math.max(stage.width, stage.height) * (v.zoom > 1.5 ? 3 : 1.5))
            sourceSize.width: res
            sourceSize.height: res
            width: implicitWidth * v.fitK
            height: implicitHeight * v.fitK
            x: (stage.width - width) / 2 + v.ox
            y: (stage.height - height) / 2 + v.oy
            rotation: v.turn
            scale: v.zoom
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on rotation { NumberAnimation { duration: Theme.d(300); easing.type: Easing.OutCubic } }
            Behavior on scale { enabled: !pan.active; NumberAnimation { duration: 120 } }
        }
        Rectangle {
            visible: v.cur.video
            anchors.centerIn: parent
            width: 84; height: 84; radius: Theme.sq ? 0 : (32)
            color: Theme.primary
            Ic { anchors.centerIn: parent; name: "play_arrow"; size: 48; color: Theme.inkPrimary }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Sys.app("player", [v.cur.path]) }
        }
        MouseArea {
            id: pan
            anchors.fill: parent
            hoverEnabled: true
            z: -1
            property bool active: false
            property point last: Qt.point(0, 0)
            cursorShape: v.zoom > 1 ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
            onPositionChanged: function(m) {
                v.poke()
                if (pressed && v.zoom > 1) { active = true; v.ox += m.x - last.x; v.oy += m.y - last.y; v.clamp() }
                last = Qt.point(m.x, m.y)
            }
            onPressed: function(m) { last = Qt.point(m.x, m.y); active = false }
            onReleased: active = false
            onDoubleClicked: function(m) { if (v.zoom > 1) { v.zoom = 1; v.ox = 0; v.oy = 0 } else v.zoomAt(Math.max(2, 1 / v.fitK), m.x, m.y) }
            onWheel: function(w) {
                if (w.modifiers & Qt.ControlModifier || v.zoom > 1 || Math.abs(w.angleDelta.y) < 120 && w.pixelDelta.y !== 0) v.zoomAt(w.angleDelta.y > 0 ? 1.18 : 1 / 1.18, w.x, w.y)
                else v.go(w.angleDelta.y > 0 ? -1 : 1)
            }
        }
        // the one before and the next one
        RoundNav { anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter; icon: "chevron_left"; onClicked: v.go(-1) }
        RoundNav { anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; icon: "chevron_right"; onClicked: v.go(1) }
    }

    // the top bar
    Item {
        id: bar
        visible: v.open
        width: stage.width; height: 72
        opacity: v.chrome ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.55) } GradientStop { position: 1; color: "transparent" } } }
        MouseArea { id: barHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        IconBtn { x: 12; anchors.verticalCenter: parent.verticalCenter; icon: "arrow_back"; ink: "white"; tip: "Back (Escape)"; onClicked: v.close() }
        Column {
            x: 64; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - tools.width - 24
            T { text: v.name; color: "white"; role: "title"; width: parent.width }
            T { text: (v.cur.t ? Qt.formatDateTime(new Date(v.cur.t), "dddd, d MMMM yyyy · hh:mm") : "") + (v.list.length > 1 ? "   " + (v.idx + 1) + " / " + v.list.length : "")
                color: Qt.rgba(1, 1, 1, 0.7); role: "small"; width: parent.width }
        }
        Row {
            id: tools
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            readonly property bool fav: v.ph.favs.indexOf(v.cur.path) >= 0
            IconBtn { icon: "favorite"; ink: tools.fav ? "#ff8a9a" : "white"; toggled: false; tip: tools.fav ? "Favorite (F)" : "Add to Favorites (F)"
                      onClicked: v.ph.fav([v.cur.path], !tools.fav) }
            IconBtn { icon: v.playing ? "pause" : "slideshow"; ink: "white"; tip: v.playing ? "Stop the slideshow (Space)" : "Slideshow (Space)"; onClicked: v.playing = !v.playing }
            IconBtn { icon: "rotate_right"; ink: "white"; tip: "Turn it (R)"; visible: !v.cur.video; onClicked: { v.turn = (v.turn + 90) % 360; v.ox = 0; v.oy = 0 } }
            IconBtn { icon: "info"; ink: "white"; toggled: v.info; tip: "Details (I)"; onClicked: v.info = !v.info }
            IconBtn { id: moreB; icon: "more_vert"; ink: "white"
                onClicked: Ui.menu([
                    !v.cur.video ? { icon: "wallpaper", text: "Set as wallpaper", act: function() { v.ph.wallpaper(v.cur.path) } } : null,
                    !v.cur.video ? { icon: "content_copy", text: "Copy the picture", key: "Ctrl+C", act: function() { v.ph.copyImage(v.cur.path) } } : null,
                    !v.cur.video ? { icon: "edit", text: "Edit", act: function() { v.ph.edit(v.cur.path) } } : null,
                    v.cur.video ? { icon: "play_circle", text: "Play in Player", act: function() { Sys.app("player", [v.cur.path]) } } : null,
                    { icon: "folder_open", text: "Show in Files", act: function() { v.ph.showInFiles(v.cur.path) } },
                    { icon: "link", text: "Copy the path", act: function() { copyPath(v.cur.path) } },
                    { sep: true },
                    { icon: "delete", text: "Move to the trash", key: "Delete", danger: true, act: v.trashIt }], moreB, -170, moreB.height) }
        }
    }
    function copyPath(t) { Sys.sh('printf %s "$1" | wl-copy', [t]); Ui.snack("Path copied") }

    // the strip of pictures at the bottom
    Item {
        id: strip
        visible: v.open && v.list.length > 1
        anchors.bottom: parent.bottom
        width: stage.width; height: 92
        opacity: v.chrome ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.55) } } }
        MouseArea { id: stripHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        ListView {
            id: sl
            anchors.fill: parent
            anchors.topMargin: 20; anchors.bottomMargin: 12
            orientation: ListView.Horizontal
            spacing: 6
            model: v.open ? v.list : []
            currentIndex: v.idx
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 30
            preferredHighlightEnd: width / 2 + 30
            highlightMoveDuration: 260
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 300
            delegate: Item {
                required property var modelData
                required property int index
                readonly property bool on: index === v.idx
                width: on ? 74 : 48; height: 60
                Behavior on width { NumberAnimation { duration: 200 } }
                Pic {
                    anchors.fill: parent
                    radius: Theme.sq ? 0 : (10)
                    res: 120
                    source: Theme.url(modelData.video ? (v.ph.thumbs[modelData.path] || "") : modelData.path)
                    opacity: parent.on ? 1 : 0.62
                }
                Rectangle { anchors.fill: parent; radius: Theme.sq ? 0 : (10); color: "transparent"; border.width: parent.on ? 2 : 0; border.color: "white" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { v.idx = index; v.reset() } }
            }
        }
    }

    // the details
    Rectangle {
        id: side
        visible: v.open
        anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: v.info ? Math.min(320, v.width * 0.4) : 0
        Behavior on width { NumberAnimation { duration: Theme.d(320); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        color: Theme.surfaceC
        clip: true
        Column {
            x: 24; y: 20
            width: 320 - 48
            spacing: 14
            Row {
                spacing: 8
                IconBtn { icon: "close"; onClicked: v.info = false }
                T { text: "Details"; role: "title"; anchors.verticalCenter: parent.verticalCenter }
            }
            InfoRow { icon: "calendar_today"; a: v.ex.taken ? v.ex.taken.replace(/^(\d+):(\d+):(\d+)/, "$1-$2-$3") : (v.cur.t ? Qt.formatDateTime(new Date(v.cur.t), "d MMMM yyyy") : ""); b: v.ex.taken ? "When it was taken" : (v.cur.t ? Qt.formatTime(new Date(v.cur.t), "hh:mm") + " · when the file changed" : "") }
            InfoRow { icon: "image"; a: v.name; b: (v.ex.w ? (v.ex.w * v.ex.h / 1e6).toFixed(1) + " MP · " + v.ex.w + " × " + v.ex.h + " · " : (img.implicitWidth > 0 && !v.cur.video ? img.sourceSize.width + " px · " : "")) + Theme.size(v.ex.size || v.cur.size) }
            InfoRow { icon: "photo_camera"; a: v.ex.camera || ""; b: v.ex.f ? "ƒ/" + v.ex.f + (v.ex.exp ? " · " + v.ex.exp + " s" : "") + (v.ex.iso ? " · ISO " + v.ex.iso : "") + (v.ex.focal ? " · " + v.ex.focal + " mm" : "") : "" }
            InfoRow { icon: "folder"; a: v.ph.albumName(v.cur.path.replace(/\/[^\/]*$/, "")); b: v.cur.path.replace(/\/[^\/]*$/, "").replace(Theme.home, "~") }
            Btn { kind: "tonal"; icon: "folder_open"; text: "Show in Files"; onClicked: v.ph.showInFiles(v.cur.path) }
        }
    }

    component InfoRow: Row {
        property string icon: ""
        property string a: ""
        property string b: ""
        visible: a !== "" || b !== ""
        spacing: 16
        width: parent.width
        Ic { name: parent.icon; size: 22; color: Theme.inkVar; y: 2 }
        Column {
            width: parent.width - 40
            T { text: parent.parent.a; width: parent.width; wrapMode: Text.WrapAnywhere; maximumLineCount: 2 }
            T { text: parent.parent.b; role: "small"; color: Theme.inkVar; width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3; visible: text !== "" }
        }
    }
    component RoundNav: Rectangle {
        id: rn
        property string icon: ""
        signal clicked()
        visible: v.list.length > 1
        width: 52; height: 52; radius: Theme.sq ? 0 : (26)
        color: Qt.rgba(0, 0, 0, 0.42)
        opacity: v.chrome ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Ic { anchors.centerIn: parent; name: rn.icon; size: 30; color: "white" }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rn.clicked(); onContainsMouseChanged: v.poke() }
    }
}
