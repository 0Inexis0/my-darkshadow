import QtQuick

// Files: the navigation drawer (your folders, bookmarks, drives, the trash). Narrow windows get a rail of icons.
Item {
    id: side
    property var fa
    property bool rail: false
    readonly property var p: fa.places
    width: rail ? 84 : 252

    Flickable {
        id: fl
        anchors.fill: parent
        anchors.topMargin: 12
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col
            x: side.rail ? 12 : 12
            width: side.width - 24
            spacing: 2
            // the app's name, and the button that makes something new
            Item {
                width: parent.width; height: side.rail ? 8 : 52
                visible: !side.rail
                Row {
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    AppIcon { app: "files"; width: 32; height: 32; anchors.verticalCenter: parent.verticalCenter
                        FolderGlyph { width: 28; height: 23; anchors.centerIn: parent } }
                    T { text: "Files"; role: "headline"; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Item { width: 1; height: 6 }
            NavItem { fa: side.fa; rail: side.rail; icon: "home"; text: "Home"; on: side.fa.mode === "folder" && side.fa.cur === Theme.home; onClicked: side.fa.go(Theme.home) }
            NavItem { fa: side.fa; rail: side.rail; icon: "schedule"; text: "Recent"; on: side.fa.mode === "recent"; onClicked: side.fa.goMode("recent") }
            NavItem { fa: side.fa; rail: side.rail; icon: "star"; text: "Starred"; on: side.fa.mode === "starred"; onClicked: side.fa.goMode("starred") }
            Head { text: "Folders" }
            Repeater {
                model: side.p.dirs || []
                NavItem { required property var modelData; fa: side.fa; rail: side.rail; icon: modelData.icon; text: modelData.name; path: modelData.path
                    on: side.fa.mode === "folder" && side.fa.cur === modelData.path; onClicked: side.fa.go(modelData.path) }
            }
            Head { text: "Bookmarks"; visible: !side.rail && (side.p.bookmarks || []).length > 0 }
            Repeater {
                model: side.p.bookmarks || []
                NavItem { required property var modelData; fa: side.fa; rail: side.rail; icon: "bookmark"; text: modelData.name; path: modelData.path
                    on: side.fa.mode === "folder" && side.fa.cur === modelData.path; onClicked: side.fa.go(modelData.path)
                    onMenu: function(it) { Ui.menu([{ icon: "open_in_new", text: "Open in a new window", act: function() { Sys.app("files", [modelData.path]) } },
                                                    { icon: "bookmark_remove", text: "Remove the bookmark", act: function() { side.fa.unmark(modelData.path) } }], it, it.width - 20, it.height / 2) } }
            }
            Head { text: "Drives" }
            Repeater {
                model: side.p.drives || []
                NavItem { required property var modelData; fa: side.fa; rail: side.rail; icon: modelData.icon; text: modelData.name; path: modelData.path
                    usage: modelData.total > 0 ? 1 - modelData.free / modelData.total : -1
                    sub: Theme.size(modelData.free) + " free of " + Theme.size(modelData.total)
                    on: side.fa.mode === "folder" && side.fa.cur === modelData.path; onClicked: side.fa.go(modelData.path)
                    onMenu: function(it) { if (modelData.removable) Ui.menu([{ icon: "eject", text: "Unmount", act: function() { side.fa.unmount(modelData.path) } }], it, it.width - 20, it.height / 2) } }
            }
            Item { width: 1; height: 8 }
            Rectangle { width: parent.width - 24; x: 12; height: 1; color: Theme.outlineVariant; visible: !side.rail }
            Item { width: 1; height: 8 }
            NavItem { fa: side.fa; rail: side.rail; icon: "delete"; text: "Trash"; badge: side.p.trash > 0 ? String(side.p.trash) : ""
                on: side.fa.mode === "trash"; onClicked: side.fa.goMode("trash"); path: side.p.trashPath || ""
                onMenu: function(it) { Ui.menu([{ icon: "delete_forever", text: "Empty the trash", danger: true, enabled: side.p.trash > 0, act: side.fa.emptyTrash }], it, it.width - 20, it.height / 2) } }
        }
    }
    VScroll { flick: fl; anchors.right: parent.right; anchors.top: fl.top; anchors.bottom: fl.bottom }

    component Head: T {
        visible: !side.rail
        role: "label"
        color: Theme.inkVar
        leftPadding: 16
        topPadding: 14
        bottomPadding: 6
    }
}
