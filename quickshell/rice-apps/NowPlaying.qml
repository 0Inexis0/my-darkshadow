import QtQuick

// Player: Now playing. The cover, the song, a wavy line while it plays, the buttons, the volume and what comes next.
Rectangle {
    id: np
    property var pl
    property bool full: false
    signal close()
    radius: Theme.rXL
    color: Theme.surfaceC
    Behavior on color { ColorAnimation { duration: 500 } }
    readonly property var t: pl.cur || ({ title: "", artist: "", album: "", cover: "" })
    clip: true

    Item {
        id: top
        width: parent.width; height: 56
        IconBtn { visible: np.full; x: 8; anchors.verticalCenter: parent.verticalCenter; icon: "keyboard_arrow_down"; onClicked: np.close() }
        T { anchors.centerIn: parent; text: np.pl.isVideo ? "Now playing · video" : "Now playing"; role: "label"; color: Theme.inkVar }
        IconBtn {
            id: moreB
            anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
            icon: "more_vert"
            onClicked: Ui.menu([
                { icon: np.pl.dynColor ? "check_box" : "check_box_outline_blank", text: "Colors from the cover", act: function() { np.pl.dynColor = !np.pl.dynColor } },
                np.t.album ? { icon: "album", text: "Go to the album", act: function() { np.pl.tab = "albums"; np.pl.artist = ""; np.pl.albumKey = (np.t.albumartist || np.t.artist || "Unknown artist") + "|" + np.t.album; np.close() } } : null,
                np.t.artist ? { icon: "artist", text: "Go to " + (np.t.albumartist || np.t.artist), act: function() { np.pl.tab = "artists"; np.pl.albumKey = ""; np.pl.artist = np.t.albumartist || np.t.artist; np.close() } } : null,
                { icon: "folder_open", text: "Show in Files", act: function() { Sys.app("files", [np.t.path]) } },
                { sep: true },
                { icon: "clear_all", text: "Clear what comes next", enabled: np.pl.upNext.length > 0, act: function() { np.pl.order = np.pl.order.slice(0, np.pl.oi + 1) } }
            ], moreB, -200, moreB.height)
        }
    }
    Flickable {
        id: fl
        anchors.top: top.bottom
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col
            x: 24
            width: np.width - 48
            spacing: 14
            // the cover
            Item {
                width: parent.width
                height: cover.height + 8
                readonly property real s: Math.min(parent.width, np.full ? np.height * 0.46 : np.height * 0.4, 520)
                Rectangle {
                    id: cover
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.s; height: parent.s
                    radius: Theme.rXL
                    color: Theme.surfaceHighest
                    scale: np.pl.playing ? 1 : 0.92
                    Behavior on scale { NumberAnimation { duration: Theme.d(500); easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                    Rectangle { anchors.fill: parent; anchors.topMargin: 10; anchors.bottomMargin: -12; anchors.leftMargin: 6; anchors.rightMargin: 6
                                radius: parent.radius; color: Qt.rgba(0, 0, 0, 0.35); z: -1 }
                    Ic { anchors.centerIn: parent; name: np.pl.isVideo ? "movie" : "music_note"; size: parent.width * 0.32; color: Theme.inkVar; visible: art.status !== Image.Ready }
                    Pic { id: art; anchors.fill: parent; radius: parent.radius; res: 640; source: Theme.url(np.t.cover || "")
                        // V4.93: a new song: the cover springs in
                        onSourceChanged: coverIn.restart() }
                    property real bump: 1
                    transform: Scale { origin.x: cover.width / 2; origin.y: cover.height / 2; xScale: cover.bump; yScale: cover.bump }
                    SequentialAnimation { id: coverIn
                        NumberAnimation { target: cover; property: "bump"; to: 0.86; duration: Theme.d(120); easing.type: Easing.InCubic }
                        NumberAnimation { target: cover; property: "bump"; to: 1; duration: Theme.d(560); easing.type: Easing.OutBack; easing.overshoot: 2 } }
                }
            }
            Column {
                width: parent.width
                spacing: 2
                T { width: parent.width; text: np.t.title || "Nothing playing"; role: "headline"; font.pixelSize: 22; horizontalAlignment: Text.AlignHCenter }
                T { width: parent.width; text: [np.t.artist || "", np.t.album || ""].filter(function(x) { return x !== "" }).join(" · ")
                    color: Theme.primary; horizontalAlignment: Text.AlignHCenter; Behavior on color { ColorAnimation { duration: 400 } } }
            }
            // where it is
            Column {
                width: parent.width
                spacing: 0
                Slider {
                    width: parent.width; height: 32
                    wavy: true
                    playing: np.pl.playing
                    value: np.pl.len > 0 ? np.pl.pos / np.pl.len : 0
                    onReleased: function(v) { np.pl.seekTo(v * np.pl.len) }
                }
                Item {
                    width: parent.width; height: 18
                    T { text: Theme.clock(np.pl.pos); role: "small"; color: Theme.inkVar }
                    T { anchors.right: parent.right; text: Theme.clock(np.pl.len); role: "small"; color: Theme.inkVar }
                }
            }
            // the buttons
            Item {
                width: parent.width; height: 80
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "shuffle"; toggled: np.pl.shuffle; tip: "Shuffle (S)"; onClicked: np.pl.setShuffle(!np.pl.shuffle) }
                    IconBtn { anchors.verticalCenter: parent.verticalCenter; width: 52; height: 52; iconSize: 30; kind: "tonal"; icon: "skip_previous"; onClicked: np.pl.prev() }
                    PlayBtn { anchors.verticalCenter: parent.verticalCenter; size: 72; playing: np.pl.playing; onClicked: np.pl.toggle() }
                    IconBtn { anchors.verticalCenter: parent.verticalCenter; width: 52; height: 52; iconSize: 30; kind: "tonal"; icon: "skip_next"; onClicked: np.pl.next(false) }
                    IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: np.pl.repeat === "one" ? "repeat_one" : "repeat"; toggled: np.pl.repeat !== "off"
                              tip: np.pl.repeat === "off" ? "Repeat (R)" : (np.pl.repeat === "all" ? "Repeat all" : "Repeat this one"); onClicked: np.pl.cycleRepeat() }
                }
            }
            Row {
                width: parent.width
                spacing: 6
                IconBtn { id: muteB; icon: np.pl.muted || np.pl.vol === 0 ? "volume_off" : (np.pl.vol < 0.5 ? "volume_down" : "volume_up"); onClicked: np.pl.muted = !np.pl.muted; anchors.verticalCenter: parent.verticalCenter }
                Slider {
                    width: parent.width - muteB.width - 6; height: 32; trackH: 8
                    anchors.verticalCenter: parent.verticalCenter
                    value: np.pl.muted ? 0 : np.pl.vol
                    onMoved: function(v) { np.pl.setVol(v) }
                }
            }
            // what comes next
            Item { width: 1; height: 4 }
            Row {
                width: parent.width
                visible: np.pl.upNext.length > 0
                T { text: "Up next"; role: "title"; width: parent.width - cnt.width }
                T { id: cnt; text: np.pl.upNext.length + (np.pl.upNext.length >= 60 ? "+" : ""); role: "label"; color: Theme.inkVar }
            }
            Repeater {
                model: np.pl.upNext
                Item {
                    id: q
                    required property var modelData
                    readonly property var tr: modelData && modelData.t ? modelData.t : ({ title: "", artist: "", cover: "" })
                    width: col.width; height: 52
                    Rectangle { anchors.fill: parent; radius: 14; color: "transparent"; Layer { area: qm; ink: Theme.ink } }
                    Rectangle {
                        id: qc
                        x: 4; width: 40; height: 40; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.surfaceHighest
                        Pic { anchors.fill: parent; radius: 10; res: 80; source: Theme.url(q.tr.cover || "") }
                    }
                    Column {
                        anchors.left: qc.right; anchors.leftMargin: 12; anchors.right: rm.left; anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        T { width: parent.width; text: q.tr.title || ""; role: "label"; font.weight: 500 }
                        T { width: parent.width; text: q.tr.artist || ""; role: "small"; color: Theme.inkVar }
                    }
                    IconBtn { id: rm; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 34; iconSize: 18; icon: "close"
                              opacity: qm.containsMouse ? 1 : 0; onClicked: np.pl.removeAt(q.modelData.at) }
                    MouseArea { id: qm; anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: np.pl.jump(q.modelData.at) }
                }
            }
        }
    }
    VScroll { flick: fl; anchors.right: parent.right; anchors.top: fl.top; anchors.bottom: fl.bottom }
}
