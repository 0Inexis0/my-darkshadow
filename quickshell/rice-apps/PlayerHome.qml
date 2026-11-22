import QtQuick

// Music > Home (V4.87): a greeting with your music in numbers and the covers you play most cut to our shapes, then
// Listen again (the albums you played last), On repeat (your most played songs), Recently added and your artists,
// each one in a shape of its own.
Item {
    id: hm
    property var pl

    function greeting() {
        const h = new Date().getHours()
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : h < 22 ? "Good evening" : "Good night"
    }
    function hm2(s) {
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }
    readonly property var shapes: ["cookie", "flower", "clover", "sun", "puffy", "cookie6", "softburst", "clover8"]

    // the albums you played, the last one first (with nothing played yet: some of your albums)
    readonly property var again: {
        const h = pl.hist, seen = {}, out = []
        const paths = Object.keys(h).sort(function(a, b) { return h[b].t - h[a].t })
        for (let i = 0; i < paths.length && out.length < 16; i++) {
            const t = pl.byPath[paths[i]]
            if (!t) continue
            const k = (t.albumartist || t.artist || "Unknown artist") + "|" + t.album
            if (seen[k]) continue
            seen[k] = true
            const a = pl.albumOf(k)
            if (a) out.push(a)
        }
        if (out.length < 4) for (let i = 0; i < pl.albums.length && out.length < 12; i++) if (!seen[pl.albums[i].key]) { seen[pl.albums[i].key] = true; out.push(pl.albums[(i * 7) % pl.albums.length]) }
        return out
    }
    readonly property var topSongs: {
        const h = pl.hist
        return Object.keys(h).filter(function(p) { return !!pl.byPath[p] })
                     .sort(function(a, b) { return h[b].n - h[a].n || h[b].t - h[a].t }).slice(0, 9)
                     .map(function(p) { return pl.byPath[p] })
    }
    readonly property var fresh: pl.albums.slice().sort(function(a, b) {
        const ta = Math.max.apply(null, a.tracks.map(function(t) { return t.t || 0 }))
        const tb = Math.max.apply(null, b.tracks.map(function(t) { return t.t || 0 }))
        return tb - ta
    }).slice(0, 14)
    readonly property var covers: {
        const l = [], seen = {}
        const src = topSongs.concat(again.map(function(a) { return a.tracks[0] }))
        for (let i = 0; i < src.length && l.length < 3; i++) if (src[i] && src[i].cover && !seen[src[i].cover]) { seen[src[i].cover] = true; l.push(src[i].cover) }
        for (let i = 0; i < pl.albums.length && l.length < 3; i++) if (pl.albums[i].cover && !seen[pl.albums[i].cover]) { seen[pl.albums[i].cover] = true; l.push(pl.albums[i].cover) }
        return l
    }

    Flickable {
        id: fl
        anchors.fill: parent
        contentHeight: col.height + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        VScroll { flick: fl }
        Column {
            id: col
            x: 20; y: 20
            width: fl.width - 40
            spacing: 14

            // ---------------- the greeting
            Rectangle {
                id: hero
                width: parent.width
                height: 248
                radius: Theme.rXL + 8
                color: Theme.primaryContainer
                clip: true
                Behavior on color { ColorAnimation { duration: 500 } }
                // shapes drifting behind
                Shape { width: 260; height: 260; x: hero.width * 0.44; y: -110; kind: "clover8"; color: Theme.alpha(Theme.inkPrimaryC, 0.07)
                    RotationAnimator on rotation { from: 0; to: 360; duration: 70000; loops: Animation.Infinite; running: hm.visible } }
                Shape { width: 90; height: 90; x: hero.width * 0.38; y: hero.height - 60; kind: "sun"; color: Theme.tertiary; opacity: 0.85
                    RotationAnimator on rotation { from: 360; to: 0; duration: 26000; loops: Animation.Infinite; running: hm.visible } }
                Column {
                    x: 32
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    T { role: "label"; font.letterSpacing: 1.6; color: Theme.inkPrimaryC; opacity: 0.85
                        text: hm.pl.loading ? "LOOKING THROUGH YOUR MUSIC" : (hm.pl.lib.length + " SONGS  ·  " + hm.hm2(hm.pl.libDur).toUpperCase()) }
                    T { role: "display"; font.pixelSize: 44; color: Theme.inkPrimaryC; text: hm.greeting() }
                    T { visible: !hm.pl.loading && hm.pl.lib.length === 0; color: Theme.inkPrimaryC; text: "Put your music in ~/Music and it shows up here" }
                    Item { width: 1; height: 4 }
                    Row {
                        spacing: 10
                        visible: hm.pl.lib.length > 0
                        Btn { kind: "filled"; icon: "shuffle"; text: "Shuffle"; onClicked: hm.pl.playList(hm.pl.lib, 0, true) }
                        Btn { kind: "tonal"; icon: "play_arrow"; text: "Play all"; onClicked: hm.pl.playList(hm.pl.lib, 0, false) }
                    }
                }
                // the covers you play most, in shapes
                Item {
                    visible: hero.width > 720
                    anchors.right: parent.right; anchors.rightMargin: 26
                    anchors.verticalCenter: parent.verticalCenter
                    width: 330; height: 220
                    Repeater {
                        model: hm.covers.length
                        ShapePic {
                            required property int index
                            readonly property var spot: [{ x: 120, y: 10, s: 200, k: "cookie" }, { x: 10, y: 96, s: 120, k: "flower" }, { x: 34, y: 0, s: 86, k: "clover" }][index]
                            x: spot.x; y: spot.y; width: spot.s; height: spot.s
                            kind: spot.k
                            source: Theme.url(hm.covers[index])
                            res: 400
                            fill: Theme.secondaryContainer
                            RotationAnimator on rotation { from: index % 2 ? 360 : 0; to: index % 2 ? 0 : 360; duration: 50000 + index * 9000; loops: Animation.Infinite; running: hm.visible }
                        }
                    }
                }
            }

            // ---------------- Listen again
            Head { text: "Listen again"; list: againL; visible: hm.again.length > 0 }
            ListView {
                id: againL
                visible: hm.again.length > 0
                width: parent.width; height: 236
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: hm.again
                Behavior on contentX { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                delegate: AlbumCard { required property var modelData; required property int index; a: modelData; kind: index === 0 ? "cookie" : "" }
            }

            // ---------------- On repeat
            Head { text: "On repeat"; visible: hm.topSongs.length > 0 }
            Grid {
                visible: hm.topSongs.length > 0
                width: parent.width
                columns: Math.max(1, Math.min(3, Math.floor(width / 300)))
                columnSpacing: 8; rowSpacing: 8
                Repeater {
                    model: hm.topSongs
                    Rectangle {
                        id: tr
                        required property var modelData
                        required property int index
                        readonly property bool now: hm.pl.cur && hm.pl.cur.path === modelData.path
                        width: (parent.width - (parent.columns - 1) * 8) / parent.columns
                        height: 68
                        radius: Theme.rL
                        color: now ? Theme.secondaryContainer : (tm.containsMouse ? Theme.surfaceHigh : Theme.surfaceC)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle {
                            id: tc
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            width: 48; height: 48; radius: Theme.rM
                            color: Theme.surfaceHighest
                            Ic { anchors.centerIn: parent; name: "music_note"; size: 22; color: Theme.inkVar }
                            Pic { anchors.fill: parent; radius: parent.radius; res: 120; source: Theme.url(tr.modelData.cover || "") }
                            Rectangle { anchors.fill: parent; radius: parent.radius; color: Qt.rgba(0, 0, 0, 0.45); visible: tm.containsMouse || tr.now
                                Ic { anchors.centerIn: parent; name: tr.now && hm.pl.playing ? "graphic_eq" : "play_arrow"; size: 24; color: "white" } }
                        }
                        Column {
                            x: tc.x + tc.width + 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - 56
                            spacing: 2
                            T { text: tr.modelData.title; font.weight: 500; width: parent.width; elide: Text.ElideRight; color: tr.now ? Theme.inkSecondaryC : Theme.ink }
                            T { role: "small"; text: tr.modelData.artist || ""; width: parent.width; elide: Text.ElideRight; color: Theme.inkVar }
                        }
                        T { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            role: "small"; color: Theme.inkVar; text: (hm.pl.hist[tr.modelData.path] || { n: 0 }).n + "×" }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (tr.now) hm.pl.toggle(); else hm.pl.playList(hm.topSongs, tr.index) }
                    }
                }
            }

            // ---------------- Recently added
            Head { text: "Recently added"; list: freshL; visible: hm.fresh.length > 0 }
            ListView {
                id: freshL
                visible: hm.fresh.length > 0
                width: parent.width; height: 236
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: hm.fresh
                Behavior on contentX { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                delegate: AlbumCard { required property var modelData; a: modelData }
            }

            // ---------------- your artists, each in a shape of its own
            Head { text: "Your artists"; list: artL; visible: hm.pl.artists.length > 0 }
            ListView {
                id: artL
                visible: hm.pl.artists.length > 0
                width: parent.width; height: 196
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: hm.pl.artists.slice().sort(function(a, b) { return b.n - a.n }).slice(0, 20)
                Behavior on contentX { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                delegate: Item {
                    id: ar
                    required property var modelData
                    required property int index
                    width: 150; height: 190
                    ShapePic {
                        id: arp
                        x: 7; y: 4; width: 136; height: 136
                        kind: hm.shapes[ar.index % hm.shapes.length]
                        source: Theme.url(ar.modelData.cover || "")
                        fill: Theme.tertiaryContainer
                        scale: am.containsMouse ? 1.05 : 1
                        rotation: am.containsMouse ? 12 : 0
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                        Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                        Ic { anchors.centerIn: parent; name: "artist"; size: 44; color: Theme.inkTertiaryC; visible: !arp.ready }
                    }
                    T { anchors.top: arp.bottom; anchors.topMargin: 8; width: parent.width; horizontalAlignment: Text.AlignHCenter
                        text: ar.modelData.name; font.weight: 500; elide: Text.ElideRight }
                    T { anchors.top: arp.bottom; anchors.topMargin: 28; width: parent.width; horizontalAlignment: Text.AlignHCenter
                        role: "small"; color: Theme.inkVar; text: ar.modelData.n + (ar.modelData.n === 1 ? " song" : " songs") }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { hm.pl.tab = "artists"; hm.pl.artist = ar.modelData.name } }
                }
            }
        }
    }

    // a section heading; with a list, two arrows move it a page at a time
    component Head: Item {
        id: hd
        property string text: ""
        property var list: null
        width: col.width; height: 52
        T { role: "headline"; text: hd.text; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; x: 4 }
        Row {
            visible: hd.list !== null && hd.list.contentWidth > hd.list.width
            anchors.right: parent.right; anchors.bottom: parent.bottom
            spacing: 6
            IconBtn { kind: "tonal"; icon: "chevron_left"; enabledBtn: hd.list && hd.list.contentX > 1
                onClicked: hd.list.contentX = Math.max(0, hd.list.contentX - hd.list.width * 0.8) }
            IconBtn { kind: "tonal"; icon: "chevron_right"; enabledBtn: hd.list && hd.list.contentX < hd.list.contentWidth - hd.list.width - 1
                onClicked: hd.list.contentX = Math.min(hd.list.contentWidth - hd.list.width, hd.list.contentX + hd.list.width * 0.8) }
        }
    }
    // an album: its cover (the first of Listen again in a cookie), a play button on hover
    component AlbumCard: Item {
        id: ac
        property var a
        property string kind: ""
        readonly property bool now: hm.pl.cur && ac.a && hm.pl.cur.album === ac.a.title && (hm.pl.cur.albumartist || hm.pl.cur.artist || "Unknown artist") === ac.a.artist
        width: 176; height: 232
        Rectangle {
            id: cv
            x: 6; y: 4
            width: 164; height: 164
            radius: Theme.rXL
            color: Theme.surfaceHigh
            visible: ac.kind === ""
            scale: cm.pressed ? 0.96 : 1
            Behavior on scale { NumberAnimation { duration: 140 } }
            Ic { anchors.centerIn: parent; name: "album"; size: 48; color: Theme.inkVar }
            Pic { anchors.fill: parent; radius: parent.radius; res: 360; source: Theme.url(ac.a ? ac.a.cover : "") }
        }
        ShapePic {
            visible: ac.kind !== ""
            x: 6; y: 4; width: 164; height: 164
            kind: ac.kind
            source: Theme.url(ac.a ? ac.a.cover : "")
            fill: Theme.primaryContainer
            RotationAnimator on rotation { from: 0; to: 360; duration: 40000; loops: Animation.Infinite; running: hm.visible && ac.kind !== "" && ac.now && hm.pl.playing }
        }
        Rectangle {
            x: cv.x + cv.width - width - 10; y: cv.y + cv.height - height - 10
            width: 48; height: 48; radius: pm.pressed ? 14 : 24
            color: Theme.primary
            opacity: cm.containsMouse || pm.containsMouse || ac.now ? 1 : 0
            scale: cm.containsMouse || pm.containsMouse || ac.now ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
            Behavior on radius { NumberAnimation { duration: 160 } }
            Ic { anchors.centerIn: parent; name: ac.now && hm.pl.playing ? "graphic_eq" : "play_arrow"; size: 28; color: Theme.inkPrimary }
            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (ac.now) hm.pl.toggle(); else hm.pl.playList(ac.a.tracks, 0) }
        }
        T { y: cv.y + cv.height + 10; x: 12; width: ac.width - 24; text: ac.a ? ac.a.title : ""; font.weight: 500; elide: Text.ElideRight }
        T { y: cv.y + cv.height + 30; x: 12; width: ac.width - 24; role: "small"; color: Theme.inkVar; text: ac.a ? ac.a.artist : ""; elide: Text.ElideRight }
        MouseArea { id: cm; anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { hm.pl.tab = "albums"; hm.pl.albumKey = ac.a.key } }
    }
}
