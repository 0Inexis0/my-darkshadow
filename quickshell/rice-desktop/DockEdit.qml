import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// The dock's own menu (V4.87, V4.89). A right click on the dock opens it next to the pointer: for an app, open it,
// pin or unpin it, move it, close it; for the dock: Add apps, Edit dock and Icons (both open Edit mode on that tab)
// and the dock's page in Settings. It grows out of the spot you clicked (Material 3 menu), its rows one after another.
PanelWindow {
    id: de
    screen: Mon.screen
    property var dock: null
    property var appsMenu: null
    property bool open: false
    property var it: null               // the app the menu is about (null: the dock)
    property real mx: 0
    property real my: 0
    // the screen's size (the window is not up yet when the menu is placed: its own size was 0 then, and the menu
    // ended in the top left corner)
    readonly property real sw: de.screen ? de.screen.width : de.width
    readonly property real sh: de.screen ? de.screen.height : de.height
    property real t: 0
    NumberAnimation { id: tA; target: de; property: "t" }
    // it grows only once the window is on the screen (it started before, so it simply popped up)
    Timer { id: goT; interval: 34; onTriggered: { tA.stop(); tA.from = de.t; tA.to = 1; tA.duration = 460; tA.easing.type = Easing.OutCubic; tA.start() } }
    onOpenChanged: {
        if (open) { goT.restart(); return }
        goT.stop(); tA.stop(); tA.from = t; tA.to = 0; tA.duration = 170; tA.easing.type = Easing.InCubic; tA.start()
    }
    // row i comes in after the ones nearer the dock (the menu grows away from it)
    function stg(i) { const k = fromBottom ? 10 - i : i; return Math.max(0, Math.min(1, (t - 0.08 - k * 0.04) / 0.5)) }

    function menuAt(item, x, y, win) {
        it = item
        // from the dock's window to the screen: the dock sits at an edge, its window in the middle of it
        const e = dock.edge, full = dock.style === "full"
        mx = e === "right" ? sw - (win.width - x) : x + (e === "left" || full ? 0 : (sw - win.width) / 2)
        my = e === "bottom" ? sh - (win.height - y) : y + (full ? 0 : (sh - win.height) / 2)
        t = 0
        open = true
    }
    function close() { open = false }
    function settings() { close(); Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-settings\" 14"]) }
    function edit(sec) { close(); dock.editDock(sec) }

    NPal { id: pal; theme: "shell"; alpha: 0.96 }
    readonly property var dc: dock ? dock.dc : ({})
    readonly property bool vert: dock ? dock.vert : false

    visible: open || t > 0.02
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-dock-edit"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    NiriBlur { win: de; items: [menu]; radius: Look.sq ? 0 : (24); on: de.open && de.t > 0.94 }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: de.close() }
    Item { focus: de.open; Keys.onEscapePressed: de.close() }

    // ---------------------------------------------------------------- the menu
    // it grows out of the dock's side: from the bottom up over a dock at the bottom, sideways over one on the side
    readonly property real et: 1 - Math.pow(1 - t, 3)
    readonly property bool fromBottom: !dock || dock.edge === "bottom"
    Rectangle {
        id: menu
        Frame { }      // V4.98 Minimal mode
        readonly property real fullH: mcol.implicitHeight + 16
        // just off the dock: above it at the bottom, beside it on a side; along it, where you clicked
        readonly property real gap: de.dock ? de.dock.thick + (de.dock.style === "full" ? 0 : 10) + 12 : 80
        readonly property real baseX: Math.max(12, Math.min(de.sw - width - 12, !de.dock || !de.vert ? de.mx - width / 2
                                       : (de.dock.edge === "left" ? gap : de.sw - gap - width)))
        readonly property real baseY: Math.max(12, Math.min(de.sh - fullH - 12, de.fromBottom ? de.sh - gap - fullH : de.my - 24))
        visible: de.t > 0.01
        width: 252
        height: Math.max(40, fullH * (0.42 + 0.58 * de.et))
        x: baseX + (de.vert ? (de.dock.edge === "left" ? -18 : 18) * (1 - de.et) : 0)
        y: de.fromBottom ? baseY + fullH - height : baseY
        radius: Look.sq ? 0 : (24)
        clip: true
        color: pal.surface
        border.width: 1; border.color: pal.line
        opacity: Math.min(1, de.t * 3)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton }
        Column {
            id: mcol
            x: 8
            // the rows stay put against the side it grows from
            y: de.fromBottom ? menu.height - menu.fullH + 8 : 8
            width: parent.width - 16
            spacing: 2
            // the app
            Item {
                visible: !!de.it
                width: parent.width; height: 54
                opacity: de.stg(0)
                AppIcon {
                    x: 8; anchors.verticalCenter: parent.verticalCenter
                    size: 36
                    name: de.it && de.it.entry ? (de.it.entry.icon || "") : (de.it ? de.it.key : "")
                    keys: de.it ? [de.it.key, de.it.entry ? de.it.entry.id : ""] : []
                    look: de.dock ? de.dock.look : "original"
                    shape: de.dock ? de.dock.shape : ""
                    colors: pal
                }
                Column {
                    x: 54; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 62
                    Text { width: parent.width; elide: Text.ElideRight; text: de.it && de.it.entry ? de.it.entry.name : (de.it ? de.it.key : "")
                        color: pal.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                    Text { width: parent.width; elide: Text.ElideRight; color: pal.dim; font.family: Fonts.main; font.pixelSize: 11
                        text: de.it ? ((de.it.tl ? Tr.t("Open") : Tr.t("Not open")) + (de.dock.isPinned(de.it) ? "  ·  " + Tr.t("Pinned") : "")) : "" }
                }
            }
            MItem { idx: 1; visible: !!(de.it && de.it.entry); sym: "open_in_new"; glyph: "\uf35d"; text: de.it && de.it.tl ? Tr.t("New window") : Tr.t("Open")
                onPicked: { de.it.entry.execute(); de.close() } }
            MItem { idx: 2; visible: !!de.it; sym: "keep"; glyph: "\uf08d"; text: de.it && de.dock.isPinned(de.it) ? Tr.t("Unpin from the dock") : Tr.t("Pin to the dock")
                onPicked: { de.dock.pin(de.it, !de.dock.isPinned(de.it)); de.close() } }
            MItem { idx: 3; visible: !!de.it && de.dock.isPinned(de.it); sym: de.vert ? "arrow_upward" : "arrow_back"; glyph: de.vert ? "\uf062" : "\uf060"
                text: de.vert ? Tr.t("Move up") : Tr.t("Move left"); onPicked: de.dock.move(de.it, -1) }
            MItem { idx: 4; visible: !!de.it && de.dock.isPinned(de.it); sym: de.vert ? "arrow_downward" : "arrow_forward"; glyph: de.vert ? "\uf063" : "\uf061"
                text: de.vert ? Tr.t("Move down") : Tr.t("Move right"); onPicked: de.dock.move(de.it, 1) }
            MItem { idx: 5; visible: !!(de.it && de.it.tl); sym: "close"; glyph: "\uf00d"; text: Tr.t("Close"); danger: true
                onPicked: { de.it.tl.close(); de.close() } }
            Item { visible: !!de.it; width: parent.width; height: 9
                Rectangle { anchors.centerIn: parent; width: parent.width - 16; height: 1; color: pal.line } }
            MItem { idx: 6; sym: "add_circle"; glyph: "\uf055"; text: Tr.t("Add apps ..."); onPicked: de.edit("dock-add") }
            MItem { idx: 7; sym: "tune"; glyph: "\uf1de"; text: Tr.t("Edit dock ..."); onPicked: de.edit("dock") }
            MItem { idx: 8; sym: "interests"; glyph: "\udb82\udc31"; text: Tr.t("Icons ..."); onPicked: de.edit("icons") }
            MItem { idx: 9; sym: "settings"; glyph: "\uf013"; text: Tr.t("Dock settings"); onPicked: de.settings() }
        }
    }

    // ---------------------------------------------------------------- pieces
    component MItem: Rectangle {
        id: mi
        property int idx: 0
        property string sym: ""
        property string glyph: ""
        property string text: ""
        property bool danger: false
        signal picked()
        width: parent ? parent.width : 200
        height: visible ? 42 : 0
        radius: Look.sq ? 0 : (14)
        color: mim.containsMouse ? (danger ? Qt.rgba(1, 0.3, 0.3, 0.16) : pal.card) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        opacity: de.stg(mi.idx)
        transform: Translate { y: (de.fromBottom ? 10 : -10) * (1 - de.stg(mi.idx)) }
        MIcon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: mi.sym; glyph: mi.glyph; size: 18; color: mi.danger ? "#ffb4ab" : pal.dim }
        Text { x: 46; anchors.verticalCenter: parent.verticalCenter; text: mi.text; color: mi.danger ? "#ffb4ab" : pal.fg; font.family: Fonts.main; font.pixelSize: 13 }
        MouseArea { id: mim; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mi.picked() }
    }
}
