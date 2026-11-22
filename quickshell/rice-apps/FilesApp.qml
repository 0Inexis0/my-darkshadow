import Quickshell
import QtQuick
import Qt.labs.folderlistmodel

// Files: our file manager. Folders through FolderListModel (it follows changes on its own); copying, moving,
// the trash, archives and searching through rice-apps-helper.
Item {
    id: files
    objectName: "app"
    focus: true
    readonly property string title: "Files — " + placeName
    readonly property string placeName: mode === "trash" ? "Trash" : (mode === "recent" ? "Recent" : (mode === "starred" ? "Starred"
                                        : (mode === "search" ? "Search" : (cur === Theme.home ? "Home" : (cur === "/" ? "Computer" : cur.replace(/^.*\//, ""))))))

    // ---------------------------------------------------------------- state
    property string cur: Theme.home
    property string mode: "folder"            // folder, trash, recent, starred, search
    property var hist: []
    property var fwd: []
    property var places: ({ dirs: [], bookmarks: [], drives: [], trash: 0, trashPath: "" })
    property string view: "grid"
    property string sortBy: "name"
    property bool rev: false
    property bool hidden: false
    property int zoom: 112
    property bool details: false
    property var starred: []
    property string query: ""
    property string searchFor: ""
    property bool loading: false
    property var sel: ({})
    property int selN: 0
    property int anchorIdx: -1
    property var cutSet: ({})
    property var thumbs: ({})
    property string pendingSelect: ""
    property real mx: 0
    property real my: 0
    property bool prefsLoaded: false
    readonly property bool rail: width < 880
    readonly property var model: mode === "folder" && query === "" ? fm : lm
    readonly property int count: model === fm ? fm.count : lm.count

    function start(args) {
        const a = args && args.length > 0 ? args[0] : ""
        Sys.run(["prefs", "files", "get"], function(j) {
            j = j || {}
            if (j.view) view = j.view
            if (j.sort) sortBy = j.sort
            rev = j.rev === true
            hidden = j.hidden === true
            if (j.zoom) zoom = Math.max(72, Math.min(220, j.zoom))
            details = j.details === true
            starred = j.starred || []
            prefsLoaded = true
        })
        if (a !== "") {
            Sys.run(["stat", a], function(r) {
                if (!r || r.length === 0) return
                if (r[0].fileIsDir) go(r[0].filePath, true)
                else { pendingSelect = r[0].filePath; go(r[0].filePath.replace(/\/[^\/]*$/, "") || "/", true) }
            })
        }
        loadPlaces()
        view_.forceActiveFocus()
    }
    function savePrefs() { if (prefsLoaded) saveT.restart() }
    Timer { id: saveT; interval: 700; onTriggered: Sys.savePrefs("files", { view: files.view, sort: files.sortBy, rev: files.rev, hidden: files.hidden, zoom: files.zoom, details: files.details, starred: files.starred }) }
    onViewChanged: savePrefs()
    onSortByChanged: { savePrefs(); if (model === lm) fill(listNow()) }
    onRevChanged: { savePrefs(); if (model === lm) fill(listNow()) }
    onHiddenChanged: savePrefs()
    onZoomChanged: savePrefs()
    onDetailsChanged: savePrefs()

    function loadPlaces() { Sys.run(["places"], function(j) { if (j) files.places = j }) }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: files.loadPlaces() }

    // ---------------------------------------------------------------- models
    FolderListModel {
        id: fm
        folder: files.mode === "folder" ? Theme.url(files.cur) : ""
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: files.hidden
        showOnlyReadable: false
        sortCaseSensitive: false
        caseSensitive: false
        sortReversed: files.rev
        sortField: files.sortBy === "date" ? FolderListModel.Time : (files.sortBy === "size" ? FolderListModel.Size : (files.sortBy === "type" ? FolderListModel.Type : FolderListModel.Name))
        onStatusChanged: if (status === FolderListModel.Ready) files.afterLoad()
        onCountChanged: { if (files.query !== "" && files.mode === "folder") filterT.restart(); files.afterLoad() }
    }
    ListModel { id: lm }
    function row(o) {
        return { fileName: o.fileName || "", filePath: o.filePath || "", fileIsDir: !!o.fileIsDir, fileSize: o.fileSize || 0,
                 fileModified: o.fileModified || 0, fileSuffix: o.fileSuffix || "", orig: o.orig || "", trashName: o.trashName || "" }
    }
    function fill(list) {
        lm.clear()
        const l = (list || []).slice()
        // the same order as the folder (folders first, then by the chosen field)
        if (mode !== "recent" && mode !== "trash") l.sort(function(a, b) {
            if (!!a.fileIsDir !== !!b.fileIsDir) return a.fileIsDir ? -1 : 1
            let r = 0
            if (sortBy === "date") r = (a.fileModified || 0) - (b.fileModified || 0)
            else if (sortBy === "size") r = (a.fileSize || 0) - (b.fileSize || 0)
            else r = String(a.fileName).localeCompare(String(b.fileName), undefined, { numeric: true, sensitivity: "base" })
            return rev ? -r : r
        })
        for (let i = 0; i < l.length; i++) lm.append(row(l[i]))
        afterLoad()
    }
    // typing filters the folder at once
    Timer { id: filterT; interval: 60; onTriggered: files.filterNow() }
    function filterNow() {
        if (mode !== "folder" || query === "") return
        const q = query.toLowerCase(), l = []
        for (let i = 0; i < fm.count; i++) {
            const n = fm.get(i, "fileName")
            if (String(n).toLowerCase().indexOf(q) >= 0)
                l.push({ fileName: n, filePath: fm.get(i, "filePath"), fileIsDir: fm.get(i, "fileIsDir"), fileSize: fm.get(i, "fileSize"),
                         fileModified: fm.get(i, "fileModified").getTime ? fm.get(i, "fileModified").getTime() : 0 })
        }
        fill(l)
    }
    onQueryChanged: { clearSel(); if (query !== "") filterT.restart() }
    function at(i) {
        if (i < 0 || i >= count) return null
        if (model === fm) return { name: fm.get(i, "fileName"), path: fm.get(i, "filePath"), dir: fm.get(i, "fileIsDir"), size: fm.get(i, "fileSize"), mod: fm.get(i, "fileModified"), trashName: "", orig: "" }
        const o = lm.get(i)
        return { name: o.fileName, path: o.filePath, dir: o.fileIsDir, size: o.fileSize, mod: o.fileModified, trashName: o.trashName, orig: o.orig }
    }
    function indexOf(path) {
        for (let i = 0; i < count; i++) { const e = at(i); if (e && e.path === path) return i }
        return -1
    }
    function afterLoad() {
        if (pendingSelect === "") return
        const i = indexOf(pendingSelect)
        if (i < 0) return
        pendingSelect = ""
        selectOnly(i)
        Qt.callLater(function() { view_.cur.positionViewAtIndex(i, GridView.Contain) })
    }

    // ---------------------------------------------------------------- going places
    function go(p, keep) {
        if (!p) return
        if (mode === "folder" && p === cur && query === "") return
        if (!keep) { hist = hist.concat([{ mode: mode, cur: cur }]).slice(-60); fwd = [] }
        query = ""; searchFor = ""; bar.closeSearch()
        mode = "folder"; cur = p
        clearSel()
        view_.cur.contentY = view_.cur.originY
        view_.forceActiveFocus()
    }
    function goMode(m, keep) {
        if (mode === m && m !== "search") { reloadList(); return }
        if (!keep) { hist = hist.concat([{ mode: mode, cur: cur }]).slice(-60); fwd = [] }
        if (m !== "search") { query = ""; bar.closeSearch() }
        mode = m
        clearSel()
        reloadList()
    }
    function reloadList() {
        lm.clear()
        if (mode === "trash") { loading = true; Sys.run(["trash-list"], function(r) { loading = false; if (files.mode === "trash") files.fill(r) }) }
        else if (mode === "recent") { loading = true; Sys.run(["recent"], function(r) { loading = false; if (files.mode === "recent") files.fill(r) }) }
        else if (mode === "starred") { loading = true; Sys.run(["stat"].concat(starred), function(r) { loading = false; if (files.mode === "starred") files.fill(r) }) }
        else if (mode === "search") { loading = true; const q = searchFor; Sys.run(["search", cur, q], function(r) { loading = false; if (files.mode === "search" && files.searchFor === q) files.fill(r) }) }
    }
    function goBack() {
        if (hist.length === 0) return
        const h = hist[hist.length - 1]
        fwd = fwd.concat([{ mode: mode, cur: cur }]); hist = hist.slice(0, -1)
        restore(h)
    }
    function goFwd() {
        if (fwd.length === 0) return
        const h = fwd[fwd.length - 1]
        hist = hist.concat([{ mode: mode, cur: cur }]); fwd = fwd.slice(0, -1)
        restore(h)
    }
    function restore(h) {
        const before = cur
        if (h.mode === "folder") go(h.cur, true)
        else { cur = h.cur; goMode(h.mode, true) }
        // back into the folder you came from: the one you were in is chosen again
        if (h.mode === "folder" && before.indexOf(h.cur + "/") === 0) pendingSelect = h.cur.replace(/\/$/, "") + "/" + before.substring(h.cur.length + (h.cur === "/" ? 0 : 1)).split("/")[0]
    }
    function up() {
        if (mode !== "folder" || cur === "/") { if (mode !== "folder") go(cur); return }
        const p = cur.replace(/\/[^\/]*$/, "") || "/"
        const was = cur
        go(p)
        pendingSelect = was
    }
    function search(text) {
        searchFor = text
        goMode("search")
    }

    // ---------------------------------------------------------------- selection
    function clearSel() { sel = ({}); selN = 0; anchorIdx = -1 }
    function isSel(path) { return sel[path] === true }
    function selectOnly(i) {
        const e = at(i); if (!e) return
        const s = {}; s[e.path] = true
        sel = s; selN = 1; anchorIdx = i
        view_.cur.currentIndex = i
    }
    function toggle(i) {
        const e = at(i); if (!e) return
        const s = Object.assign({}, sel)
        if (s[e.path]) delete s[e.path]; else s[e.path] = true
        sel = s; selN = Object.keys(s).length; anchorIdx = i
        view_.cur.currentIndex = i
    }
    function range(i, add) {
        if (anchorIdx < 0) { selectOnly(i); return }
        const s = add ? Object.assign({}, sel) : {}
        const a = Math.min(anchorIdx, i), b = Math.max(anchorIdx, i)
        for (let k = a; k <= b; k++) { const e = at(k); if (e) s[e.path] = true }
        sel = s; selN = Object.keys(s).length
        view_.cur.currentIndex = i
    }
    function selectRange(a, b, add, base) {
        const s = add ? Object.assign({}, base) : {}
        for (let k = Math.max(0, a); k <= Math.min(count - 1, b); k++) { const e = at(k); if (e) s[e.path] = true }
        sel = s; selN = Object.keys(s).length
    }
    function selectSet(idx, add, base) {
        const s = add ? Object.assign({}, base) : {}
        for (let k = 0; k < idx.length; k++) { const e = at(idx[k]); if (e) s[e.path] = true }
        sel = s; selN = Object.keys(s).length
    }
    function selectAll() {
        const s = {}
        for (let i = 0; i < count; i++) { const e = at(i); if (e) s[e.path] = true }
        sel = s; selN = Object.keys(s).length
    }
    function selected() {
        const l = []
        for (let i = 0; i < count && l.length < selN; i++) { const e = at(i); if (e && sel[e.path]) l.push(e) }
        return l
    }
    // the symbol on a folder of yours (Downloads, Music ...)
    readonly property var symbols: {
        const m = {}
        const d = places.dirs || []
        for (let i = 0; i < d.length; i++) m[d[i].path] = d[i].icon
        return m
    }
    function selPaths() { return selected().map(function(e) { return e.path }) }
    // what the details pane and Quick look show: the one you clicked last
    readonly property var focusE: { const _ = sel; const r = selN; return selN === 1 ? (selected()[0] || null) : null }
    function selSize() { let t = 0; const l = selected(); for (let i = 0; i < l.length; i++) if (!l[i].dir) t += Number(l[i].size) || 0; return t }

    // ---------------------------------------------------------------- doing things
    function openE(e, newWin) {
        if (!e) return
        if (e.dir) { if (newWin) Sys.app("files", [e.path]); else if (mode === "trash") return; else go(e.path); return }
        if (mode === "trash") { quick.show(e); return }
        Sys.open(e.path)
    }
    function openSel() {
        const l = selected()
        if (l.length === 1) { openE(l[0]); return }
        const dirs = l.filter(function(e) { return e.dir })
        if (dirs.length === l.length && dirs.length > 0) { go(dirs[0].path); for (let i = 1; i < dirs.length && i < 8; i++) Sys.app("files", [dirs[i].path]); return }
        const files = l.filter(function(e) { return !e.dir })
        const pics = files.filter(function(e) { return Theme.kind(e.name) === "image" })
        if (pics.length === files.length && pics.length > 1) { Sys.app("photos", [pics[0].path]); return }
        const media = files.filter(function(e) { const k = Theme.kind(e.name); return k === "audio" || k === "video" })
        if (media.length === files.length && media.length > 1) { Sys.app("player", media.map(function(e) { return e.path })); return }
        for (let i = 0; i < files.length && i < 12; i++) Sys.open(files[i].path)
    }
    function busy(text) { Ui.progress(text, -1) }
    function done(r, okText) {
        Ui.progress("", 1)
        if (!r) { Ui.snack("Something went wrong"); return false }
        if (r.error && r.error !== "") { Ui.snack(r.error); return false }
        if (okText) Ui.snack(okText)
        return true
    }
    function plural(n, one, many) { return n + " " + (n === 1 ? one : many) }
    function trashSel() {
        const ps = selPaths(); if (ps.length === 0) return
        if (mode === "trash") { deleteSel(); return }
        Sys.run(["trash"].concat(ps), function(r) {
            if (!r) return
            if (r.error) Ui.snack(r.error)
            else Ui.snack(plural(r.n, "item", "items") + " moved to the trash", "Undo", function() {
                Sys.run(["restore"].concat(r.names || []), function(x) { files.done(x); files.loadPlaces() })
            })
            files.loadPlaces()
        })
        clearSel()
    }
    function deleteSel() {
        const l = selected(); if (l.length === 0) return
        Ui.ask({ icon: "delete_forever", danger: true, title: l.length === 1 ? "Delete “" + l[0].name + "” forever?" : "Delete " + l.length + " items forever?",
                 text: "They do not go to the trash: you cannot get them back.", ok: "Delete",
                 onOk: function() { Sys.run(["delete"].concat(l.map(function(e) { return e.path })), function(r) { files.done(r); files.loadPlaces(); if (files.mode === "trash") files.reloadList() }) } })
    }
    function restoreSel() {
        const l = selected(); if (l.length === 0) return
        Sys.run(["restore"].concat(l.map(function(e) { return e.trashName })), function(r) { if (files.done(r, plural(r ? r.n : 0, "item", "items") + " put back")) { files.reloadList(); files.loadPlaces() } })
    }
    function emptyTrash() {
        Ui.ask({ icon: "delete_forever", danger: true, title: "Empty the trash?", text: "Everything in it is deleted forever.", ok: "Empty",
                 onOk: function() { Sys.run(["empty-trash"], function(r) { files.done(r, "The trash is empty"); files.loadPlaces(); if (files.mode === "trash") files.reloadList() }) } })
    }
    function clip(op) {
        const ps = selPaths(); if (ps.length === 0) return
        Sys.run(["clip", op].concat(ps), function(r) {
            if (!r) return
            const s = {}; if (op === "cut") for (let i = 0; i < ps.length; i++) s[ps[i]] = true
            files.cutSet = s
            Ui.snack(plural(ps.length, "item", "items") + (op === "cut" ? " cut: paste them where they should go" : " copied"))
        })
    }
    function paste(dest) {
        if (mode !== "folder" && !dest) return
        const d = dest || cur
        busy("Pasting …")
        Sys.run(["paste", d], function(r) {
            files.done(r)
            if (r && r.made && r.made.length > 0) { files.cutSet = ({}); if (d === files.cur) files.pendingSelect = r.made[0] }
        }, function(p) { Ui.progress("Pasting …", p) })
    }
    function dropInto(dest, drop) {
        if (!drop.hasUrls) return
        const ps = []
        for (let i = 0; i < drop.urls.length; i++) {
            const u = String(drop.urls[i])
            if (u.indexOf("file://") === 0) ps.push(decodeURIComponent(u.substring(7)))
        }
        if (ps.length === 0) return
        drop.acceptProposedAction()
        if (dest === places.trashPath) { Sys.run(["trash"].concat(ps), function(r) { files.done(r); files.loadPlaces() }); return }
        const op = drop.proposedAction === Qt.CopyAction ? "copy" : "move"
        busy(op === "copy" ? "Copying …" : "Moving …")
        Sys.run([op, dest].concat(ps), function(r) { files.done(r) }, function(p) { Ui.progress(op === "copy" ? "Copying …" : "Moving …", p) })
    }
    function newFolder() {
        if (mode !== "folder") return
        Ui.ask({ title: "New folder", field: "New folder", ok: "Make",
                 onOk: function(v) { Sys.run(["mkdir", files.cur, v.trim()], function(r) { if (files.done(r)) files.pendingSelect = r.path }) } })
    }
    function newFile() {
        if (mode !== "folder") return
        Ui.ask({ title: "New file", field: "New file.txt", select: [0, 8], ok: "Make",
                 onOk: function(v) { Sys.run(["newfile", files.cur, v.trim()], function(r) { if (files.done(r)) files.pendingSelect = r.path }) } })
    }
    function renameSel() {
        const l = selected(); if (l.length !== 1 || mode === "trash") return
        const e = l[0]
        const dot = e.dir ? -1 : e.name.lastIndexOf(".")
        Ui.ask({ title: "Rename", field: e.name, select: [0, dot > 0 ? dot : e.name.length], ok: "Rename",
                 onOk: function(v) { if (v === e.name) return; Sys.run(["rename", e.path, v.trim()], function(r) { if (files.done(r)) files.pendingSelect = r.path }) } })
    }
    function compressSel() {
        const l = selected(); if (l.length === 0) return
        const base = l.length === 1 ? l[0].name.replace(/\.[^.\/]*$/, "") : "Archive"
        Ui.ask({ title: "Compress", text: plural(l.length, "item", "items") + " into one file. End the name with .zip, .tar.gz or .7z.", field: base + ".zip", select: [0, base.length], ok: "Compress",
                 onOk: function(v) { files.busy("Compressing …"); Sys.run(["compress", files.cur.replace(/\/$/, "") + "/" + v.trim()].concat(l.map(function(e) { return e.path })), function(r) { if (files.done(r)) files.pendingSelect = r.path }) } })
    }
    function extractE(e) {
        busy("Extracting …")
        Sys.run(["extract", e.path], function(r) { if (files.done(r)) files.pendingSelect = r.path })
    }
    function star(e, on) {
        const l = starred.filter(function(p) { return p !== e.path })
        if (on) l.unshift(e.path)
        starred = l
        savePrefs()
        if (mode === "starred") reloadList()
        Ui.snack(on ? "Starred: it is in Starred on the left" : "Not starred any more")
    }
    function mark(p) {
        Sys.sh('f="$HOME/.config/gtk-3.0/bookmarks"; mkdir -p "$(dirname "$f")"; u="file://$(python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))" "$1")"; grep -qxF "$u" "$f" 2>/dev/null || echo "$u" >> "$f"', [p])
        Ui.snack("Bookmarked: it is on the left now")
        bmT.restart()
    }
    function unmark(p) {
        Sys.sh('f="$HOME/.config/gtk-3.0/bookmarks"; u="file://$(python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))" "$1")"; [ -f "$f" ] && grep -vF -e "$u" "$f" > "$f.tmp"; mv -f "$f.tmp" "$f"', [p])
        bmT.restart()
    }
    Timer { id: bmT; interval: 400; onTriggered: files.loadPlaces() }
    function unmount(p) {
        Sys.sh('d="$(findmnt -no SOURCE --target "$1")"; udisksctl unmount -b "$d" >/dev/null 2>&1 || gio mount -u "$1" >/dev/null 2>&1 || notify-send "Files" "It could not be unmounted (is something still using it?)"', [p])
        if (cur.indexOf(p) === 0) go(Theme.home)
        bmT.restart()
    }
    function wallpaper(e) {
        Sys.sh('exec bash "$HOME/.config/quickshell/hyprquickpaper/commands.sh" "$1"', [e.path])
        Ui.snack("Wallpaper set: the colors follow it")
    }
    function terminalHere(p) { Sys.sh('cd "$1" && exec "$HOME/.local/bin/rice-term"', [p || cur]) }
    function copyPaths() { const ps = selPaths(); Quickshell.execDetached(["wl-copy", ps.length > 0 ? ps.join("\n") : cur]); Ui.snack(ps.length > 1 ? "Paths copied" : "Path copied") }
    function openWith(e) {
        Sys.run(["apps", e.path], function(r) {
            if (!r) return
            const items = (r.apps || []).map(function(a) {
                return { icon: a.default ? "check_circle" : "apps", text: a.name, act: function() { Sys.run(["launch", a.file, e.path]) } }
            })
            if (items.length === 0) items.push({ icon: "block", text: "No app opens " + r.mime, enabled: false })
            items.push({ sep: true })
            items.push({ icon: "star", text: "Choose the default …", enabled: (r.apps || []).length > 0, act: function() {
                Ui.menu((r.apps || []).map(function(a) { return { icon: a.default ? "check_circle" : "radio_button_unchecked", text: a.name,
                    act: function() { Sys.run(["default", a.id, e.path], function(x) { if (files.done(x)) Ui.snack(a.name + " opens " + x.mime + " now") }) } } }), null, files.mx, files.my)
            } })
            Ui.menu(items, null, files.mx, files.my)
        })
    }

    // the menu of a file (or of the selection), or of the folder itself
    function itemMenu(e) {
        const l = selected(), one = l.length === 1, k = Theme.kind(e.name, e.dir)
        if (mode === "trash") return [
            { icon: "restore_from_trash", text: "Put back", act: restoreSel },
            { icon: "visibility", text: "Quick look", key: "Space", enabled: one && !e.dir, act: function() { quick.show(e) } },
            { sep: true },
            { icon: "delete_forever", text: "Delete forever", danger: true, act: deleteSel }]
        const isStar = starred.indexOf(e.path) >= 0
        return [
            { icon: "open_in_new", text: one && e.dir ? "Open" : "Open", key: "Enter", act: openSel },
            one && e.dir ? { icon: "tab", text: "Open in a new window", act: function() { Sys.app("files", [e.path]) } } : null,
            one && !e.dir ? { icon: "apps", text: "Open with …", act: function() { files.openWith(e) } } : null,
            one && k === "image" ? { icon: "photo_library", text: "Open in Photos", act: function() { Sys.app("photos", [e.path]) } } : null,
            (k === "audio" || k === "video") ? { icon: "play_circle", text: "Play in Player", act: function() { Sys.app("player", l.map(function(x) { return x.path })) } } : null,
            one && !e.dir ? { icon: "visibility", text: "Quick look", key: "Space", act: function() { quick.show(e) } } : null,
            { sep: true },
            { icon: "content_cut", text: "Cut", key: "Ctrl+X", act: function() { files.clip("cut") } },
            { icon: "content_copy", text: "Copy", key: "Ctrl+C", act: function() { files.clip("copy") } },
            one && e.dir ? { icon: "content_paste", text: "Paste into it", act: function() { files.paste(e.path) } } : null,
            { icon: "edit", text: "Rename", key: "F2", enabled: one, act: renameSel },
            { sep: true },
            one && k === "archive" ? { icon: "unarchive", text: "Extract here", act: function() { files.extractE(e) } } : null,
            { icon: "folder_zip", text: "Compress …", act: compressSel },
            one && k === "image" ? { icon: "wallpaper", text: "Set as wallpaper", act: function() { files.wallpaper(e) } } : null,
            one ? { icon: isStar ? "star_rate" : "star", text: isStar ? "Not starred" : "Star", act: function() { files.star(e, !isStar) } } : null,
            one && e.dir ? { icon: "bookmark_add", text: "Bookmark", act: function() { files.mark(e.path) } } : null,
            one && e.dir ? { icon: "terminal", text: "Open a terminal here", act: function() { files.terminalHere(e.path) } } : null,
            { icon: "link", text: l.length > 1 ? "Copy the paths" : "Copy the path", act: copyPaths },
            { sep: true },
            { icon: "info", text: "Details", act: function() { files.details = true } },
            { icon: "delete", text: "Move to the trash", key: "Delete", danger: true, act: trashSel }]
    }
    // the Menu key (or Shift + F10): the menu of the chosen file, next to it
    function keyMenu() {
        const v = view_.cur, it = v.currentItem
        if (it) { const p = it.mapToItem(files, it.width / 2, it.height / 2); mx = p.x; my = p.y } else { mx = width / 2; my = height / 3 }
        Ui.menu(focusE ? itemMenu(focusE) : folderMenu(), null, mx, my)
    }
    function folderMenu() {
        if (mode === "trash") return [{ icon: "delete_forever", text: "Empty the trash", danger: true, enabled: places.trash > 0, act: emptyTrash }]
        if (mode !== "folder") return [{ icon: "select_all", text: "Select all", key: "Ctrl+A", act: selectAll }]
        return [
            { icon: "create_new_folder", text: "New folder", key: "Ctrl+Shift+N", act: newFolder },
            { icon: "note_add", text: "New file", act: newFile },
            { icon: "content_paste", text: "Paste", key: "Ctrl+V", act: function() { files.paste() } },
            { sep: true },
            { icon: "select_all", text: "Select all", key: "Ctrl+A", act: selectAll },
            { icon: hidden ? "visibility_off" : "visibility", text: hidden ? "Hide hidden files" : "Show hidden files", key: "Ctrl+H", act: function() { files.hidden = !files.hidden } },
            { icon: "terminal", text: "Open a terminal here", act: function() { files.terminalHere() } },
            { icon: "bookmark_add", text: "Bookmark this folder", act: function() { files.mark(files.cur) } },
            { icon: "link", text: "Copy the path", act: function() { Quickshell.execDetached(["wl-copy", files.cur]); Ui.snack("Path copied") } }]
    }
    function sortMenu(src) {
        function it(k, icon, text) { return { icon: files.sortBy === k ? "check" : icon, text: text, act: function() { files.sortBy = k } } }
        Ui.menu([it("name", "sort_by_alpha", "Name"), it("date", "schedule", "Modified"), it("size", "straighten", "Size"), it("type", "category", "Type"),
                 { sep: true },
                 { icon: files.rev ? "arrow_upward" : "arrow_downward", text: files.rev ? "Reversed" : "In order", act: function() { files.rev = !files.rev } },
                 { icon: files.hidden ? "check_box" : "check_box_outline_blank", text: "Hidden files", key: "Ctrl+H", act: function() { files.hidden = !files.hidden } }], src, 0, src.height)
    }
    function listNow() { const l = []; for (let i = 0; i < lm.count; i++) l.push(lm.get(i)); return l }

    // ---------------------------------------------------------------- the keyboard
    Keys.onPressed: function(k) { keys(k) }
    function keys(k) {
        if (Ui.busy() || quick.open) return
        const ctrl = k.modifiers & Qt.ControlModifier, shift = k.modifiers & Qt.ShiftModifier, alt = k.modifiers & Qt.AltModifier
        const v = view_.cur
        const cols = view === "grid" ? Math.max(1, view_.cols) : 1
        function move(d) {
            if (count === 0) return
            let i = v.currentIndex < 0 ? 0 : Math.max(0, Math.min(count - 1, v.currentIndex + d))
            if (shift) range(i, false); else selectOnly(i)
            v.positionViewAtIndex(i, GridView.Contain)
        }
        if (alt && k.key === Qt.Key_Left) { goBack(); k.accepted = true }
        else if (alt && k.key === Qt.Key_Right) { goFwd(); k.accepted = true }
        else if ((alt && k.key === Qt.Key_Up) || k.key === Qt.Key_Backspace) { up(); k.accepted = true }
        else if (alt && k.key === Qt.Key_Return) { details = !details; k.accepted = true }
        else if (k.key === Qt.Key_Left) { move(-1); k.accepted = true }
        else if (k.key === Qt.Key_Right) { move(1); k.accepted = true }
        else if (k.key === Qt.Key_Up) { move(-cols); k.accepted = true }
        else if (k.key === Qt.Key_Down) { move(cols); k.accepted = true }
        else if (k.key === Qt.Key_Home) { move(-count); k.accepted = true }
        else if (k.key === Qt.Key_End) { move(count); k.accepted = true }
        else if (k.key === Qt.Key_Return || k.key === Qt.Key_Enter) { openSel(); k.accepted = true }
        else if (k.key === Qt.Key_Space && selN === 1) { quick.show(focusE); k.accepted = true }
        else if (k.key === Qt.Key_Delete) { if (shift) deleteSel(); else trashSel(); k.accepted = true }
        else if (k.key === Qt.Key_F2) { renameSel(); k.accepted = true }
        else if (k.key === Qt.Key_Menu || (shift && k.key === Qt.Key_F10)) { keyMenu(); k.accepted = true }
        else if (k.key === Qt.Key_F5) { if (model === fm) { const c = cur; cur = ""; cur = c } else reloadList(); loadPlaces(); k.accepted = true }
        else if (k.key === Qt.Key_Escape) { if (query !== "" || bar.searching) bar.closeSearch(); else clearSel(); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_A) { selectAll(); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_C) { clip("copy"); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_X) { clip("cut"); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_V) { paste(); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_H) { hidden = !hidden; k.accepted = true }
        else if (ctrl && k.key === Qt.Key_L) { bar.editPath(); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_F) { bar.openSearch(""); k.accepted = true }
        else if (ctrl && shift && k.key === Qt.Key_N) { newFolder(); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_N) { Sys.app("files", [cur]); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_1) { view = "grid"; k.accepted = true }
        else if (ctrl && k.key === Qt.Key_2) { view = "list"; k.accepted = true }
        else if (ctrl && (k.key === Qt.Key_Plus || k.key === Qt.Key_Equal)) { zoom = Math.min(220, zoom + 16); k.accepted = true }
        else if (ctrl && k.key === Qt.Key_Minus) { zoom = Math.max(72, zoom - 16); k.accepted = true }
        else if (!ctrl && !alt && k.text !== "" && k.text.charCodeAt(0) > 32) { bar.openSearch(k.text); k.accepted = true }
    }

    // ---------------------------------------------------------------- the window
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: function(m) { if (m.button === Qt.BackButton) files.goBack(); else files.goFwd() }
    }
    FilesSide { id: side; fa: files; rail: files.rail; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom }

    Rectangle {
        id: pane
        anchors.left: side.right
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.top: parent.top; anchors.topMargin: 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        radius: Theme.rXL
        color: Theme.surfaceLow
        clip: true

        FilesBar { id: bar; fa: files; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top }

        Item {
            id: body
            anchors.top: bar.bottom
            anchors.left: parent.left
            anchors.right: det.left
            anchors.bottom: status.top
            FilesView { id: view_; fa: files; anchors.fill: parent }
            // nothing here
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: files.count === 0 && !files.loading && (files.mode !== "folder" || fm.status === FolderListModel.Ready)
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 112; height: 112; radius: 40
                    color: Theme.surfaceC
                    rotation: 8
                    Ic { anchors.centerIn: parent; rotation: -8; size: 52; color: Theme.primary
                         name: files.mode === "trash" ? "delete" : (files.mode === "search" || files.query !== "" ? "search_off" : (files.mode === "recent" ? "schedule" : (files.mode === "starred" ? "star" : "folder_open"))) }
                }
                T { anchors.horizontalCenter: parent.horizontalCenter; role: "title"
                    text: files.mode === "trash" ? "The trash is empty" : (files.mode === "search" || files.query !== "" ? "Nothing found" : (files.mode === "recent" ? "Nothing opened lately"
                          : (files.mode === "starred" ? "Nothing starred yet" : "This folder is empty"))) }
                T { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.inkVar
                    text: files.mode === "starred" ? "Right click a file or a folder > Star" : (files.mode === "search" || files.query !== "" ? "Try other words" : (files.mode === "folder" ? "Drop files here, or make something new" : "")) }
            }
            // busy
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 24
                width: 44; height: 44; radius: 22
                color: Theme.surfaceHigh
                visible: files.loading
                Ic { anchors.centerIn: parent; name: "progress_activity"; color: Theme.primary
                     RotationAnimation on rotation { running: files.loading; from: 0; to: 360; duration: 900; loops: Animation.Infinite } }
            }
            Fab {
                id: fab
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                visible: files.mode === "folder"
                icon: "add"
                text: "New"
                expanded: !view_.cur.moving && view_.cur.contentY - view_.cur.originY < 40
                onClicked: Ui.menu([{ icon: "create_new_folder", text: "New folder", act: files.newFolder }, { icon: "note_add", text: "New file", act: files.newFile },
                                    { icon: "content_paste", text: "Paste", act: function() { files.paste() } }], fab, 0, -8)
            }
        }
        FilesDetails {
            id: det
            fa: files
            anchors.top: bar.bottom
            anchors.bottom: status.top
            anchors.right: parent.right
            width: files.details && pane.width > 640 ? 296 : 0
            Behavior on width { NumberAnimation { duration: Theme.d(320); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        }
        // the status line
        Item {
            id: status
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 40
            T {
                x: 20; anchors.verticalCenter: parent.verticalCenter
                role: "small"; color: Theme.inkVar
                text: files.selN > 0 ? files.plural(files.selN, "item", "items") + " selected" + (files.selSize() > 0 ? " · " + Theme.size(files.selSize()) : "")
                      : files.plural(files.count, "item", "items") + (files.mode === "folder" ? "" : "")
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Ic { name: "photo_size_select_small"; size: 16; color: Theme.inkVar; visible: files.view === "grid"; anchors.verticalCenter: parent.verticalCenter }
                Slider {
                    visible: files.view === "grid"
                    width: 110; height: 24; trackH: 6
                    value: (files.zoom - 72) / (220 - 72)
                    onMoved: function(v) { files.zoom = Math.round(72 + v * (220 - 72)) }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
    QuickLook { id: quick; fa: files; anchors.fill: parent }
}
