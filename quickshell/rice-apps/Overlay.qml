import QtQuick

// Everything that floats over an app: the menus, the dialogs, the snackbar and the tooltips. One per window; it puts
// itself into Ui.host, so any part reaches it with Ui.menu(...), Ui.ask(...), Ui.snack(...), Ui.tip(...).
Item {
    id: ov
    objectName: "overlay"
    anchors.fill: parent
    z: 1000
    readonly property bool modal: menu.open || dlg.open
    property var back: null           // what had the keyboard before a menu or a dialog took it
    Component.onCompleted: Ui.host = ov
    function keep() { back = Window.activeFocusItem }
    function giveBack() { if (back) { try { back.forceActiveFocus() } catch (e) { } } back = null }

    // ---------------------------------------------------------------- menu
    property var items: []
    property real menuW: 220
    FontMetrics { id: fmT; font.family: Theme.font; font.pixelSize: 14 }
    FontMetrics { id: fmS; font.family: Theme.font; font.pixelSize: 12 }
    function openMenu(list, src, mx, my) {
        hideTip(null)
        items = list.filter(function(i) { return i && (i.sep || i.text) })
        let w = 0
        for (let i = 0; i < items.length; i++) {
            const it = items[i]
            if (it.sep) continue
            w = Math.max(w, fmT.advanceWidth(it.text) + (it.key ? fmS.advanceWidth(it.key) + 28 : 0))
        }
        menuW = Math.ceil(w) + 12 + 12 + 22 + 12 + 24
        let p = src ? src.mapToItem(ov, mx || 0, my !== undefined ? my : src.height) : Qt.point(mx, my)
        menu.ox = p.x; menu.oy = p.y
        keep()
        menu.cur = -1
        menu.open = true
        menu.forceActiveFocus()
    }
    function closeMenu() { if (menu.open) { menu.open = false; giveBack() } }
    MouseArea {
        anchors.fill: parent
        visible: menu.open
        acceptedButtons: Qt.AllButtons
        onPressed: ov.closeMenu()
        onWheel: ov.closeMenu()
    }
    Rectangle {
        id: menu
        property bool open: false
        property real ox: 0
        property real oy: 0
        property int cur: -1
        readonly property bool up: oy + col.implicitHeight + 16 > ov.height
        readonly property bool toLeft: ox + width + 8 > ov.width
        width: Math.max(200, Math.min(ov.width - 16, 420, ov.menuW))
        height: col.implicitHeight + 12
        x: Math.max(8, Math.min(ov.width - width - 8, left ? ox - width : ox))
        y: Math.max(8, Math.min(ov.height - height - 8, up ? oy - height : oy + 4))
        radius: Theme.sq ? 0 : (Theme.rL)
        color: Theme.surfaceC
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.6)
        visible: opacity > 0.01
        opacity: open ? 1 : 0
        scale: open ? 1 : 0.9
        transformOrigin: up ? (toLeft ? Item.BottomRight : Item.BottomLeft) : (toLeft ? Item.TopRight : Item.TopLeft)
        Behavior on opacity { NumberAnimation { duration: Theme.d(menu.open ? 180 : 120) } }
        Behavior on scale { NumberAnimation { duration: Theme.d(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        Rectangle { anchors.fill: parent; anchors.margins: -1; anchors.topMargin: 4; anchors.bottomMargin: -6; radius: Theme.sq ? 0 : (parent.radius + 2); color: Qt.rgba(0, 0, 0, 0.28); z: -1 }
        Keys.onEscapePressed: ov.closeMenu()
        Keys.onDownPressed: step(1)
        Keys.onUpPressed: step(-1)
        Keys.onReturnPressed: if (cur >= 0) ov.run(ov.items[cur])
        function step(d) {
            let i = cur
            for (let n = 0; n < ov.items.length; n++) {
                i = (i + d + ov.items.length) % ov.items.length
                const it = ov.items[i]
                if (!it.sep && it.enabled !== false) { cur = i; return }
            }
        }
        Column {
            id: col
            x: 6; y: 6
            width: menu.width - 12
            Repeater {
                model: menu.open ? ov.items : []
                Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool off: modelData.enabled === false
                    width: col.width
                    implicitWidth: rowIn.implicitWidth + 40
                    height: modelData.sep ? 9 : 44
                    Rectangle { visible: !!row.modelData.sep; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.outlineVariant }
                    Rectangle {
                        visible: !row.modelData.sep
                        anchors.fill: parent
                        radius: Theme.sq ? 0 : (Theme.rS)
                        color: row.modelData.danger ? Theme.error : Theme.ink
                        opacity: row.off ? 0 : (im.pressed ? 0.14 : (im.containsMouse || menu.cur === row.index ? 0.08 : 0))
                    }
                    Row {
                        id: rowIn
                        visible: !row.modelData.sep
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        spacing: 12
                        opacity: row.off ? 0.38 : 1
                        Ic { name: row.modelData.icon || ""; size: 20; width: 22; color: row.modelData.danger ? Theme.error : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
                        T { text: row.modelData.text || ""; color: row.modelData.danger ? Theme.error : Theme.ink; anchors.verticalCenter: parent.verticalCenter }
                    }
                    T { visible: !row.modelData.sep && !!row.modelData.key; text: row.modelData.key || ""; role: "small"; color: Theme.inkVar
                        anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; enabled: !row.off && !row.modelData.sep
                        cursorShape: Qt.PointingHandCursor; onClicked: ov.run(row.modelData); onContainsMouseChanged: if (containsMouse) menu.cur = row.index }
                }
            }
        }
    }
    function run(it) {
        if (!it || it.sep || it.enabled === false) return
        closeMenu()
        if (typeof it.act === "function") Qt.callLater(it.act)
    }

    // ---------------------------------------------------------------- dialog
    property var dlgO: ({})
    function ask(o) {
        closeMenu()
        dlgO = o
        field.text = o.field !== undefined ? String(o.field) : ""
        keep()
        dlg.open = true
        if (o.field !== undefined) {
            field.forceActiveFocus()
            const s = o.select || [0, field.text.length]
            field.select(s[0], s[1])
        } else dlg.forceActiveFocus()
    }
    function answer(ok) {
        if (!dlg.open) return
        const o = dlgO, v = field.text
        if (ok && o.field !== undefined && v.trim() === "") return
        dlg.open = false
        giveBack()
        if (ok && typeof o.onOk === "function") o.onOk(v)
        if (!ok && typeof o.onCancel === "function") o.onCancel()
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: dlg.open ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.d(200) } }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: ov.answer(false); onWheel: {} }
    }
    Rectangle {
        id: dlg
        property bool open: false
        width: Math.min(ov.width - 48, 420)
        height: dc.implicitHeight + 48
        anchors.centerIn: parent
        radius: Theme.sq ? 0 : (Theme.rXL)
        color: Theme.surfaceHigh
        visible: opacity > 0.01
        opacity: open ? 1 : 0
        scale: open ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Theme.d(180) } }
        Behavior on scale { NumberAnimation { duration: Theme.d(320); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        Keys.onEscapePressed: ov.answer(false)
        Keys.onReturnPressed: ov.answer(true)
        MouseArea { anchors.fill: parent }
        Column {
            id: dc
            x: 24; y: 24
            width: dlg.width - 48
            spacing: 16
            Ic { visible: !!ov.dlgO.icon; name: ov.dlgO.icon || ""; size: 26; color: ov.dlgO.danger ? Theme.error : Theme.secondary; anchors.horizontalCenter: parent.horizontalCenter }
            T { text: ov.dlgO.title || ""; role: "headline"; width: parent.width; wrapMode: Text.Wrap; elide: Text.ElideNone
                horizontalAlignment: ov.dlgO.icon ? Text.AlignHCenter : Text.AlignLeft }
            T { visible: !!ov.dlgO.text; text: ov.dlgO.text || ""; color: Theme.inkVar; width: parent.width; wrapMode: Text.Wrap; elide: Text.ElideNone; maximumLineCount: 8 }
            Rectangle {
                visible: ov.dlgO.field !== undefined
                width: parent.width; height: 56
                radius: Theme.sq ? 0 : (Theme.rXS)
                color: "transparent"
                border.width: field.activeFocus ? 2 : 1
                border.color: field.activeFocus ? Theme.primary : Theme.outline
                TextInput {
                    id: field
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.font; font.pixelSize: 16
                    color: Theme.ink
                    selectionColor: Theme.alpha(Theme.primary, 0.4)
                    selectedTextColor: Theme.ink
                    selectByMouse: true
                    clip: true
                    Keys.onEscapePressed: ov.answer(false)
                    onAccepted: ov.answer(true)
                }
            }
            Row {
                anchors.right: parent.right
                spacing: 8
                Btn { kind: "text"; text: ov.dlgO.cancel || "Cancel"; visible: ov.dlgO.cancel !== ""; onClicked: ov.answer(false) }
                Btn { kind: ov.dlgO.danger ? "danger" : "filled"; text: ov.dlgO.ok || "OK"; onClicked: ov.answer(true) }
            }
        }
    }

    // ---------------------------------------------------------------- snackbar
    property string snackText: ""
    property string snackAct: ""
    property var snackFn: null
    property real prog: -2            // -2: no progress; -1: busy without a number; 0..1
    function snack(text, action, fn) { prog = -2; snackText = text; snackAct = action || ""; snackFn = fn || null; sb.open = true; sbT.restart() }
    function progress(text, v) {
        if (v === null || v === undefined || v >= 1) { if (prog > -2) { prog = -2; sb.open = false } return }
        prog = v; snackText = text; snackAct = ""; sb.open = true; sbT.stop()
    }
    Timer { id: sbT; interval: 4200; onTriggered: sb.open = false }
    Rectangle {
        id: sb
        property bool open: false
        width: Math.min(ov.width - 32, Math.max(300, sbRow.implicitWidth + 32))
        height: ov.prog > -2 ? 64 : 48
        anchors.horizontalCenter: parent.horizontalCenter
        y: open ? ov.height - height - 20 : ov.height + 10
        Behavior on y { NumberAnimation { duration: Theme.d(360); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        radius: Theme.sq ? 0 : (Theme.rM)
        color: Theme.dark ? "#e3e2e6" : "#303034"
        visible: y < ov.height
        Row {
            id: sbRow
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: ov.prog > -2 ? -6 : 0
            spacing: 16
            T { text: ov.snackText; color: Theme.dark ? "#303034" : "#e3e2e6"; width: Math.min(implicitWidth, ov.width - 180); anchors.verticalCenter: parent.verticalCenter }
            T { visible: ov.snackAct !== ""; text: ov.snackAct; role: "label"; color: Theme.mix(Theme.primary, "#000000", Theme.dark ? 0.45 : 0); anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor
                    onClicked: { sb.open = false; if (typeof ov.snackFn === "function") ov.snackFn() } } }
        }
        Rectangle {
            visible: ov.prog > -2
            x: 16; width: parent.width - 32; height: 4; radius: Theme.sq ? 0 : (2)
            anchors.bottom: parent.bottom; anchors.bottomMargin: 14
            color: Theme.alpha(Theme.dark ? "#303034" : "#e3e2e6", 0.18)
            clip: true
            Rectangle {
                visible: ov.prog >= 0
                height: parent.height; radius: Theme.sq ? 0 : (2)
                color: Theme.mix(Theme.primary, "#000000", Theme.dark ? 0.45 : 0)
                width: parent.width * Math.max(0, ov.prog)
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                id: bar
                visible: ov.prog === -1
                height: parent.height; radius: Theme.sq ? 0 : (2)
                width: parent.width * 0.3
                color: Theme.mix(Theme.primary, "#000000", Theme.dark ? 0.45 : 0)
                NumberAnimation on x {
                    running: ov.prog === -1 && sb.visible
                    loops: Animation.Infinite
                    from: -bar.width; to: bar.parent.width; duration: 1100; easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // ---------------------------------------------------------------- tooltip
    property var tipSrc: null
    property string tipText: ""
    function showTip(src, text) { tipSrc = src; tipText = text; tip.shown = false; tipT.restart() }
    function hideTip(src) { if (src === null || src === tipSrc) { tipT.stop(); tip.shown = false; tipSrc = null } }
    Timer { id: tipT; interval: 550; onTriggered: if (ov.tipSrc && !ov.modal) { tip.place(); tip.shown = true } }
    Rectangle {
        id: tip
        property bool shown: false
        function place() {
            const s = ov.tipSrc; if (!s) return
            const p = s.mapToItem(ov, s.width / 2, s.height)
            x = Math.max(6, Math.min(ov.width - width - 6, p.x - width / 2))
            y = p.y + 6 + height > ov.height ? s.mapToItem(ov, 0, 0).y - height - 6 : p.y + 6
        }
        width: tt.implicitWidth + 16
        height: 26
        radius: Theme.sq ? 0 : (Theme.rXS)
        color: Theme.dark ? "#e3e2e6" : "#303034"
        opacity: shown ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 140 } }
        T { id: tt; anchors.centerIn: parent; text: ov.tipText; role: "small"; color: Theme.dark ? "#303034" : "#e3e2e6" }
    }
}
