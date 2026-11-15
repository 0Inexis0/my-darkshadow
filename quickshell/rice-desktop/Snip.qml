import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

// Screenshots (Print, the dashboard): the screen is frozen the moment you press the key, then you pick what to keep.
//   Region   drag a box; move it by dragging inside, resize it by its corners; a loupe shows the pixels while you drag
//   Window   point at a window, click it (Hyprland)
//   Screen   the whole screen
// Enter or the big button saves it (and copies it, Settings > Dashboard), Ctrl+C only copies, E opens it in an
// editor (satty or swappy, when you have one), Esc cancels. 1 / 2 / 3 (or R / W / S) switch the mode.
// rice-hotcorner takes the frozen picture with grim and writes "TIME PICTURE OUTPUT SCALE MODE" to
// ~/.cache/rice/snip-open; the crop is made here at full resolution and handed back to it (shot-done) to keep.
PanelWindow {
    id: sn
    property bool open: false
    property string pic: ""
    property string outName: ""
    property real dpr: 1
    property string mode: "region"           // region | window | screen
    property bool canEdit: false
    property bool busy: false

    // the selection, in logical pixels of this screen
    property real sx: 0
    property real sy: 0
    property real sw: 0
    property real sh: 0
    readonly property bool hasSel: sw >= 4 && sh >= 4
    // what is drawn (glides when it jumps to a window or the whole screen, follows the mouse when you drag)
    property bool glide: false
    property real ax: sx
    property real ay: sy
    property real aw: sw
    property real ah: sh
    Behavior on ax { enabled: sn.glide; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on ay { enabled: sn.glide; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on aw { enabled: sn.glide; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on ah { enabled: sn.glide; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // the windows on this screen (Hyprland), front ones first
    property var wins: []
    property int hoverWin: -1
    // the pointer (for the loupe)
    property real mx: -1
    property real my: -1
    property bool dragging: false

    property real t: 0
    Behavior on t { NumberAnimation { duration: sn.open ? 320 : 160; easing.type: Easing.OutCubic } }

    screen: {
        const l = Quickshell.screens
        for (let i = 0; i < l.length; i++) if (l[i].name === sn.outName) return l[i]
        return Mon.screen
    }
    visible: open || t > 0.01
    color: "black"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-snip"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    NPal { id: pal; theme: "shell"; alpha: 0.94 }
    readonly property string home: Quickshell.env("HOME")
    readonly property string outFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/rice-snip-out.png"

    Trigger {
        name: "snip-open"; fresh: true
        onFired: function(o) {
            const p = o.trim().split(/\s+/)
            if (p.length < 3) return
            sn.pic = p[1]
            sn.outName = p[2]
            const d = parseFloat(p[3]); sn.dpr = isNaN(d) || d <= 0 ? 1 : d
            sn.mode = ["region", "window", "screen"].indexOf(p[4]) >= 0 ? p[4] : "region"
            sn.glide = false
            sn.sx = 0; sn.sy = 0; sn.sw = 0; sn.sh = 0
            sn.wins = []; sn.hoverWin = -1; sn.busy = false
            sn.open = true; sn.t = 1
            ack.running = true
            if (Wm.hypr) winsProc.running = true
            editProc.running = true
            if (sn.mode === "screen") sn.pickScreen()
            focusT.restart()
        }
    }
    Timer { id: focusT; interval: 30; onTriggered: keys.forceActiveFocus() }
    // tells rice-hotcorner the picture was taken in (else it falls back to the plain selection tool)
    Process { id: ack; command: ["bash", "-c", "printf '%s\\n' \"$(date +%s)\" > \"$HOME/.cache/rice/snip-ack\""] }
    Process {
        id: editProc
        command: ["bash", "-c", "command -v satty >/dev/null || command -v swappy >/dev/null"]
        onExited: function(code) { sn.canEdit = code === 0 }
    }
    Process {
        id: winsProc
        command: ["bash", "-c", "printf '{\"m\":%s,\"c\":%s}' \"$(hyprctl -j monitors)\" \"$(hyprctl -j clients)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const m = j.m.find(x => x.name === sn.outName) || j.m.find(x => x.focused)
                    if (!m) return
                    const ws = [m.activeWorkspace ? m.activeWorkspace.id : -1, m.specialWorkspace ? m.specialWorkspace.id : 0]
                    const l = j.c.filter(c => c.mapped !== false && !c.hidden && ws.indexOf(c.workspace.id) >= 0 && c.size[0] > 4)
                    // the special workspace and floating windows lie on top, then the one used last
                    l.sort((a, b) => (b.workspace.id < 0) - (a.workspace.id < 0) || (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
                    sn.wins = l.map(c => ({ x: c.at[0] - m.x, y: c.at[1] - m.y, w: c.size[0], h: c.size[1],
                                            title: c.title || c["class"] || "", app: c["class"] || "" }))
                    if (sn.mode === "window" && sn.mx >= 0) sn.hoverAt(sn.mx, sn.my)
                } catch (e) { sn.wins = [] }
            }
        }
    }

    function setSel(x, y, w, h) { sx = x; sy = y; sw = w; sh = h; ax = x; ay = y; aw = w; ah = h }
    function pickScreen() { glide = true; setSel(0, 0, width, height) }
    function hoverAt(x, y) {
        for (let i = 0; i < wins.length; i++) {
            const w = wins[i]
            if (x >= w.x && x < w.x + w.w && y >= w.y && y < w.y + w.h) {
                if (hoverWin !== i) {
                    hoverWin = i; glide = true
                    const cx = Math.max(0, w.x), cy = Math.max(0, w.y)
                    setSel(cx, cy, Math.min(width, w.x + w.w) - cx, Math.min(height, w.y + w.h) - cy)
                }
                return
            }
        }
        hoverWin = -1
        glide = true; setSel(0, 0, 0, 0)
    }
    function setMode(m) {
        if (m === "window" && !Wm.hypr) return
        mode = m
        Sfx.play("click")
        if (m === "screen") pickScreen()
        else if (m === "window") { hoverWin = -1; hoverAt(mx, my) }
        else { glide = true; setSel(0, 0, 0, 0) }
    }
    function cancel() {
        open = false; t = 0; busy = false
        Quickshell.execDetached(["rm", "-f", pic])
    }
    // the crop at full resolution, handed to rice-hotcorner: save | copy | edit
    function finish(what) {
        if (busy || !hasSel) return
        busy = true
        Sfx.play("select")
        const pw = Math.max(1, Math.round(sw * dpr)), ph = Math.max(1, Math.round(sh * dpr))
        crop.cx = sx; crop.cy = sy; crop.width = sw; crop.height = sh
        crop.grabToImage(function(r) {
            const ok = r.saveToFile(sn.outFile)
            sn.open = false; sn.t = 0
            Quickshell.execDetached(["bash", "-c", "rm -f \"$1\"; " + (ok ? "\"$HOME/.local/bin/rice-hotcorner\" shot-done \"$2\" \"$3\""
                : "notify-send -a \"DarkShadow's Shell\" 'Screenshot failed' 'The picture could not be written'"), "snip", sn.pic, sn.outFile, what])
        }, Qt.size(pw, ph))
    }

    // ---------------- the crop (drawn under everything, only ever grabbed) ----------------
    Item {
        id: crop
        property real cx: 0
        property real cy: 0
        z: -10
        clip: true
        Image {
            x: -crop.cx; y: -crop.cy
            width: sn.width; height: sn.height
            source: frozen.source
            smooth: true
        }
    }

    // ---------------- the frozen screen ----------------
    Image {
        id: frozen
        anchors.fill: parent
        source: sn.pic !== "" ? "file://" + sn.pic : ""
        // the picture has a new name every time, so it can be cached and shared by the crop and the loupe
        asynchronous: false
        smooth: true
        opacity: sn.t > 0 ? 1 : 0
    }

    // dim around the selection (all of it when nothing is chosen)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.52 * t)
    Rectangle { x: 0; y: 0; width: parent.width; height: sn.hasSel ? sn.ay : parent.height; color: sn.scrim }
    Rectangle { visible: sn.hasSel; x: 0; y: sn.ay + sn.ah; width: parent.width; height: Math.max(0, parent.height - sn.ay - sn.ah); color: sn.scrim }
    Rectangle { visible: sn.hasSel; x: 0; y: sn.ay; width: sn.ax; height: sn.ah; color: sn.scrim }
    Rectangle { visible: sn.hasSel; x: sn.ax + sn.aw; y: sn.ay; width: Math.max(0, parent.width - sn.ax - sn.aw); height: sn.ah; color: sn.scrim }

    // ---------------- the mouse ----------------
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: sn.mode === "region" ? (inside(mouseX, mouseY) && !sn.dragging ? Qt.SizeAllCursor : Qt.CrossCursor) : Qt.PointingHandCursor
        property string op: ""          // new | move | tl | tr | bl | br
        property real px: 0
        property real py: 0
        property var start: null
        function inside(x, y) { return sn.hasSel && x >= sn.sx && x <= sn.sx + sn.sw && y >= sn.sy && y <= sn.sy + sn.sh }
        function corner(x, y) {
            if (!sn.hasSel) return ""
            const r = 18
            const L = Math.abs(x - sn.sx) < r, R = Math.abs(x - sn.sx - sn.sw) < r
            const T = Math.abs(y - sn.sy) < r, B = Math.abs(y - sn.sy - sn.sh) < r
            return T && L ? "tl" : T && R ? "tr" : B && L ? "bl" : B && R ? "br" : ""
        }
        onPositionChanged: function(m) {
            sn.mx = m.x; sn.my = m.y
            if (sn.mode === "window" && !pressed) { sn.hoverAt(m.x, m.y); return }
            if (sn.mode !== "region" || !pressed) return
            const dx = m.x - px, dy = m.y - py
            const s = start
            if (op === "new") {
                sn.setSel(Math.min(px, m.x), Math.min(py, m.y), Math.abs(dx), Math.abs(dy))
            } else if (op === "move") {
                sn.setSel(Math.max(0, Math.min(sn.width - s.w, s.x + dx)), Math.max(0, Math.min(sn.height - s.h, s.y + dy)), s.w, s.h)
            } else {
                let x1 = s.x, y1 = s.y, x2 = s.x + s.w, y2 = s.y + s.h
                if (op[1] === "l") x1 += dx; else x2 += dx
                if (op[0] === "t") y1 += dy; else y2 += dy
                sn.setSel(Math.min(x1, x2), Math.min(y1, y2), Math.abs(x2 - x1), Math.abs(y2 - y1))
            }
        }
        onPressed: function(m) {
            if (m.button === Qt.RightButton) { if (sn.hasSel && sn.mode === "region") { sn.glide = true; sn.setSel(0, 0, 0, 0) } else sn.cancel(); return }
            if (sn.mode !== "region") return
            sn.glide = false
            px = m.x; py = m.y
            start = { x: sn.sx, y: sn.sy, w: sn.sw, h: sn.sh }
            const c = corner(m.x, m.y)
            op = c !== "" ? c : (inside(m.x, m.y) ? "move" : "new")
            if (op === "new") sn.setSel(m.x, m.y, 0, 0)
            sn.dragging = true
        }
        onReleased: function(m) {
            sn.dragging = false
            if (m.button !== Qt.LeftButton) return
            if (sn.mode === "window" && sn.hasSel) sn.finish("save")
            else if (sn.mode === "screen") sn.finish("save")
        }
        onDoubleClicked: function(m) { if (sn.mode === "region" && inside(m.x, m.y)) sn.finish("save") }
    }

    // ---------------- the selection ----------------
    Item {
        visible: sn.hasSel || sn.aw > 2
        x: sn.ax; y: sn.ay; width: sn.aw; height: sn.ah
        opacity: sn.t
        Rectangle {
            anchors.fill: parent; anchors.margins: -2
            color: "transparent"; radius: 3
            border.width: 2; border.color: pal.primary
        }
        // corner handles (region): a ring in your key color
        Repeater {
            model: sn.mode === "region" && !sn.busy ? 4 : 0
            delegate: Rectangle {
                width: 14; height: 14; radius: 7
                x: (index % 2 === 0 ? 0 : sn.aw) - 7
                y: (index < 2 ? 0 : sn.ah) - 7
                color: pal.primary
                border.width: 3; border.color: pal.inkPrimary
            }
        }
        // its size, in real pixels (above it; inside when there is no room)
        Rectangle {
            id: sizePill
            visible: sn.hasSel
            readonly property bool above: sn.ay > 44
            x: Math.max(-sn.ax, Math.min(0, sn.width - sn.ax - width))
            y: above ? -height - 10 : 10
            width: sizeRow.implicitWidth + 24; height: 30; radius: 15
            color: pal.surface
            Row {
                id: sizeRow
                anchors.centerIn: parent
                spacing: 8
                Text { anchors.verticalCenter: parent.verticalCenter; visible: sn.mode === "window" && sn.hoverWin >= 0 && sn.wins[sn.hoverWin]
                    text: visible ? sn.wins[sn.hoverWin].app : ""; color: pal.primary; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(sn.sw * sn.dpr) + " × " + Math.round(sn.sh * sn.dpr)
                    color: pal.fg; font.family: Fonts.numbers; font.pixelSize: 12; font.weight: Font.Medium }
            }
        }
    }

    // ---------------- the loupe (while you drag a box) ----------------
    Item {
        id: loupe
        readonly property real size: 132
        readonly property real zoom: 6
        visible: sn.dragging && sn.mode === "region" && sn.mx >= 0
        x: Math.min(sn.width - size - 16, sn.mx + 24)
        y: sn.my + 24 + size > sn.height ? sn.my - size - 24 : sn.my + 24
        width: size; height: size
        // the few pixels around the pointer, straight from the frozen picture on the graphics card (a picture six
        // times the screen's size would be bigger than a texture may be), cut round like RoundImage does
        ShaderEffectSource {
            id: lens
            anchors.fill: parent
            visible: false
            sourceItem: frozen
            readonly property real n: loupe.size / loupe.zoom
            sourceRect: Qt.rect(sn.mx - n / 2, sn.my - n / 2, n, n)
            textureSize: Qt.size(Math.max(1, Math.round(n * sn.dpr)), Math.max(1, Math.round(n * sn.dpr)))
            smooth: false
            live: loupe.visible
        }
        Item {
            id: lensMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle { anchors.fill: parent; radius: 28 }
        }
        MultiEffect { anchors.fill: parent; source: lens; maskEnabled: true; maskSource: lensMask }
        Rectangle { anchors.fill: parent; radius: 28; color: "transparent"; border.width: 3; border.color: pal.primary }
        // the pixel under the pointer
        Rectangle { anchors.centerIn: parent; width: loupe.zoom + 4; height: loupe.zoom + 4; color: "transparent"; border.width: 2; border.color: "white" }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: 8
            width: posT.implicitWidth + 18; height: 24; radius: 12; color: pal.surface
            Text { id: posT; anchors.centerIn: parent; text: Math.round(sn.mx * sn.dpr) + ", " + Math.round(sn.my * sn.dpr)
                color: pal.fg; font.family: Fonts.numbers; font.pixelSize: 11 }
        }
    }

    // ---------------- the toolbar ----------------
    component ModeBtn: Rectangle {
        id: mb
        property string m: ""
        property string label: ""
        property string icon: ""
        property string glyph: ""
        readonly property bool on: sn.mode === m
        enabled: m !== "window" || Wm.hypr
        opacity: enabled ? 1 : 0.35
        height: 44; radius: 22
        width: on ? mbRow.implicitWidth + 32 : 48
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        color: on ? pal.container : (mbM.containsMouse ? pal.cardHi : "transparent")
        Behavior on color { ColorAnimation { duration: 160 } }
        clip: true
        Row {
            id: mbRow
            anchors.centerIn: parent
            spacing: 8
            MIcon { anchors.verticalCenter: parent.verticalCenter; size: 20; name: mb.icon; glyph: mb.glyph; color: mb.on ? pal.inkContainer : pal.fg }
            Text { anchors.verticalCenter: parent.verticalCenter; visible: mb.on; text: mb.label; color: pal.inkContainer
                font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
        }
        MouseArea { id: mbM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sn.setMode(mb.m) }
    }
    component IconBtn: Rectangle {
        id: ib
        property string icon: ""
        property string glyph: ""
        property string tip: ""
        signal clicked()
        width: 44; height: 44; radius: 22
        color: ibM.containsMouse ? pal.cardHi : "transparent"
        Behavior on color { ColorAnimation { duration: 160 } }
        MIcon { anchors.centerIn: parent; size: 20; name: ib.icon; glyph: ib.glyph; color: pal.fg }
        MouseArea { id: ibM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
        Rectangle {
            visible: ibM.containsMouse && ib.tip !== ""
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 10
            width: tipT.implicitWidth + 18; height: 26; radius: 8; color: pal.fg
            Text { id: tipT; anchors.centerIn: parent; text: ib.tip; color: pal.surface; font.family: Fonts.main; font.pixelSize: 12 }
        }
    }

    Shadow { anchors.fill: bar; radius: bar.radius; opacity: bar.opacity; on: Look.shadows }
    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - 36 + (1 - sn.t) * 40
        opacity: sn.t
        width: barRow.implicitWidth + 16; height: 60; radius: 30
        color: pal.surface
        border.width: 1; border.color: pal.line
        // over the selection: it moves up out of the way
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }     // clicks on the bar never start a box
        Row {
            id: barRow
            anchors.centerIn: parent
            spacing: 4
            Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter
                ModeBtn { m: "region"; label: Tr.t("Region"); icon: "crop_free"; glyph: String.fromCodePoint(0xF0489) }
                ModeBtn { m: "window"; label: Tr.t("Window"); icon: "select_window"; glyph: String.fromCodePoint(0xF05AF) }
                ModeBtn { m: "screen"; label: Tr.t("Screen"); icon: "fullscreen"; glyph: String.fromCodePoint(0xF0379) }
            }
            Rectangle { width: 1; height: 28; color: pal.line; anchors.verticalCenter: parent.verticalCenter }
            IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "content_copy"; glyph: String.fromCodePoint(0xF018F); tip: Tr.t("Copy") + "  Ctrl+C"; onClicked: sn.finish("copy") }
            IconBtn { anchors.verticalCenter: parent.verticalCenter; visible: sn.canEdit; icon: "edit"; glyph: String.fromCodePoint(0xF03EB); tip: Tr.t("Edit") + "  E"; onClicked: sn.finish("edit") }
            // the main action: a filled pill in your key color
            Rectangle {
                id: shoot
                anchors.verticalCenter: parent.verticalCenter
                height: 44; radius: 22
                width: shootRow.implicitWidth + 36
                opacity: sn.hasSel ? 1 : 0.4
                color: shootM.pressed ? Qt.darker(pal.primary, 1.12) : (shootM.containsMouse ? Qt.lighter(pal.primary, 1.06) : pal.primary)
                scale: shootM.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
                Row {
                    id: shootRow
                    anchors.centerIn: parent
                    spacing: 8
                    MIcon { anchors.verticalCenter: parent.verticalCenter; size: 20; name: "photo_camera"; glyph: String.fromCodePoint(0xF0100); color: pal.inkPrimary }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Tr.t("Save"); color: pal.inkPrimary
                        font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                }
                MouseArea { id: shootM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sn.finish("save") }
            }
            IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: "close"; glyph: String.fromCodePoint(0xF0156); tip: Tr.t("Cancel") + "  Esc"; onClicked: sn.cancel() }
        }
    }
    Text {
        anchors.horizontalCenter: bar.horizontalCenter
        anchors.top: bar.bottom; anchors.topMargin: 8
        opacity: 0.85 * sn.t
        text: sn.mode === "region" ? Tr.t("Drag to choose · Enter saves · Ctrl+C copies · Esc cancels")
            : sn.mode === "window" ? Tr.t("Click a window to save it · Esc cancels")
            : Tr.t("Click or Enter saves the whole screen · Esc cancels")
        color: "white"; style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.5)
        font.family: Fonts.main; font.pixelSize: 12
    }

    // ---------------- keys ----------------
    Item {
        id: keys
        focus: true
        Keys.onPressed: function(e) {
            const k = e.key
            if (k === Qt.Key_Escape) sn.cancel()
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) sn.finish("save")
            else if (k === Qt.Key_C && (e.modifiers & Qt.ControlModifier)) sn.finish("copy")
            else if (k === Qt.Key_E && sn.canEdit) sn.finish("edit")
            else if (k === Qt.Key_1 || k === Qt.Key_R) sn.setMode("region")
            else if (k === Qt.Key_2 || k === Qt.Key_W) sn.setMode("window")
            else if (k === Qt.Key_3 || k === Qt.Key_S || k === Qt.Key_F) sn.setMode("screen")
            else if (k === Qt.Key_A && (e.modifiers & Qt.ControlModifier)) sn.setMode("screen")
            else return
            e.accepted = true
        }
    }
}
