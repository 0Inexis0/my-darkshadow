import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// SUPER + W: your wallpapers in a Material 3 sheet (it took the place of the dashboard's Wallpaper tab).
// Type to search, arrows and Enter to pick, Esc or a click outside to close; the shuffle button picks one at
// random. The one you have now wears a check in your shape. Thumbnails come from rice-dashboard walls.
PanelWindow {
    id: wp
    property bool open: false
    property real t: 0
    Behavior on t { NumberAnimation { duration: wp.open ? 520 : 200; easing.type: Easing.Linear } }
    function ease(p) { return 1 - Math.pow(1 - Math.max(0, Math.min(1, p)), 4) }
    readonly property real et: ease(t)
    onOpenChanged: {
        t = open ? 1 : 0
        if (open) { query = ""; search.text = ""; list.running = true; focusT.restart() }
    }
    NPal { id: pal; theme: "shell"; alpha: 0.94 }

    visible: open || t > 0.01
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-walls"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Trigger { name: "walls-open"; onFired: function(l) { wp.open = !wp.open } }

    // ---------- the wallpapers ----------
    property var all: []
    property string current: ""
    property string query: ""
    readonly property var shown: query === "" ? all : all.filter(function(w) { return w.name.toLowerCase().indexOf(wp.query.toLowerCase()) >= 0 })
    property int sel: 0
    Process {
        id: list
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" walls"]
        stdout: StdioCollector { onStreamFinished: {
            try { const j = JSON.parse(text); wp.all = j.walls; wp.current = j.current } catch (e) { }
            for (let i = 0; i < wp.shown.length; i++) if (wp.shown[i].path === wp.current) { wp.sel = i; grid.positionViewAtIndex(i, GridView.Center); break }
        } }
    }
    // thumbnails are made in the background the first time: look again a bit later
    Timer { interval: 4000; running: wp.open; repeat: true; onTriggered: if (!list.running && wp.all.some(function(w) { return w.thumb === w.path })) list.running = true }
    function apply(path) {
        current = path
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" wall \"$1\"", "_", path])
    }
    function shuffle() { if (shown.length > 0) { sel = Math.floor(Math.random() * shown.length); grid.positionViewAtIndex(sel, GridView.Contain); apply(shown[sel].path) } }
    onShownChanged: if (sel >= shown.length) sel = Math.max(0, shown.length - 1)
    Timer { id: focusT; interval: 60; onTriggered: search.forceActiveFocus() }

    // ---------- the scrim: a click outside closes ----------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.32 * wp.et)
        MouseArea { anchors.fill: parent; onClicked: wp.open = false }
    }

    // ---------- the sheet ----------
    Shadow { anchors.fill: sheet; radius: sheet.radius; on: Look.shadows && Look.shadowPanels; opacity: sheet.opacity; size: Look.shadowSize; strength: Look.shadowStrength }
    Rectangle {
        id: sheet
        width: Math.min(parent.width - 80, 980); height: Math.min(parent.height - 120, 620)
        anchors.centerIn: parent
        radius: 32
        color: pal.surface
        opacity: Math.min(1, wp.et * 1.5)
        scale: 0.92 + 0.08 * wp.et
        transform: Translate { y: (1 - wp.et) * 30 }
        clip: true
        MouseArea { anchors.fill: parent }          // clicks on the sheet stay on it

        // header
        Item {
            id: head
            x: 24; y: 20; width: parent.width - 48; height: 48
            Item { id: hIc; width: 46; height: 46; anchors.verticalCenter: parent.verticalCenter
                Blob { anchors.fill: parent; kind: Look.shape; color: pal.container
                    RotationAnimator on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: wp.open && !Look.lite } }
                MIcon { anchors.centerIn: parent; size: 22; filled: true; name: "wallpaper"; glyph: ""; color: pal.inkContainer } }
            Column {
                anchors.left: hIc.right; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                Text { text: "Wallpapers"; color: pal.fg; font.family: Fonts.main; font.pixelSize: 20; font.weight: Font.DemiBold }
                Text { text: wp.shown.length + (wp.shown.length === 1 ? " wallpaper" : " wallpapers") + "  ·  colors follow"; color: pal.dim; font.family: Fonts.main; font.pixelSize: 12 }
            }
            Row {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                // search
                Rectangle {
                    width: 280; height: 44; radius: 22; color: pal.card
                    border.width: search.activeFocus ? 2 : 0; border.color: pal.primary
                    MIcon { x: 14; anchors.verticalCenter: parent.verticalCenter; size: 18; name: "search"; glyph: ""; color: pal.dim }
                    TextInput {
                        id: search
                        x: 42; width: parent.width - 56; anchors.verticalCenter: parent.verticalCenter
                        color: pal.fg; font.family: Fonts.main; font.pixelSize: 14; clip: true
                        selectionColor: pal.primary; selectedTextColor: pal.inkPrimary
                        onTextChanged: { wp.query = text; wp.sel = 0 }
                        Text { visible: search.text === ""; text: "Search"; color: pal.dim; font: search.font }
                        Keys.onPressed: function(e) {
                            const cols = Math.max(1, Math.floor(grid.width / grid.cellWidth))
                            if (e.key === Qt.Key_Escape) { wp.open = false; e.accepted = true }
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { if (wp.shown[wp.sel]) wp.apply(wp.shown[wp.sel].path); e.accepted = true }
                            else if (e.key === Qt.Key_Right) { wp.sel = Math.min(wp.shown.length - 1, wp.sel + 1); e.accepted = true }
                            else if (e.key === Qt.Key_Left) { wp.sel = Math.max(0, wp.sel - 1); e.accepted = true }
                            else if (e.key === Qt.Key_Down) { wp.sel = Math.min(wp.shown.length - 1, wp.sel + cols); e.accepted = true }
                            else if (e.key === Qt.Key_Up) { wp.sel = Math.max(0, wp.sel - cols); e.accepted = true }
                            if (e.accepted) { const y0 = grid.contentY; grid.positionViewAtIndex(wp.sel, GridView.Contain); const y1 = grid.contentY
                                if (y1 !== y0) { grid.contentY = y0; grid.scrollBy(y1 - y0) } }
                        }
                    }
                }
                IconBtn { icon: "shuffle"; filled: true; onHit: wp.shuffle() }
                IconBtn { icon: "close"; onHit: wp.open = false }
            }
        }

        // the grid
        GridView {
            id: grid
            x: 24; y: 88; width: parent.width - 48; height: parent.height - 88 - 20
            clip: true
            readonly property int cols: Math.max(2, Math.floor(width / 230))
            cellWidth: Math.floor(width / cols); cellHeight: Math.round(cellWidth * 0.68)
            model: wp.shown
            boundsBehavior: Flickable.StopAtBounds
            // the wheel: farther per notch, and it glides there (touchpads scroll as they are)
            property real goal: 0
            NumberAnimation { id: glide; target: grid; property: "contentY"; duration: 380; easing.type: Easing.OutCubic }
            function scrollBy(dy) {
                const top = grid.originY, bottom = Math.max(grid.originY, grid.contentHeight + grid.originY - grid.height)
                goal = Math.max(top, Math.min(bottom, (glide.running ? goal : contentY) + dy))
                glide.stop(); glide.from = contentY; glide.to = goal; glide.start()
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    if (e.pixelDelta.y !== 0) { glide.stop(); grid.contentY = Math.max(grid.originY, Math.min(Math.max(grid.originY, grid.contentHeight + grid.originY - grid.height), grid.contentY - e.pixelDelta.y * 1.4)) }
                    else grid.scrollBy(-e.angleDelta.y / 120 * grid.cellHeight * 0.9)
                }
            }
            delegate: Item {
                id: cell
                width: grid.cellWidth; height: grid.cellHeight
                readonly property bool cur: modelData.path === wp.current
                readonly property bool picked: index === wp.sel
                // comes in one after another when the sheet opens
                readonly property real it: wp.ease((wp.t - Math.min(index, 18) * 0.025) / 0.55)
                opacity: it
                transform: Translate { y: (1 - cell.it) * 18 }
                Rectangle {
                    id: frame
                    anchors.fill: parent; anchors.margins: 6
                    radius: cell.cur ? 28 : 20
                    Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                    color: pal.card
                    scale: cm.pressed ? 0.96 : (cm.containsMouse || cell.picked ? 1.02 : 1)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    RoundImage { anchors.fill: parent; anchors.margins: cell.cur ? 4 : 0; cornerRadius: frame.radius - (cell.cur ? 4 : 0); source: "file://" + modelData.thumb }
                    Rectangle { anchors.fill: parent; radius: frame.radius; color: "transparent"
                        border.width: cell.cur ? 3 : (cell.picked ? 2 : 0); border.color: cell.cur ? pal.primary : Qt.rgba(pal.fg.r, pal.fg.g, pal.fg.b, 0.6) }
                    // the one you have: a check in your shape
                    Item { visible: cell.cur; width: 30; height: 30; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                        Blob { anchors.fill: parent; kind: Look.shape; color: pal.primary }
                        MIcon { anchors.centerIn: parent; size: 16; filled: true; name: "check"; glyph: ""; color: pal.inkPrimary } }
                    // its name on hover
                    Rectangle {
                        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 10
                        width: Math.min(parent.width - 20, nm.implicitWidth + 20); height: 26; radius: 13
                        color: Qt.rgba(0, 0, 0, 0.55)
                        opacity: cm.containsMouse || cell.picked ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Text { id: nm; anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - 20); elide: Text.ElideRight
                            text: modelData.name; color: "white"; font.family: Fonts.main; font.pixelSize: 11 }
                    }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { wp.sel = index; wp.apply(modelData.path) } }
                }
            }
            // nothing found / no wallpapers
            Text { anchors.centerIn: parent; visible: wp.shown.length === 0 && !list.running
                text: wp.all.length === 0 ? "No wallpapers yet" : "Nothing matches"; color: pal.dim; font.family: Fonts.main; font.pixelSize: 14 }
        }
    }

    component IconBtn: Item {
        id: ib
        property string icon: ""
        property bool filled: false
        signal hit()
        width: 44; height: 44
        Rectangle { anchors.fill: parent; radius: ibm.pressed ? 14 : 22; color: ib.filled ? pal.primary : pal.card
            Behavior on radius { NumberAnimation { duration: 200 } } }
        MIcon { anchors.centerIn: parent; size: 20; filled: true; name: ib.icon; glyph: ""; color: ib.filled ? pal.inkPrimary : pal.fg }
        MouseArea { id: ibm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ib.hit() }
    }
}
