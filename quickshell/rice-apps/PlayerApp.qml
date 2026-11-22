import Quickshell
import Quickshell.Io
import QtQuick
import QtMultimedia

// Music and Videos (one player): your music (~/Music) and videos (~/Videos). Songs, albums and artists from the files' tags, a queue,
// shuffle and repeat, the album cover's colors over the whole app, and the bar's media controls and the media keys
// through MPRIS (rice-player-mpris).
Item {
    id: player
    objectName: "app"
    focus: true
    readonly property string appName: isVideo || tab === "videos" || tab === "video" ? "Videos" : "Music"
    readonly property string title: cur ? appName + " — " + cur.title : appName

    // ---------------------------------------------------------------- library
    property var lib: []
    property var vids: []
    property bool loading: true
    property string tab: "home"           // home, songs, albums, artists, videos
    property string albumKey: ""
    property string artist: ""
    // V4.93: a new page (a tab, an album, an artist) comes in from a little below while it fades in, and its rows and
    // covers pop in one after another (viewTick tells them)
    property real viewK: 1
    property int viewTick: 0
    NumberAnimation { id: viewA; target: player; property: "viewK"; from: 0; to: 1; duration: Theme.d(460); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
    function newView() { viewTick++; viewA.restart() }
    onTabChanged: newView()
    onAlbumKeyChanged: newView()
    onArtistChanged: newView()
    property string query: ""
    property bool theater: false          // a video fills the window

    readonly property var albums: {
        const m = {}, out = []
        for (let i = 0; i < lib.length; i++) {
            const t = lib[i], a = t.albumartist || t.artist || "Unknown artist", k = a + "|" + t.album
            if (!m[k]) { m[k] = { key: k, title: t.album || "Unknown album", artist: a, cover: t.cover || "", year: t.year || 0, tracks: [], dur: 0 }; out.push(m[k]) }
            m[k].tracks.push(t); m[k].dur += t.dur || 0
            if (!m[k].cover && t.cover) m[k].cover = t.cover
        }
        out.sort(function(x, y) { return x.title.localeCompare(y.title, undefined, { sensitivity: "base" }) })
        return out
    }
    readonly property var artists: {
        const m = {}, out = []
        for (let i = 0; i < lib.length; i++) {
            const t = lib[i], a = t.albumartist || t.artist || "Unknown artist"
            if (!m[a]) { m[a] = { name: a, cover: t.cover || "", albums: {}, n: 0 }; out.push(m[a]) }
            m[a].n++; m[a].albums[t.album] = true
            if (!m[a].cover && t.cover) m[a].cover = t.cover
        }
        out.sort(function(x, y) { return x.name.localeCompare(y.name, undefined, { sensitivity: "base" }) })
        return out
    }
    function albumOf(k) { for (let i = 0; i < albums.length; i++) if (albums[i].key === k) return albums[i]; return null }
    function match(t) {
        if (query === "") return true
        const q = query.toLowerCase()
        return (t.title || "").toLowerCase().indexOf(q) >= 0 || (t.artist || "").toLowerCase().indexOf(q) >= 0 || (t.album || "").toLowerCase().indexOf(q) >= 0
    }
    readonly property var songs: lib.filter(match)
    // what you played: path -> { n: times, t: last time } (Home: Listen again, your top songs)
    property var hist: ({})
    function played(t) {
        if (!t || t.vid || !t.path) return
        const h = Object.assign({}, hist)
        const e = h[t.path] || { n: 0, t: 0 }
        h[t.path] = { n: e.n + 1, t: Date.now() }
        // the 400 last ones are kept
        const keys = Object.keys(h)
        if (keys.length > 400) keys.sort(function(a, b) { return h[a].t - h[b].t }).slice(0, keys.length - 400).forEach(function(k) { delete h[k] })
        hist = h
        saveT.restart()
    }
    readonly property var byPath: { const m = {}; for (let i = 0; i < lib.length; i++) m[lib[i].path] = lib[i]; return m }
    readonly property int libDur: { let d = 0; for (let i = 0; i < lib.length; i++) d += lib[i].dur || 0; return d }
    readonly property var artistSongs: artist === "" ? [] : lib.filter(function(t) { return (t.albumartist || t.artist || "Unknown artist") === player.artist })
    readonly property var artistAlbums: artist === "" ? [] : albums.filter(function(a) { return a.artist === player.artist })

    function load() {
        loading = true
        Sys.run(["music"], function(r) { player.loading = false; if (r) player.lib = r.items || []; player.restoreLast() })
        Sys.run(["videos"], function(r) { if (r) player.vids = r.items || [] })
    }

    // ---------------------------------------------------------------- the queue
    property var queue: []
    property var order: []
    property int oi: -1
    property bool shuffle: false
    property string repeat: "off"         // off, all, one
    property real vol: 0.8
    property bool muted: false
    property bool dynColor: true
    property bool prefsLoaded: false
    property var last: null
    readonly property var cur: oi >= 0 && oi < order.length ? queue[order[oi]] : null
    readonly property bool isVideo: !!(cur && (cur.vid || /\.(mp4|mkv|webm|mov|avi|m4v|ogv|flv|wmv)$/i.test(cur.path)))
    readonly property bool playing: mp.playbackState === MediaPlayer.PlayingState
    readonly property real pos: mp.position / 1000
    readonly property real len: mp.duration > 0 ? mp.duration / 1000 : (cur ? cur.dur || 0 : 0)
    readonly property var upNext: { const l = []; for (let i = oi + 1; i < order.length && l.length < 60; i++) l.push({ t: queue[order[i]], at: i }); return l }

    function makeOrder(n, first) {
        const o = []
        for (let i = 0; i < n; i++) o.push(i)
        if (shuffle) {
            for (let i = o.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); const x = o[i]; o[i] = o[j]; o[j] = x }
            const k = o.indexOf(first); if (k > 0) { o.splice(k, 1); o.unshift(first) }
        }
        return o
    }
    function playList(list, i, shuf) {
        if (!list || list.length === 0) return
        started = true
        if (shuf !== undefined) shuffle = shuf
        if (shuf === true) i = Math.floor(Math.random() * list.length)
        queue = list.slice()
        order = makeOrder(queue.length, i)
        oi = order.indexOf(i)
        loadCur(true)
    }
    function loadCur(autoplay) {
        if (!cur) { mp.stop(); return }
        mp.source = Theme.url(cur.path)
        if (autoplay) { mp.play(); played(cur) }
        if (isVideo && !theater && tab !== "video") { lastTab = tab; tab = "video" }
        if (!isVideo && tab === "video") tab = lastTab
        coverColor.take(cur.cover || "")
        saveT.restart()
        pushState(true)
    }
    property string lastTab: "home"
    function next(auto) {
        if (order.length === 0) return
        if (auto && repeat === "one") { mp.position = 0; mp.play(); return }
        if (oi + 1 < order.length) oi++
        else if (repeat === "all" || !auto) { oi = 0; if (shuffle) order = makeOrder(queue.length, order[0]) }
        else { mp.stop(); mp.position = 0; pushState(); return }
        loadCur(true)
    }
    function prev() {
        if (order.length === 0) return
        if (pos > 3) { mp.position = 0; pushState(false, true); return }
        if (oi > 0) oi--
        else if (repeat === "all") oi = order.length - 1
        else { mp.position = 0; return }
        loadCur(true)
    }
    function toggle() { if (!cur) { if (lib.length > 0) playList(lib, 0); return } if (playing) mp.pause(); else mp.play() }
    function jump(at) { oi = at; loadCur(true) }
    function setShuffle(on) {
        shuffle = on
        if (queue.length > 0 && oi >= 0) { const c = order[oi]; order = makeOrder(queue.length, c); if (!on) oi = c; else oi = 0 }
        saveT.restart(); pushState()
    }
    function cycleRepeat() { repeat = repeat === "off" ? "all" : (repeat === "all" ? "one" : "off"); saveT.restart(); pushState() }
    function addNext(t) {
        if (!cur) { playList([t], 0); return }
        const q = queue.concat([t]), o = order.slice()
        o.splice(oi + 1, 0, q.length - 1)
        queue = q; order = o
        Ui.snack("Plays next: " + t.title)
    }
    function addEnd(list) {
        if (!cur) { playList(list, 0); return }
        const q = queue.slice(), o = order.slice()
        for (let i = 0; i < list.length; i++) { q.push(list[i]); o.push(q.length - 1) }
        queue = q; order = o
        Ui.snack(list.length === 1 ? "Added to the queue: " + list[0].title : list.length + " added to the queue")
    }
    function removeAt(at) {
        if (at === oi) return
        const o = order.slice(); o.splice(at, 1)
        order = o
        if (at < oi) oi--
    }
    function seekTo(s) { mp.position = Math.max(0, Math.min(len, s)) * 1000; pushState(false, true) }
    function seekBy(d) { seekTo(pos + d) }
    function setVol(v) { vol = Math.max(0, Math.min(1, v)); muted = false; saveT.restart(); pushState() }

    // files given to rice-app player (or sent to this one while it runs)
    function openFiles(paths) {
        if (paths.length === 0) return
        Sys.run(["tracks"].concat(paths), function(r) {
            if (!r || r.length === 0) { Ui.snack("Nothing here can be played"); return }
            player.playList(r, 0, false)
        })
    }
    function start(args) {
        Sys.run(["prefs", "player", "get"], function(j) {
            j = j || {}
            if (j.vol !== undefined) player.vol = j.vol
            player.shuffle = j.shuffle === true
            player.repeat = j.repeat || "off"
            player.dynColor = j.dynColor !== false
            player.last = j.last || null
            player.hist = j.hist || ({})
            player.prefsLoaded = true
            player.restoreLast()
        })
        load()
        if (Quickshell.env("RICE_TAB") === "videos") tab = "videos"
        else if (["home", "songs", "albums", "artists"].indexOf(Quickshell.env("RICE_TAB")) >= 0) tab = Quickshell.env("RICE_TAB")
        if (args && args.length > 0) { started = true; openFiles(args) }
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$HOME/.cache/rice\"; echo \"$PPID\" > \"$HOME/.cache/rice/player-pid\""])
    }
    property bool started: false
    // the song you heard last, ready (not playing) where you stopped
    function restoreLast() {
        if (started || !prefsLoaded || loading || !last || !last.path) return
        started = true
        const i = lib.findIndex(function(t) { return t.path === player.last.path })
        if (i < 0) return
        queue = lib.slice(); order = makeOrder(queue.length, i); oi = order.indexOf(i)
        mp.source = Theme.url(cur.path)
        resumeAt = last.pos || 0
        coverColor.take(cur.cover || "")
        pushState(true)
    }
    property real resumeAt: 0
    Timer { id: saveT; interval: 1500; onTriggered: player.savePrefs() }
    Timer { interval: 10000; repeat: true; running: player.playing; onTriggered: player.savePrefs() }
    function savePrefs() {
        if (!prefsLoaded) return
        Sys.savePrefs("player", { vol: vol, shuffle: shuffle, repeat: repeat, dynColor: dynColor,
                                  last: cur && !isVideo ? { path: cur.path, pos: Math.floor(pos) } : last, hist: hist })
    }
    FileView {
        path: Theme.home + "/.cache/rice/player-open"
        watchChanges: true
        printErrors: false
        property bool primed: false
        onFileChanged: reload()
        onLoaded: {
            const l = text().split("\n")
            if (!primed) { primed = true; return }
            const files = l.slice(1).filter(function(x) { return x !== "" })
            // "TIME TAB": Videos opened again shows the videos
            if (files.length === 0 && (l[0].split(" ")[1] || "") === "videos" && player.tab !== "video") { player.tab = "videos"; player.albumKey = ""; player.artist = "" }
            player.openFiles(files)
        }
        onLoadFailed: primed = true
    }

    // ---------------------------------------------------------------- playing
    MediaPlayer {
        id: mp
        audioOutput: AudioOutput { id: ao; volume: player.muted ? 0 : Math.pow(player.vol, 2) }
        videoOutput: video
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) player.next(true)
            if (mediaStatus === MediaPlayer.LoadedMedia && player.resumeAt > 0) { position = player.resumeAt * 1000; player.resumeAt = 0 }
        }
        onPlaybackStateChanged: player.pushState()
        onDurationChanged: player.pushState()
        onErrorOccurred: function(e, s) { Ui.snack("It cannot be played: " + s) }
    }
    // the cover's main color (the whole app takes it)
    Canvas {
        id: coverColor
        width: 12; height: 12
        visible: false
        property string src: ""
        function take(f) {
            if (!player.dynColor || f === "") { Theme.dyn = ""; src = ""; return }
            const u = Theme.url(f)
            if (u === src) return
            src = u
            if (isImageLoaded(u)) requestPaint(); else loadImage(u)
        }
        onImageLoaded: requestPaint()
        onPaint: {
            if (src === "" || !isImageLoaded(src)) return
            const c = getContext("2d")
            c.clearRect(0, 0, 12, 12)
            c.drawImage(src, 0, 0, 12, 12)
            const d = c.getImageData(0, 0, 12, 12).data
            let best = null, bs = -1
            for (let i = 0; i < d.length; i += 4) {
                const r = d[i] / 255, g = d[i + 1] / 255, b = d[i + 2] / 255
                const mx = Math.max(r, g, b), mn = Math.min(r, g, b), s = mx === 0 ? 0 : (mx - mn) / mx
                const score = s * 0.8 + mx * 0.35 - (mx < 0.15 ? 1 : 0)
                if (score > bs) { bs = score; best = [r, g, b] }
            }
            if (best) Theme.dyn = Qt.rgba(best[0], best[1], best[2], 1).toString()
            unloadImage(src)      // V4.96: every cover stayed in memory after its color was taken
        }
    }
    onDynColorChanged: { if (!dynColor) Theme.dyn = ""; else if (cur) { coverColor.src = ""; coverColor.take(cur.cover || "") } saveT.restart() }

    // MPRIS: the bar, the island, the lock screen and the media keys
    Process {
        id: mpris
        command: ["python3", Theme.home + "/.local/bin/rice-player-mpris"]
        running: true
        stdinEnabled: true
        stdout: SplitParser {
            onRead: function(l) {
                const w = l.split(" ")
                switch (w[0]) {
                case "play": if (!player.playing) player.toggle(); break
                case "pause": mp.pause(); break
                case "toggle": player.toggle(); break
                case "stop": mp.stop(); break
                case "next": player.next(false); break
                case "prev": player.prev(); break
                case "seek": player.seekBy(parseFloat(w[1])); break
                case "pos": player.seekTo(parseFloat(w[1])); break
                case "vol": player.setVol(Math.sqrt(parseFloat(w[1]))); break
                case "shuffle": player.setShuffle(w[1] === "1"); break
                case "loop": player.repeat = w[1] === "Track" ? "one" : (w[1] === "Playlist" ? "all" : "off"); player.pushState(); break
                case "quit": Qt.quit(); break
                case "open": player.openFiles([decodeURIComponent(l.substring(5).replace(/^file:\/\//, ""))]); break
                }
            }
        }
    }
    function pushState(track, seeked) {
        if (!mpris.running) return
        const c = cur, o = { status: !c ? "Stopped" : (playing ? "Playing" : (mp.playbackState === MediaPlayer.PausedState || c ? "Paused" : "Stopped")),
                             pos: pos, len: len, vol: muted ? 0 : Math.pow(vol, 2), shuffle: shuffle,
                             loop: repeat === "one" ? "Track" : (repeat === "all" ? "Playlist" : "None"),
                             canNext: oi + 1 < order.length || repeat === "all", canPrev: true }
        if (track !== false && c) {
            o.title = c.title || ""; o.artist = c.artist || ""; o.album = c.album || ""
            o.art = c.cover ? Theme.url(c.cover) : ""; o.url = Theme.url(c.path); o.id = oi + 1
        }
        if (seeked) o.seeked = true
        mpris.write(JSON.stringify(o) + "\n")
    }
    Timer { interval: 5000; repeat: true; running: player.playing; onTriggered: player.pushState(false) }

    // ---------------------------------------------------------------- the keyboard
    Keys.onPressed: function(k) {
        if (Ui.busy()) return
        const ctrl = k.modifiers & Qt.ControlModifier
        if (k.key === Qt.Key_Space || k.key === Qt.Key_MediaTogglePlayPause || k.key === Qt.Key_K) toggle()
        else if (ctrl && k.key === Qt.Key_Right || k.key === Qt.Key_MediaNext) next(false)
        else if (ctrl && k.key === Qt.Key_Left || k.key === Qt.Key_MediaPrevious) prev()
        else if (k.key === Qt.Key_Right || k.key === Qt.Key_L) seekBy(isVideo ? 10 : 5)
        else if (k.key === Qt.Key_Left || k.key === Qt.Key_J) seekBy(isVideo ? -10 : -5)
        else if (ctrl && k.key === Qt.Key_Up || k.key === Qt.Key_Plus || k.key === Qt.Key_Equal) setVol(vol + 0.05)
        else if (ctrl && k.key === Qt.Key_Down || k.key === Qt.Key_Minus) setVol(vol - 0.05)
        else if (k.key === Qt.Key_M) muted = !muted
        else if (k.key === Qt.Key_S) setShuffle(!shuffle)
        else if (k.key === Qt.Key_R) cycleRepeat()
        else if (k.key === Qt.Key_F && isVideo) theater = !theater
        else if (ctrl && k.key === Qt.Key_F) { if (tab === "home" || tab === "video") tab = "songs"; Qt.callLater(libv.findNow) }
        else if (k.key === Qt.Key_Escape) { if (theater) theater = false; else if (albumKey !== "" || artist !== "") { albumKey = ""; artist = "" } else if (query !== "") libv.clearFind() }
        else return
        k.accepted = true
    }

    // ---------------------------------------------------------------- the window
    readonly property bool wide: width >= 1040
    Rail {
        id: rail
        visible: !player.theater
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: visible ? 88 : 0
        value: player.tab === "video" ? "" : player.tab
        items: [{ key: "home", icon: "home", text: "Home" }, { key: "songs", icon: "music_note", text: "Songs" }, { key: "albums", icon: "album", text: "Albums" },
                { key: "artists", icon: "artist", text: "Artists" }, { key: "videos", icon: "smart_display", text: "Videos" }]
        fabIcon: "shuffle"
        fabTip: "Shuffle all your music"
        onFab: player.playList(player.lib, 0, true)
        onPicked: function(k) { player.tab = k; player.albumKey = ""; player.artist = ""; player.forceActiveFocus() }
        mark: [AppIcon { app: player.appName === "Videos" ? "videos" : "music"; width: 44; height: 44; anchors.centerIn: parent
            Rectangle { anchors.centerIn: parent; width: 40; height: 40; radius: 20; color: Theme.primary
                Ic { anchors.centerIn: parent; name: "graphic_eq"; size: 24; color: Theme.inkPrimary } } }]
    }
    Rectangle {
        id: pane
        anchors.left: rail.right
        anchors.right: panel.visible ? panel.left : parent.right
        anchors.rightMargin: player.theater ? 0 : 8
        anchors.top: parent.top; anchors.topMargin: player.theater ? 0 : 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: player.theater ? 0 : 8
        radius: player.theater ? 0 : Theme.rXL
        color: player.tab === "video" ? "#000000" : Theme.surfaceLow
        clip: true
        Behavior on color { ColorAnimation { duration: 300 } }

        PlayerLibrary { id: libv; pl: player; anchors.fill: parent; anchors.bottomMargin: mini.visible ? mini.height + 8 : 0; visible: player.tab !== "video" && player.tab !== "home"
            opacity: player.viewK; transform: Translate { y: 22 * (1 - player.viewK) } }
        PlayerHome { id: homev; pl: player; anchors.fill: parent; anchors.bottomMargin: mini.visible ? mini.height + 8 : 0; visible: player.tab === "home"
            opacity: player.viewK; transform: Translate { y: 22 * (1 - player.viewK) } }
        VideoStage { id: stage; pl: player; anchors.fill: parent; visible: player.tab === "video" }
        MiniPlayer { id: mini; pl: player; visible: !player.wide && player.cur !== null && player.tab !== "video"; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8
            onOpen: full.open = true }
    }
    NowPlaying {
        id: panel
        pl: player
        visible: player.wide && !player.theater && player.cur !== null
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.top: parent.top; anchors.topMargin: 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        width: 360
    }
    // narrow windows: Now playing over everything
    Item {
        id: full
        property bool open: false
        width: parent.width; height: parent.height
        visible: y < height
        y: open && !player.wide ? 0 : height
        Behavior on y { NumberAnimation { duration: Theme.d(420); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        Rectangle { anchors.fill: parent; color: Theme.surface }
        NowPlaying { pl: player; anchors.fill: parent; anchors.margins: 8; full: true; onClose: full.open = false }
    }
    // a hidden video sink when the stage is not shown (the player always has one)
    property alias video: stage.output
}
