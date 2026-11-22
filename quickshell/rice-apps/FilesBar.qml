import QtQuick

// Files: the top bar. Back, forward, up; where you are as a row of pieces you can click (a click on the empty end,
// or Ctrl + L, lets you type a path); search; grid or list; sort; the details pane.
Item {
    id: bar
    property var fa
    property bool searching: false
    property bool editing: false
    height: 68

    function openSearch(t) {
        searching = true; editing = false
        sf.text = t
        sf.input.forceActiveFocus()
        sf.input.cursorPosition = sf.text.length
    }
    function closeSearch() {
        if (!searching && fa.query === "") return
        searching = false
        sf.text = ""
        fa.query = ""
        if (fa.mode === "search") fa.go(fa.cur, true)
        fa.forceActiveFocus()
    }
    function editPath() {
        searching = false; editing = true
        pf.text = fa.mode === "folder" ? fa.cur : Theme.home
        pf.forceActiveFocus(); pf.selectAll()
    }

    Row {
        id: nav
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        IconBtn { icon: "arrow_back"; tip: "Back (Alt + Left)"; enabledBtn: bar.fa.hist.length > 0; onClicked: bar.fa.goBack() }
        IconBtn { icon: "arrow_forward"; tip: "Forward (Alt + Right)"; enabledBtn: bar.fa.fwd.length > 0; onClicked: bar.fa.goFwd() }
        IconBtn { icon: "arrow_upward"; tip: "Up (Backspace)"; enabledBtn: bar.fa.mode !== "folder" || bar.fa.cur !== "/"; onClicked: bar.fa.up() }
    }

    // where you are
    Rectangle {
        id: crumbs
        anchors.left: nav.right; anchors.leftMargin: 8
        anchors.right: tools.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 48
        radius: Theme.sq ? 0 : (24)
        color: bar.editing ? Theme.surfaceHighest : Theme.surfaceC
        visible: !bar.searching
        Behavior on color { ColorAnimation { duration: 160 } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: bar.editPath() }
        readonly property var parts: {
            const f = bar.fa
            if (f.mode === "trash") return [{ t: "Trash", p: "", icon: "delete" }]
            if (f.mode === "recent") return [{ t: "Recent", p: "", icon: "schedule" }]
            if (f.mode === "starred") return [{ t: "Starred", p: "", icon: "star" }]
            const cur = f.cur, r = []
            let rest
            if (cur === Theme.home || cur.indexOf(Theme.home + "/") === 0) { r.push({ t: "Home", p: Theme.home, icon: "home" }); rest = cur.substring(Theme.home.length) }
            else { r.push({ t: "Computer", p: "/", icon: "computer" }); rest = cur === "/" ? "" : cur }
            let acc = r[0].p === "/" ? "" : r[0].p
            const bits = rest.split("/").filter(function(x) { return x !== "" })
            for (let i = 0; i < bits.length; i++) { acc += "/" + bits[i]; r.push({ t: bits[i], p: acc, icon: "" }) }
            if (f.mode === "search") r.push({ t: "“" + f.searchFor + "”", p: "", icon: "search" })
            return r
        }
        ListView {
            id: lv
            visible: !bar.editing
            anchors.fill: parent
            anchors.leftMargin: 6; anchors.rightMargin: 6
            orientation: ListView.Horizontal
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            model: crumbs.parts
            onCountChanged: Qt.callLater(function() { lv.positionViewAtEnd() })
            onWidthChanged: Qt.callLater(function() { lv.positionViewAtEnd() })
            delegate: Row {
                required property var modelData
                required property int index
                height: lv.height
                Ic { visible: index > 0; name: "chevron_right"; size: 18; color: Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    id: seg
                    readonly property bool last: index === lv.count - 1
                    anchors.verticalCenter: parent.verticalCenter
                    height: 36
                    width: segRow.implicitWidth + 24
                    radius: Theme.sq ? 0 : (18)
                    color: last ? Theme.secondaryContainer : "transparent"
                    readonly property bool dropOn: sda.containsDrag
                    border.width: dropOn ? 2 : 0
                    border.color: Theme.primary
                    Layer { area: sm; ink: Theme.ink }
                    Row {
                        id: segRow
                        anchors.centerIn: parent
                        spacing: 6
                        Ic { visible: modelData.icon !== ""; name: modelData.icon; size: 18; color: seg.last ? Theme.inkSecondaryC : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
                        T { text: modelData.t; role: "label"; color: seg.last ? Theme.inkSecondaryC : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 220) }
                    }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: function(m) { if (modelData.p === "") return; if (m.button === Qt.MiddleButton) Sys.app("files", [modelData.p]); else bar.fa.go(modelData.p) } }
                    DropArea { id: sda; anchors.fill: parent; enabled: modelData.p !== ""; onDropped: function(d) { bar.fa.dropInto(modelData.p, d) } }
                }
            }
            footer: Item { width: 40; height: lv.height }
        }
        TextInput {
            id: pf
            visible: bar.editing
            anchors.fill: parent
            anchors.leftMargin: 20; anchors.rightMargin: 20
            verticalAlignment: TextInput.AlignVCenter
            font.family: Theme.font; font.pixelSize: 15
            color: Theme.ink
            selectionColor: Theme.alpha(Theme.primary, 0.4)
            selectedTextColor: Theme.ink
            selectByMouse: true
            clip: true
            onActiveFocusChanged: if (!activeFocus) bar.editing = false
            Keys.onEscapePressed: { bar.editing = false; bar.fa.forceActiveFocus() }
            onAccepted: {
                let p = text.trim().replace(/^~(?=\/|$)/, Theme.home)
                if (p.length > 1) p = p.replace(/\/+$/, "")
                bar.editing = false
                Sys.run(["stat", p], function(r) {
                    if (r && r.length > 0) { if (r[0].fileIsDir) bar.fa.go(r[0].filePath); else { bar.fa.pendingSelect = r[0].filePath; bar.fa.go(r[0].filePath.replace(/\/[^\/]*$/, "") || "/") } }
                    else Ui.snack("There is no " + p)
                })
                bar.fa.forceActiveFocus()
            }
        }
    }
    Search {
        id: sf
        visible: bar.searching
        anchors.left: nav.right; anchors.leftMargin: 8
        anchors.right: tools.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        hint: bar.fa.mode === "folder" ? "Filter " + bar.fa.placeName + " · Enter: search inside it too" : "Search"
        onTextChanged: if (bar.fa.mode === "folder" || bar.fa.mode === "search") { if (bar.fa.mode === "folder") bar.fa.query = text }
        onAccepted: if (text.trim() !== "") bar.fa.search(text.trim())
        onEscaped: bar.closeSearch()
    }

    Row {
        id: tools
        anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        IconBtn { icon: bar.searching ? "close" : "search"; tip: "Search (Ctrl + F, or just type)"; toggled: bar.searching
            onClicked: { if (bar.searching) bar.closeSearch(); else bar.openSearch("") } }
        Seg {
            anchors.verticalCenter: parent.verticalCenter
            value: bar.fa.view
            options: [{ key: "grid", icon: "grid_view" }, { key: "list", icon: "view_list" }]
            onPicked: function(k) { bar.fa.view = k }
        }
        IconBtn { id: sortB; icon: "sort"; tip: "Sort"; onClicked: bar.fa.sortMenu(sortB) }
        IconBtn { icon: "info"; tip: "Details (Alt + Enter)"; toggled: bar.fa.details; onClicked: bar.fa.details = !bar.fa.details }
        IconBtn { id: moreB; icon: "more_vert"; onClicked: Ui.menu(bar.fa.folderMenu().concat([{ sep: true }, { icon: "open_in_new", text: "New window", key: "Ctrl+N", act: function() { Sys.app("files", [bar.fa.cur]) } }]), moreB, -150, moreB.height) }
    }
}
