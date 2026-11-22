import QtQuick

// Player: one song in a list. A click plays the list from it; the dots (or a right click): play next, the queue,
// the album, the artist.
Item {
    id: r
    property var pl
    property var t: ({})
    property var list: []
    property int idx: 0
    property string num: ""               // a track number instead of the cover (album pages)
    readonly property bool now: pl.cur !== null && pl.cur.path === t.path
    height: 60
    // V4.93: the rows slide in one after another when a page opens
    property real pop: 1
    opacity: pop
    transform: Translate { x: (1 - r.pop) * 30 }
    SequentialAnimation {
        id: rowIn
        PropertyAction { target: r; property: "pop"; value: 0 }
        PauseAnimation { duration: Math.min(12, Math.max(0, Math.round(r.y - (r.ListView.view ? r.ListView.view.contentY : 0)) / 60)) * Theme.d(22) }
        NumberAnimation { target: r; property: "pop"; to: 1; duration: Theme.d(380); easing.type: Easing.OutCubic }
    }
    Connections { target: r.pl; function onViewTickChanged() { rowIn.restart() } }
    Rectangle {
        anchors.fill: parent
        radius: Theme.rL
        color: r.now ? Theme.secondaryContainer : "transparent"
        Layer { area: ma; ink: Theme.ink }
    }
    Item {
        id: lead
        x: 10; width: 44; height: 44
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            visible: r.num === ""
            anchors.fill: parent
            radius: 12
            color: Theme.surfaceHigh
            Ic { anchors.centerIn: parent; name: "music_note"; size: 20; color: Theme.inkVar; visible: cov.status !== Image.Ready }
            Pic { id: cov; anchors.fill: parent; radius: 12; res: 96; source: Theme.url(r.t.cover || "") }
        }
        T { visible: r.num !== "" && !r.now; anchors.centerIn: parent; text: r.num; color: Theme.inkVar; role: "label" }
        // it is playing: three little bars
        Rectangle {
            visible: r.now
            anchors.fill: parent
            radius: 12
            color: r.num === "" ? Qt.rgba(0, 0, 0, 0.45) : "transparent"
            Row {
                anchors.centerIn: parent
                spacing: 3
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 4; radius: 2
                        color: r.num === "" ? "white" : Theme.primary
                        anchors.bottom: parent.bottom
                        height: 6
                        SequentialAnimation on height {
                            running: r.now && r.pl.playing
                            loops: Animation.Infinite
                            NumberAnimation { to: 16 - index * 3; duration: 260 + index * 90; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 5 + index * 2; duration: 300 + index * 70; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }
    }
    Column {
        anchors.left: lead.right; anchors.leftMargin: 14
        anchors.right: dur.left; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        T { width: parent.width; text: r.t.title || ""; font.weight: 500; color: r.now ? Theme.inkSecondaryC : Theme.ink }
        T { width: parent.width; role: "small"; color: r.now ? Theme.inkSecondaryC : Theme.inkVar
            text: [r.t.artist || "", r.num === "" ? (r.t.album || "") : ""].filter(function(x) { return x !== "" }).join(" · ") }
    }
    T { id: dur; anchors.right: more.left; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
        text: r.t.dur ? Theme.clock(r.t.dur) : ""; role: "label"; font.weight: 400; color: Theme.inkVar }
    IconBtn { id: more; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
        icon: "more_vert"; opacity: ma.containsMouse || r.now ? 1 : 0.0; onClicked: r.menu(more, 0, more.height) }
    MouseArea {
        id: ma
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(m) { if (m.button === Qt.RightButton) r.menu(ma, m.x, m.y); else r.pl.playList(r.list, r.idx) }
    }
    function menu(src, x, y) {
        const t = r.t
        Ui.menu([
            { icon: "play_arrow", text: "Play", act: function() { r.pl.playList(r.list, r.idx) } },
            { icon: "playlist_play", text: "Play next", act: function() { r.pl.addNext(t) } },
            { icon: "playlist_add", text: "Add to the queue", act: function() { r.pl.addEnd([t]) } },
            { sep: true },
            t.album ? { icon: "album", text: "Go to the album", act: function() { r.pl.tab = "albums"; r.pl.artist = ""; r.pl.albumKey = (t.albumartist || t.artist || "Unknown artist") + "|" + t.album } } : null,
            t.artist ? { icon: "artist", text: "Go to " + (t.albumartist || t.artist), act: function() { r.pl.tab = "artists"; r.pl.albumKey = ""; r.pl.artist = t.albumartist || t.artist } } : null,
            { icon: "folder_open", text: "Show in Files", act: function() { Sys.app("files", [t.path]) } }
        ], src, x, y)
    }
}
