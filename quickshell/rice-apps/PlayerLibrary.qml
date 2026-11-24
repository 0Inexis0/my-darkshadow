import QtQuick

// Player: the library: songs, albums (and an album's page), artists (and an artist's page), videos.
Item {
    id: lb
    property var pl
    function findNow() { search.input.forceActiveFocus(); search.input.selectAll() }
    function clearFind() { search.text = ""; pl.forceActiveFocus() }
    readonly property string mode: pl.tab === "albums" && pl.albumKey !== "" ? "album" : (pl.tab === "artists" && pl.artist !== "" ? "artist" : pl.tab)
    readonly property var album: pl.albumOf(pl.albumKey)

    // the heading
    Item {
        id: head
        width: parent.width; height: 92
        IconBtn { id: backB; visible: lb.mode === "album" || lb.mode === "artist"; x: 16; anchors.verticalCenter: parent.verticalCenter; icon: "arrow_back"
                  onClicked: { lb.pl.albumKey = ""; lb.pl.artist = "" } }
        Column {
            x: backB.visible ? 68 : 28
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(120, parent.width - x - search.width - 40)
            T { role: "display"; font.pixelSize: 30; width: parent.width
                text: lb.mode === "album" ? "Album" : (lb.mode === "artist" ? "Artist" : ({ songs: "Songs", albums: "Albums", artists: "Artists", videos: "Videos" })[lb.pl.tab] || "") }
            T { role: "label"; font.weight: 400; color: Theme.inkVar
                text: lb.pl.loading ? "Looking through your music …" : (lb.mode === "songs" ? lb.pl.songs.length + " songs" : (lb.mode === "albums" ? lb.pl.albums.length + " albums"
                      : (lb.mode === "artists" ? lb.pl.artists.length + " artists" : (lb.mode === "videos" ? lb.pl.vids.length + " videos" : "")))) }
        }
        Search {
            id: search
            visible: lb.mode === "songs" || lb.mode === "albums" || lb.mode === "artists"
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(320, lb.width * 0.4)
            hint: "Search your music"
            onTextChanged: lb.pl.query = text
            onEscaped: lb.clearFind()
        }
    }

    // songs
    ListView {
        id: songs
        visible: lb.mode === "songs"
        anchors.top: head.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 12; anchors.rightMargin: 12
        model: visible ? lb.pl.songs : []
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        bottomMargin: 16
        reuseItems: false      // V5.00: like Files (a reused row could stay on screen from the list before)
        cacheBuffer: 400
        delegate: TrackRow { required property var modelData; required property int index; width: songs.width; pl: lb.pl; t: modelData; list: lb.pl.songs; idx: index }
    }
    VScroll { flick: songs; visible: songs.visible && ratio < 0.999; anchors.right: parent.right; anchors.top: songs.top; anchors.bottom: songs.bottom }

    // albums
    GridView {
        id: albums
        visible: lb.mode === "albums"
        anchors.top: head.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 16; anchors.rightMargin: 16
        model: visible ? lb.pl.albums.filter(function(a) { return lb.pl.query === "" || (a.title + " " + a.artist).toLowerCase().indexOf(lb.pl.query.toLowerCase()) >= 0 }) : []
        readonly property int n: Math.max(2, Math.floor(width / 200))
        cellWidth: Math.floor(width / n)
        cellHeight: cellWidth + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        delegate: Card {
            required property var modelData
            width: albums.cellWidth; height: albums.cellHeight
            cover: modelData.cover; title: modelData.title; sub: modelData.artist
            playing: lb.pl.cur !== null && lb.pl.cur.album === modelData.title && (lb.pl.cur.albumartist || lb.pl.cur.artist) === modelData.artist
            onOpen: lb.pl.albumKey = modelData.key
            onPlay: lb.pl.playList(modelData.tracks, 0, false)
        }
    }
    VScroll { flick: albums; visible: albums.visible && ratio < 0.999; anchors.right: parent.right; anchors.top: albums.top; anchors.bottom: albums.bottom }

    // an album
    ListView {
        id: albumL
        visible: lb.mode === "album" && lb.album !== null
        anchors.top: head.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 12; anchors.rightMargin: 12
        model: visible ? lb.album.tracks : []
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        bottomMargin: 16
        header: Item {
            width: albumL.width; height: 236
            Rectangle {
                id: ac
                x: 12; y: 4
                width: 200; height: 200; radius: Theme.sq ? 0 : (Theme.rXL)
                color: Theme.surfaceHigh
                Ic { anchors.centerIn: parent; name: "album"; size: 64; color: Theme.inkVar }
                Pic { anchors.fill: parent; radius: Theme.sq ? 0 : (parent.radius); res: 400; source: Theme.url(lb.album ? lb.album.cover : "") }
            }
            Column {
                anchors.left: ac.right; anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.verticalCenter: ac.verticalCenter
                spacing: 6
                T { role: "headline"; font.pixelSize: 28; text: lb.album ? lb.album.title : ""; width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 2 }
                T { role: "title"; color: Theme.primary; text: lb.album ? lb.album.artist : ""; width: parent.width
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { lb.pl.tab = "artists"; lb.pl.artist = lb.album.artist; lb.pl.albumKey = "" } } }
                T { color: Theme.inkVar; role: "label"; font.weight: 400
                    text: lb.album ? [lb.album.year > 0 ? String(lb.album.year) : "", lb.album.tracks.length + (lb.album.tracks.length === 1 ? " song" : " songs"), Math.round(lb.album.dur / 60) + " min"].filter(function(x) { return x !== "" }).join(" · ") : "" }
                Item { width: 1; height: 8 }
                Row {
                    spacing: 8
                    Btn { kind: "filled"; icon: "play_arrow"; text: "Play"; onClicked: lb.pl.playList(lb.album.tracks, 0, false) }
                    Btn { kind: "tonal"; icon: "shuffle"; text: "Shuffle"; onClicked: lb.pl.playList(lb.album.tracks, 0, true) }
                    IconBtn { icon: "playlist_add"; kind: "outlined"; tip: "Add to the queue"; onClicked: lb.pl.addEnd(lb.album.tracks) }
                }
            }
        }
        delegate: TrackRow { required property var modelData; required property int index; width: albumL.width; pl: lb.pl; t: modelData; list: lb.album.tracks; idx: index
                             num: modelData.track > 0 ? String(modelData.track) : String(index + 1) }
    }

    // artists
    GridView {
        id: artists
        visible: lb.mode === "artists"
        anchors.top: head.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 16; anchors.rightMargin: 16
        model: visible ? lb.pl.artists.filter(function(a) { return lb.pl.query === "" || a.name.toLowerCase().indexOf(lb.pl.query.toLowerCase()) >= 0 }) : []
        readonly property int n: Math.max(2, Math.floor(width / 180))
        cellWidth: Math.floor(width / n)
        cellHeight: cellWidth + 44
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        delegate: Card {
            required property var modelData
            width: artists.cellWidth; height: artists.cellHeight
            round: true
            cover: modelData.cover; title: modelData.name; sub: { const a = Object.keys(modelData.albums).length; return a + (a === 1 ? " album · " : " albums · ") + modelData.n + (modelData.n === 1 ? " song" : " songs") }
            onOpen: lb.pl.artist = modelData.name
            onPlay: lb.pl.playList(lb.pl.lib.filter(function(t) { return (t.albumartist || t.artist || "Unknown artist") === modelData.name }), 0, false)
        }
    }
    // an artist
    ListView {
        id: artistL
        visible: lb.mode === "artist"
        anchors.top: head.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 12; anchors.rightMargin: 12
        model: visible ? lb.pl.artistSongs : []
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        bottomMargin: 16
        header: Column {
            width: artistL.width
            spacing: 16
            Row {
                x: 12
                spacing: 24
                Rectangle {
                    width: 160; height: 160; radius: Theme.sq ? 0 : (80)
                    color: Theme.surfaceHigh
                    Ic { anchors.centerIn: parent; name: "artist"; size: 56; color: Theme.inkVar }
                    Pic { anchors.fill: parent; radius: Theme.sq ? 0 : (80); res: 320; source: Theme.url(lb.pl.artistAlbums.length > 0 ? lb.pl.artistAlbums[0].cover : "") }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    T { role: "headline"; font.pixelSize: 30; text: lb.pl.artist }
                    T { color: Theme.inkVar; text: lb.pl.artistAlbums.length + (lb.pl.artistAlbums.length === 1 ? " album · " : " albums · ") + lb.pl.artistSongs.length + (lb.pl.artistSongs.length === 1 ? " song" : " songs") }
                    Row {
                        spacing: 8
                        Btn { kind: "filled"; icon: "play_arrow"; text: "Play"; onClicked: lb.pl.playList(lb.pl.artistSongs, 0, false) }
                        Btn { kind: "tonal"; icon: "shuffle"; text: "Shuffle"; onClicked: lb.pl.playList(lb.pl.artistSongs, 0, true) }
                    }
                }
            }
            T { x: 12; role: "title"; text: "Albums" }
            ListView {
                width: parent.width; height: 210
                orientation: ListView.Horizontal
                spacing: 4
                clip: true
                model: lb.pl.artistAlbums
                boundsBehavior: Flickable.StopAtBounds
                delegate: Card { required property var modelData; width: 170; height: 210; cover: modelData.cover; title: modelData.title
                                 sub: modelData.year > 0 ? String(modelData.year) : modelData.tracks.length + " songs"
                                 onOpen: { lb.pl.tab = "albums"; lb.pl.albumKey = modelData.key; lb.pl.artist = "" }
                                 onPlay: lb.pl.playList(modelData.tracks, 0, false) }
            }
            T { x: 12; role: "title"; text: "Songs" }
            Item { width: 1; height: 1 }
        }
        delegate: TrackRow { required property var modelData; required property int index; width: artistL.width; pl: lb.pl; t: modelData; list: lb.pl.artistSongs; idx: index }
    }

    // videos
    GridView {
        id: videos
        visible: lb.mode === "videos"
        anchors.top: head.bottom; anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 16; anchors.rightMargin: 16
        model: visible ? lb.pl.vids : []
        readonly property int n: Math.max(1, Math.floor(width / 280))
        cellWidth: Math.floor(width / n)
        cellHeight: Math.round((cellWidth - 16) * 9 / 16) + 70
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: vd
            required property var modelData
            required property int index
            width: videos.cellWidth; height: videos.cellHeight
            Rectangle {
                id: vthumb
                x: 8; y: 8
                width: parent.width - 16; height: Math.round(width * 9 / 16)
                radius: Theme.sq ? 0 : (Theme.rL)
                color: Theme.surfaceHigh
                scale: vm.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: 140 } }
                Ic { anchors.centerIn: parent; name: "movie"; size: 40; color: Theme.inkVar }
                Pic { anchors.fill: parent; radius: Theme.sq ? 0 : (parent.radius); res: 480; source: Theme.url(vd.modelData.cover || "") }
                Rectangle {
                    anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8
                    width: dl.implicitWidth + 12; height: 22; radius: Theme.sq ? 0 : (11)
                    color: Qt.rgba(0, 0, 0, 0.6)
                    visible: vd.modelData.dur > 0
                    T { id: dl; anchors.centerIn: parent; text: Theme.clock(vd.modelData.dur); role: "small"; color: "white" }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 52; height: 52; radius: Theme.sq ? 0 : (26)
                    color: Theme.primary
                    opacity: vm.containsMouse ? 1 : 0
                    scale: vm.containsMouse ? 1 : 0.7
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Ic { anchors.centerIn: parent; name: "play_arrow"; size: 30; color: Theme.inkPrimary }
                }
            }
            T { x: 12; anchors.top: vthumb.bottom; anchors.topMargin: 8; width: parent.width - 24; text: vd.modelData.title; font.weight: 500 }
            T { x: 12; anchors.top: vthumb.bottom; anchors.topMargin: 28; width: parent.width - 24; role: "small"; color: Theme.inkVar; text: Theme.when(vd.modelData.t) }
            MouseArea { id: vm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) {
                    if (m.button === Qt.RightButton) Ui.menu([{ icon: "play_arrow", text: "Play", act: function() { lb.pl.playList(lb.pl.vids, vd.index, false) } },
                                                            { icon: "folder_open", text: "Show in Files", act: function() { Sys.app("files", [vd.modelData.path]) } }], vm, m.x, m.y)
                    else lb.pl.playList(lb.pl.vids, vd.index, false)
                } }
        }
    }

    // nothing yet
    Column {
        anchors.centerIn: parent
        spacing: 12
        visible: !lb.pl.loading && ((lb.mode === "songs" && lb.pl.songs.length === 0) || (lb.mode === "albums" && albums.count === 0)
                 || (lb.mode === "artists" && artists.count === 0) || (lb.mode === "videos" && lb.pl.vids.length === 0))
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 112; height: 112; radius: Theme.sq ? 0 : (56)
            color: Theme.surfaceC
            Ic { anchors.centerIn: parent; size: 52; color: Theme.primary; name: lb.mode === "videos" ? "smart_display" : (lb.pl.query !== "" ? "search_off" : "library_music") }
        }
        T { anchors.horizontalCenter: parent.horizontalCenter; role: "title"
            text: lb.pl.query !== "" ? "Nothing found" : (lb.mode === "videos" ? "No videos yet" : "No music yet") }
        T { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.inkVar
            text: lb.pl.query !== "" ? "Try other words" : (lb.mode === "videos" ? "Videos in ~/Videos show up here" : "Songs in ~/Music show up here") }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 56; height: 56; radius: Theme.sq ? 0 : (28)
        color: Theme.surfaceHigh
        visible: lb.pl.loading && lb.mode !== "videos"
        Ic { anchors.centerIn: parent; name: "progress_activity"; size: 28; color: Theme.primary
             RotationAnimation on rotation { running: parent.visible; from: 0; to: 360; duration: 900; loops: Animation.Infinite } }
    }

    // an album or an artist as a card: its picture, a play button on it when the pointer is there
    component Card: Item {
        id: c
        property real pop: 1
        opacity: pop
        SequentialAnimation {
            id: cardIn
            PropertyAction { target: c; property: "pop"; value: 0 }
            PauseAnimation { duration: Math.min(10, Math.max(0, Math.round((c.x + c.y * 3) / Math.max(1, c.width)))) * Theme.d(26) }
            NumberAnimation { target: c; property: "pop"; to: 1; duration: Theme.d(420); easing.type: Easing.OutCubic }
        }
        Connections { target: lb.pl; function onViewTickChanged() { cardIn.restart() } }
        property string cover: ""
        property string title: ""
        property string sub: ""
        property bool round: false
        property bool playing: false
        signal open()
        signal play()
        Rectangle {
            id: pic
            x: 8; y: 8
            width: c.width - 16; height: width
            radius: Theme.sq ? 0 : (c.round ? width / 2 : Theme.rXL)
            color: Theme.surfaceHigh
            // V4.93: it lifts a little under the pointer, and pops in when the page opens
            scale: (cm.pressed ? 0.95 : (cm.containsMouse ? 1.04 : 1)) * (0.8 + 0.2 * c.pop)
            Behavior on scale { NumberAnimation { duration: Theme.d(240); easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
            Ic { anchors.centerIn: parent; name: c.round ? "artist" : "album"; size: parent.width * 0.3; color: Theme.inkVar }
            Pic { anchors.fill: parent; radius: Theme.sq ? 0 : (parent.radius); res: 400; source: Theme.url(c.cover) }
            Rectangle {
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.rightMargin: c.round ? parent.width * 0.08 : 10; anchors.bottomMargin: c.round ? parent.width * 0.08 : 10
                width: 48; height: 48; radius: Theme.sq ? 0 : (cpm.pressed ? 14 : 24)
                color: Theme.primary
                opacity: cm.containsMouse || cpm.containsMouse || c.playing ? 1 : 0
                scale: cm.containsMouse || cpm.containsMouse || c.playing ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                Behavior on radius { NumberAnimation { duration: 160 } }
                Ic { anchors.centerIn: parent; name: c.playing ? "graphic_eq" : "play_arrow"; size: 28; color: Theme.inkPrimary }
                MouseArea { id: cpm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.play() }
            }
        }
        T { anchors.top: pic.bottom; anchors.topMargin: 8; x: c.round ? 8 : 12; width: c.width - (c.round ? 16 : 24)
            horizontalAlignment: c.round ? Text.AlignHCenter : Text.AlignLeft; text: c.title; font.weight: 500 }
        T { anchors.top: pic.bottom; anchors.topMargin: 28; x: c.round ? 8 : 12; width: c.width - (c.round ? 16 : 24)
            horizontalAlignment: c.round ? Text.AlignHCenter : Text.AlignLeft; text: c.sub; role: "small"; color: Theme.inkVar }
        MouseArea { id: cm; anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.open() }
    }
}
