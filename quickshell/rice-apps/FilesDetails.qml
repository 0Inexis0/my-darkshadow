import QtQuick

// Files: the details pane: a big picture of the chosen file and what is known about it (or of the folder you are in).
Item {
    id: d
    property var fa
    clip: true
    readonly property var e: fa.focusE
    readonly property string path: e ? e.path : (fa.mode === "folder" ? fa.cur : "")
    readonly property string name: e ? e.name : fa.placeName
    readonly property bool isDir: e ? !!e.dir : fa.mode === "folder"
    property var info: ({})
    property var ex: ({})
    onPathChanged: if (width > 0) load()
    onWidthChanged: if (width > 0 && info.path !== path) load()
    function load() {
        info = ({}); ex = ({})
        if (path === "") return
        const p = path
        Sys.run(["info", p], function(r) { if (r && d.path === p) d.info = r })
        if (Theme.kind(name, isDir) === "image") Sys.run(["exif", p], function(r) { if (r && d.path === p) d.ex = r })
    }
    Rectangle { width: 1; height: parent.height; color: Theme.outlineVariant }
    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 1
        contentHeight: col.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Column {
            id: col
            x: 20; y: 12
            width: 296 - 40
            spacing: 14
            Rectangle {
                width: parent.width; height: width * 0.78
                radius: Theme.sq ? 0 : (Theme.rL)
                color: Theme.surfaceC
                FileTile {
                    anchors.centerIn: parent
                    width: parent.width * 0.72; height: width * 0.86
                    path: d.path; name: d.name; isDir: d.isDir
                    thumb: d.fa.thumbs[d.path] || ""
                    symbol: d.isDir ? (d.fa.symbols[d.path] || "") : ""
                    visible: d.path !== ""
                }
            }
            T { text: d.fa.selN > 1 ? d.fa.selN + " items" : d.name; role: "title"; width: parent.width; wrapMode: Text.WrapAnywhere; maximumLineCount: 3 }
            Column {
                width: parent.width
                spacing: 2
                visible: d.fa.selN <= 1
                Info { k: "Type"; v: d.info.mime || "" }
                Info { k: "Size"; v: d.info.size !== undefined ? Theme.size(d.info.size) + (d.isDir && d.info.items !== undefined ? " · " + d.info.items + " items" : "") : "" }
                Info { k: "Picture"; v: d.ex.w ? d.ex.w + " × " + d.ex.h : "" }
                Info { k: "Camera"; v: d.ex.camera || "" }
                Info { k: "Taken"; v: d.ex.taken ? d.ex.taken.replace(/^(\d+):(\d+):(\d+)/, "$3.$2.$1") : "" }
                Info { k: "Exposure"; v: d.ex.f ? "ƒ/" + d.ex.f + (d.ex.exp ? " · " + d.ex.exp + " s" : "") + (d.ex.iso ? " · ISO " + d.ex.iso : "") + (d.ex.focal ? " · " + d.ex.focal + " mm" : "") : "" }
                Info { k: "Modified"; v: d.info.modified ? Qt.formatDateTime(new Date(d.info.modified), "d MMM yyyy, hh:mm") : "" }
                Info { k: d.e && d.e.orig ? "From" : "Where"; v: d.e && d.e.orig ? d.e.orig : d.path.replace(/\/[^\/]*$/, "").replace(Theme.home, "~") }
                Info { k: "Rights"; v: d.info.mode || "" }
                Info { k: "Free here"; v: d.info.free !== undefined ? Theme.size(d.info.free) : "" }
            }
            T { visible: d.fa.selN > 1; text: Theme.size(d.fa.selSize()) + " in the files"; color: Theme.inkVar }
            Flow {
                width: parent.width
                spacing: 8
                visible: d.e !== null && d.fa.mode !== "trash"
                Btn { kind: "tonal"; icon: "open_in_new"; text: "Open"; onClicked: d.fa.openSel() }
                Btn { kind: "outlined"; icon: "content_copy"; text: "Copy"; onClicked: d.fa.clip("copy") }
            }
        }
    }
    component Info: Item {
        property string k: ""
        property string v: ""
        visible: v !== ""
        width: parent.width
        height: Math.max(28, vt.implicitHeight + 8)
        T { text: parent.k; role: "label"; color: Theme.inkVar; width: 86; y: 4 }
        T { id: vt; x: 92; y: 4; width: parent.width - 92; text: parent.v; wrapMode: Text.WrapAnywhere; maximumLineCount: 3 }
    }
}
