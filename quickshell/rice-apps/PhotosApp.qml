import Quickshell
import QtQuick
import Qt.labs.folderlistmodel

// Photos: your pictures (and screen recordings) by day or month, albums from their folders, favorites,
// and a viewer with zoom, the details of a picture, a slideshow and "set as wallpaper".
Item {
    id: photos
    objectName: "app"
    focus: true
    readonly property string title: viewer.open ? "Photos — " + viewer.name : "Photos"

    property var all: []
    property string root: ""
    property bool loading: true
    property string tab: "photos"         // photos, albums, favs, videos
    property string album: ""
    property var favs: []
    property int tile: 150
    property var sel: ({})
    property int selN: 0
    property var thumbs: ({})
    property bool prefsLoaded: false
    readonly property bool selecting: selN > 0

    function start(args) {
        Sys.run(["prefs", "photos", "get"], function(j) {
            j = j || {}
            photos.favs = j.favs || []
            if (j.tile) photos.tile = Math.max(80, Math.min(320, j.tile))
            photos.prefsLoaded = true
        })
        load()
        const a = args && args.length > 0 ? args[0] : ""
        if (a !== "") Sys.run(["stat", a], function(r) {
            if (!r || r.length === 0) return
            if (r[0].fileIsDir) { folder.dir = r[0].filePath; folder.openAt = "" }
            else { folder.dir = r[0].filePath.replace(/\/[^\/]*$/, "") || "/"; folder.openAt = r[0].filePath }
        })
    }
    function load() {
        loading = true
        Sys.run(["photos"], function(r) {
            photos.loading = false
            if (!r) return
            photos.root = r.root
            photos.all = r.items || []
        })
    }
    function savePrefs() { if (prefsLoaded) saveT.restart() }
    Timer { id: saveT; interval: 600; onTriggered: Sys.savePrefs("photos", { favs: photos.favs, tile: photos.tile }) }
    onTileChanged: savePrefs()

    // a picture or a folder given to rice-app photos: its folder's pictures, the viewer on that one
    FolderListModel {
        id: folder
        property string dir: ""
        property string openAt: ""
        folder: dir !== "" ? Theme.url(dir) : ""
        showDirs: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp", "*.avif", "*.tif", "*.tiff", "*.jxl", "*.svg", "*.heic",
                      "*.JPG", "*.JPEG", "*.PNG", "*.WEBP", "*.GIF"]
        sortField: FolderListModel.Name
        onStatusChanged: if (status === FolderListModel.Ready && dir !== "") Qt.callLater(photos.openFolder)
    }
    function openFolder() {
        const l = []
        for (let i = 0; i < folder.count; i++) l.push({ path: folder.get(i, "filePath"), t: folder.get(i, "fileModified").getTime(), size: folder.get(i, "fileSize"), dir: folder.dir, video: false })
        if (folder.openAt !== "") {
            let i = l.findIndex(function(x) { return x.path === folder.openAt })
            if (i < 0) { l.unshift({ path: folder.openAt, t: Date.now(), size: 0, dir: folder.dir, video: false }); i = 0 }
            viewer.show(l, i)
        } else { tab = "albums"; album = folder.dir }
        folder.dir = ""
    }

    // ---------------------------------------------------------------- what is shown
    function isFav(p) { return favs.indexOf(p) >= 0 }
    readonly property var shown: {
        const f = favs
        let l = all
        if (album !== "") l = l.filter(function(x) { return x.dir === album })
        else if (tab === "favs") l = l.filter(function(x) { return f.indexOf(x.path) >= 0 })
        else if (tab === "videos") l = l.filter(function(x) { return x.video })
        return l
    }
    readonly property var albums: {
        const m = {}, order = []
        for (let i = 0; i < all.length; i++) {
            const x = all[i]
            if (!m[x.dir]) { m[x.dir] = { dir: x.dir, n: 0, cover: x.path, coverVideo: x.video, t: x.t }; order.push(x.dir) }
            m[x.dir].n++
        }
        return order.map(function(d) { return m[d] })
    }
    function albumName(d) {
        if (d === root) return "Pictures"
        return d.replace(/\/+$/, "").replace(/^.*\//, "")
    }
    // the rows of the timeline: a heading for each day (or month), then rows of pictures
    readonly property int cols: Math.max(2, Math.floor((grid.width + 4) / tile))
    readonly property real cell: (grid.width - (cols - 1) * 4) / cols
    readonly property var rows: {
        const l = shown, out = [], byDay = tile >= 120
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        const now = new Date(), t0 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
        let key = "", group = []
        function flush() {
            if (group.length === 0) return
            for (let i = 0; i < group.length; i += cols) out.push({ k: "r", items: group.slice(i, i + cols) })
            group = []
        }
        for (let i = 0; i < l.length; i++) {
            const d = new Date(l[i].t)
            const k = byDay ? d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate() : d.getFullYear() + "-" + d.getMonth()
            if (k !== key) {
                flush()
                key = k
                let text
                if (byDay) {
                    const day = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
                    text = day === t0 ? "Today" : (day === t0 - 86400000 ? "Yesterday" : Qt.formatDate(d, d.getFullYear() === now.getFullYear() ? "dddd, d MMMM" : "d MMMM yyyy"))
                } else text = months[d.getMonth()] + (d.getFullYear() === now.getFullYear() ? "" : " " + d.getFullYear())
                out.push({ k: "h", text: text, first: i })
            }
            group.push(i)
        }
        flush()
        return out
    }

    // ---------------------------------------------------------------- selection, favorites, actions
    function clearSel() { sel = ({}); selN = 0 }
    function toggle(p) { const s = Object.assign({}, sel); if (s[p]) delete s[p]; else s[p] = true; sel = s; selN = Object.keys(s).length }
    function selectAll() { const s = {}; for (let i = 0; i < shown.length; i++) s[shown[i].path] = true; sel = s; selN = shown.length }
    function selPaths() { return shown.filter(function(x) { return photos.sel[x.path] }).map(function(x) { return x.path }) }
    function fav(paths, on) {
        let f = favs.filter(function(p) { return paths.indexOf(p) < 0 })
        if (on) f = paths.concat(f)
        favs = f
        savePrefs()
    }
    function trash(paths, after) {
        if (paths.length === 0) return
        Sys.run(["trash"].concat(paths), function(r) {
            if (!r) return
            if (r.error) { Ui.snack(r.error); return }
            const gone = {}; for (let i = 0; i < paths.length; i++) gone[paths[i]] = true
            const kept = photos.all, back = kept.filter(function(x) { return gone[x.path] })
            photos.all = kept.filter(function(x) { return !gone[x.path] })
            if (after) after()
            Ui.snack(r.n === 1 ? "Moved to the trash" : r.n + " moved to the trash", "Undo", function() {
                Sys.run(["restore"].concat(r.names || []), function(x) { if (x && x.ok) photos.load() })
            })
        })
    }
    function wallpaper(p) {
        Sys.sh('exec bash "$HOME/.config/quickshell/hyprquickpaper/commands.sh" "$1"', [p])
        Ui.snack("Wallpaper set: the colors follow it")
    }
    function copyImage(p) { Sys.sh('wl-copy < "$1"', [p]); Ui.snack("Picture copied") }
    function showInFiles(p) { Sys.app("files", [p]) }
    function edit(p) {
        Sys.sh('for e in satty swappy gimp krita pinta; do command -v "$e" >/dev/null 2>&1 || continue; case "$e" in satty) exec satty --filename "$1" --output-filename "$1" ;; swappy) exec swappy -f "$1" -o "$1" ;; *) exec "$e" "$1" ;; esac; done; notify-send "Photos" "Install an editor (satty, swappy, GIMP, Krita or Pinta) to edit pictures"', [p])
    }
    function openItem(i) {
        const x = shown[i]
        viewer.show(shown, i)
    }
    function tileMenu(x, src, mx, my) {
        const many = selecting && sel[x.path]
        const ps = many ? selPaths() : [x.path]
        const f = isFav(x.path)
        Ui.menu([
            { icon: "open_in_full", text: "Open", act: function() { photos.openItem(photos.shown.indexOf(x)) } },
            { icon: f ? "heart_minus" : "favorite", text: f ? "Not a favorite" : "Favorite", act: function() { photos.fav(ps, !f) } },
            { icon: "check_circle", text: many ? "Unselect" : "Select", act: function() { photos.toggle(x.path) } },
            { sep: true },
            !x.video && !many ? { icon: "wallpaper", text: "Set as wallpaper", act: function() { photos.wallpaper(x.path) } } : null,
            !x.video && !many ? { icon: "content_copy", text: "Copy the picture", act: function() { photos.copyImage(x.path) } } : null,
            !x.video && !many ? { icon: "edit", text: "Edit", act: function() { photos.edit(x.path) } } : null,
            { icon: "folder_open", text: "Show in Files", act: function() { photos.showInFiles(x.path) } },
            { sep: true },
            { icon: "delete", text: many ? "Move " + ps.length + " to the trash" : "Move to the trash", danger: true, act: function() { photos.trash(ps); photos.clearSel() } }
        ], src, mx, my)
    }
    function uris(x) {
        const ps = selecting && sel[x.path] ? selPaths() : [x.path]
        return ps.map(function(p) { return Theme.url(p) }).join("\r\n") + "\r\n"
    }
    // pictures of videos (the helper makes them)
    property var want: []
    property var asked: ({})
    function needThumb(p) { if (thumbs[p] !== undefined || asked[p]) return; asked[p] = true; want.push(p); thumbT.restart() }
    Timer { id: thumbT; interval: 150; onTriggered: { if (photos.want.length === 0) return; const l = photos.want.splice(0, 16)
            Sys.run(["thumbs"].concat(l), function(r) { if (!r) return; const t = Object.assign({}, photos.thumbs); for (const k in r) t[k] = r[k]; photos.thumbs = t })
            if (photos.want.length > 0) thumbT.restart() } }

    Keys.onPressed: function(k) {
        if (Ui.busy() || viewer.open) return
        const ctrl = k.modifiers & Qt.ControlModifier
        if (k.key === Qt.Key_Escape) { if (selecting) clearSel(); else if (album !== "") album = ""; k.accepted = true }
        else if (ctrl && k.key === Qt.Key_A) { selectAll(); k.accepted = true }
        else if (k.key === Qt.Key_Delete && selecting) { trash(selPaths()); clearSel(); k.accepted = true }
        else if ((ctrl && (k.key === Qt.Key_Plus || k.key === Qt.Key_Equal)) || k.key === Qt.Key_Plus) { tile = Math.min(320, tile + 30); k.accepted = true }
        else if ((ctrl && k.key === Qt.Key_Minus) || k.key === Qt.Key_Minus) { tile = Math.max(80, tile - 30); k.accepted = true }
        else if (k.key === Qt.Key_F5) { load(); k.accepted = true }
    }

    // ---------------------------------------------------------------- the window
    Rail {
        id: rail
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        value: photos.album !== "" ? "albums" : photos.tab
        items: [{ key: "photos", icon: "photo_library", text: "Photos" }, { key: "albums", icon: "photo_album", text: "Albums" },
                { key: "favs", icon: "favorite", text: "Favorites" }, { key: "videos", icon: "movie", text: "Videos" }]
        onPicked: function(k) { photos.tab = k; photos.album = ""; photos.clearSel(); grid.contentY = grid.originY; albumGrid.contentY = albumGrid.originY }
        mark: [AppIcon { app: "photos"; width: 44; height: 44; anchors.centerIn: parent
            Rectangle { anchors.centerIn: parent; width: 40; height: 40; radius: 14; color: Theme.tertiary
                Ic { anchors.centerIn: parent; name: "photo"; size: 24; color: Theme.inkPrimary } } }]
    }
    Rectangle {
        id: pane
        anchors.left: rail.right
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.top: parent.top; anchors.topMargin: 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        radius: Theme.rXL
        color: Theme.surfaceLow
        clip: true

        // the heading, or what to do with the chosen ones
        Item {
            id: head
            width: parent.width; height: 96
            Item {
                anchors.fill: parent
                visible: !photos.selecting
                IconBtn { id: backB; visible: photos.album !== ""; x: 16; anchors.verticalCenter: parent.verticalCenter; icon: "arrow_back"; onClicked: photos.album = "" }
                Column {
                    x: photos.album !== "" ? 68 : 28
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    T { role: "display"; font.pixelSize: 30
                        text: photos.album !== "" ? photos.albumName(photos.album) : ({ photos: "Photos", albums: "Albums", favs: "Favorites", videos: "Videos" })[photos.tab] }
                    T { color: Theme.inkVar; role: "label"; font.weight: 400
                        text: photos.loading ? "Looking for your pictures …" : (photos.tab === "albums" && photos.album === "" ? photos.albums.length + " albums"
                              : photos.shown.length + (photos.shown.length === 1 ? " item" : " items")) }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    IconBtn { icon: "zoom_out"; tip: "Smaller (−)"; onClicked: photos.tile = Math.max(80, photos.tile - 30) }
                    IconBtn { icon: "zoom_in"; tip: "Bigger (+)"; onClicked: photos.tile = Math.min(320, photos.tile + 30) }
                    IconBtn { icon: "refresh"; tip: "Look again (F5)"; onClicked: photos.load() }
                    IconBtn { icon: "folder_open"; tip: "Open the folder in Files"; onClicked: Sys.app("files", [photos.album !== "" ? photos.album : (photos.root || Theme.home)]) }
                }
            }
            Rectangle {
                anchors.fill: parent; anchors.margins: 12
                radius: 36
                color: Theme.secondaryContainer
                visible: photos.selecting
                IconBtn { x: 10; anchors.verticalCenter: parent.verticalCenter; icon: "close"; ink: Theme.inkSecondaryC; onClicked: photos.clearSel() }
                T { x: 62; anchors.verticalCenter: parent.verticalCenter; role: "title"; color: Theme.inkSecondaryC; text: photos.selN + " selected" }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    IconBtn { icon: "select_all"; tip: "All (Ctrl + A)"; ink: Theme.inkSecondaryC; onClicked: photos.selectAll() }
                    IconBtn { icon: "favorite"; tip: "Favorite"; ink: Theme.inkSecondaryC; onClicked: { photos.fav(photos.selPaths(), true); Ui.snack("Added to Favorites") } }
                    IconBtn { icon: "content_copy"; tip: "Copy (as files)"; ink: Theme.inkSecondaryC; onClicked: Sys.run(["clip", "copy"].concat(photos.selPaths()), function() { Ui.snack("Copied: paste them in Files or another app") }) }
                    IconBtn { icon: "delete"; tip: "Move to the trash (Delete)"; ink: Theme.inkSecondaryC; onClicked: { photos.trash(photos.selPaths()); photos.clearSel() } }
                }
            }
        }

        // the timeline
        ListView {
            id: grid
            anchors.top: head.bottom
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            visible: !(photos.tab === "albums" && photos.album === "")
            model: visible ? photos.rows : []
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 600
            bottomMargin: 24
            reuseItems: true
            flickDeceleration: 4000
            maximumFlickVelocity: 6000
            delegate: Item {
                id: rowD
                required property var modelData
                width: grid.width
                height: modelData.k === "h" ? 52 : photos.cell + 4
                T {
                    visible: rowD.modelData.k === "h"
                    y: 18
                    text: rowD.modelData.text || ""
                    role: "title"
                    font.weight: 600
                }
                // choose a whole day at once
                IconBtn {
                    visible: rowD.modelData.k === "h" && photos.selecting
                    anchors.right: parent.right; y: 10
                    icon: "done_all"; tip: "Choose this day"
                    onClicked: { let i = rowD.modelData.first; const s = Object.assign({}, photos.sel); const r = photos.rows; const at = r.indexOf(rowD.modelData)
                                 for (let k = at + 1; k < r.length && r[k].k === "r"; k++) for (let j = 0; j < r[k].items.length; j++) s[photos.shown[r[k].items[j]].path] = true
                                 photos.sel = s; photos.selN = Object.keys(s).length }
                }
                Row {
                    visible: rowD.modelData.k === "r"
                    spacing: 4
                    Repeater {
                        model: rowD.modelData.k === "r" ? rowD.modelData.items : []
                        PhotoTile { required property var modelData; ph: photos; i: modelData; size: photos.cell }
                    }
                }
            }
            WheelHandler {
                acceptedModifiers: Qt.ControlModifier
                onWheel: function(w) { photos.tile = Math.max(80, Math.min(320, photos.tile + (w.angleDelta.y > 0 ? 20 : -20))) }
            }
        }
        VScroll { flick: grid; visible: grid.visible && ratio < 0.999; anchors.right: parent.right; anchors.top: grid.top; anchors.bottom: grid.bottom }

        // the albums
        GridView {
            id: albumGrid
            anchors.top: head.bottom
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            visible: photos.tab === "albums" && photos.album === ""
            model: visible ? photos.albums : []
            readonly property int n: Math.max(2, Math.floor(width / 210))
            cellWidth: Math.floor(width / n)
            cellHeight: cellWidth + 56
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: al
                required property var modelData
                width: albumGrid.cellWidth; height: albumGrid.cellHeight
                Rectangle {
                    id: cov
                    x: 8; y: 8
                    width: parent.width - 16; height: width
                    radius: Theme.rXL
                    color: Theme.surfaceHigh
                    scale: am.pressed ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: 140 } }
                    Pic { anchors.fill: parent; radius: parent.radius; res: 400
                          source: Theme.url(al.modelData.coverVideo ? (photos.thumbs[al.modelData.cover] || "") : al.modelData.cover)
                          Component.onCompleted: if (al.modelData.coverVideo) photos.needThumb(al.modelData.cover) }
                    Rectangle { anchors.fill: parent; radius: parent.radius; color: Theme.ink; opacity: am.containsMouse ? 0.08 : 0 }
                }
                T { x: 12; anchors.top: cov.bottom; anchors.topMargin: 8; width: parent.width - 24; text: photos.albumName(al.modelData.dir); role: "title"; font.pixelSize: 15 }
                T { x: 12; anchors.top: cov.bottom; anchors.topMargin: 30; text: al.modelData.n + (al.modelData.n === 1 ? " item" : " items"); role: "small"; color: Theme.inkVar }
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(m) {
                        if (m.button === Qt.RightButton) Ui.menu([{ icon: "folder_open", text: "Open in Files", act: function() { Sys.app("files", [al.modelData.dir]) } }], am, m.x, m.y)
                        else { photos.album = al.modelData.dir; grid.contentY = grid.originY }
                    } }
            }
        }
        VScroll { flick: albumGrid; visible: albumGrid.visible && ratio < 0.999; anchors.right: parent.right; anchors.top: albumGrid.top; anchors.bottom: albumGrid.bottom }

        // nothing yet
        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: !photos.loading && (photos.tab === "albums" && photos.album === "" ? photos.albums.length === 0 : photos.shown.length === 0)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 112; height: 112; radius: 40; rotation: -8
                color: Theme.surfaceC
                Ic { anchors.centerIn: parent; rotation: 8; size: 52; color: Theme.primary
                     name: photos.tab === "favs" ? "favorite" : (photos.tab === "videos" ? "movie" : "add_photo_alternate") }
            }
            T { anchors.horizontalCenter: parent.horizontalCenter; role: "title"
                text: photos.tab === "favs" ? "No favorites yet" : (photos.tab === "videos" ? "No videos here" : "No pictures yet") }
            T { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.inkVar
                text: photos.tab === "favs" ? "The heart on a picture puts it here" : "Pictures in " + (photos.root || "~/Pictures").replace(Theme.home, "~") + " show up here" }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 56; height: 56; radius: 28
            color: Theme.surfaceHigh
            visible: photos.loading
            Ic { anchors.centerIn: parent; name: "progress_activity"; size: 28; color: Theme.primary
                 RotationAnimation on rotation { running: photos.loading; from: 0; to: 360; duration: 900; loops: Animation.Infinite } }
        }
    }
    PhotoViewer { id: viewer; ph: photos; anchors.fill: parent }
}
