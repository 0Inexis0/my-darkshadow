import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper tab: big wallpaper cards you scroll sideways, search, random and the folder.
Item {
    id: wp
    property var d
    property bool live: false
    readonly property var p: d.p
    property var all: []
    property string current: ""
    property string dir: ""
    property string query: ""
    readonly property var shown: query === "" ? all : all.filter(function(w) { return w.name.toLowerCase().indexOf(query.toLowerCase()) >= 0 })
    property int sel: 0
    Component.onCompleted: d.wallsTab = wp

    // move the selection (arrows, wheel, buttons); the desktop shows a preview of it
    function move(n) {
        if (shown.length === 0) return
        sel = Math.max(0, Math.min(shown.length - 1, sel + n))
        previewTimer.restart()
    }
    function applySel() { if (shown.length > 0) apply(shown[sel].path) }
    Timer { id: previewTimer; interval: 140; onTriggered: if (wp.shown[wp.sel]) wp.d.previewPath = wp.shown[wp.sel].path }

    Process {
        id: list
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" walls"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { const j = JSON.parse(text); wp.all = j.walls; wp.current = j.current; wp.dir = j.dir } catch (e) { }
                wp.center()
            }
        }
    }
    onShownChanged: if (sel >= shown.length) sel = Math.max(0, shown.length - 1)
    onLiveChanged: { if (live) { list.running = true; search.text = ""; query = ""; wp.center() } else d.typing = false }
    // thumbnails are made in the background the first time: look again a bit later
    Timer { interval: 4000; running: wp.live; repeat: true; onTriggered: if (!list.running && wp.all.some(function(w) { return w.thumb === w.path })) list.running = true }

    function apply(path) {
        current = path
        // keep showing it until the real wallpaper has changed underneath
        d.previewPath = path
        d.keepPreview()
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" wall \"$1\"", "_", path])
    }
    function center() {
        for (let i = 0; i < shown.length; i++) if (shown[i].path === current) { sel = i; car.positionViewAtIndex(i, ListView.Center); return }
    }

    // ---------- top row ----------
    Item {
        id: top
        width: parent.width; height: 40
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            MIcon { name: "wallpaper"; glyph: wp.d.md(0xF02E9); size: 22; color: wp.p.primary; anchors.verticalCenter: parent.verticalCenter }
            DText { text: "Wallpapers"; font.pixelSize: 18; font.weight: Font.DemiBold; color: wp.p.text; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: cnt.implicitWidth + 16; height: 22; radius: 11
                color: wp.p.container
                DText { id: cnt; anchors.centerIn: parent; text: wp.shown.length; font.pixelSize: 11; font.weight: Font.DemiBold; color: wp.p.onContainer }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Rectangle {
                width: 240; height: 38; radius: 19
                color: wp.p.container
                border.width: search.activeFocus ? 2 : 0
                border.color: wp.p.primary
                MIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; glyph: wp.d.md(0xF0349); size: 18; color: wp.p.onContainer }
                TextInput {
                    id: search
                    x: 40; width: parent.width - 54
                    anchors.verticalCenter: parent.verticalCenter
                    color: wp.p.onContainer
                    selectionColor: wp.p.primary
                    font.family: DashFont.sans
                    font.pixelSize: 13
                    clip: true
                    onTextChanged: { wp.query = text; wp.sel = 0; car.positionViewAtBeginning(); if (activeFocus) Sfx.play("type") }
                    onActiveFocusChanged: wp.d.typing = activeFocus
                    Keys.onEscapePressed: { if (text !== "") text = ""; else wp.d.close() }
                    Keys.onReturnPressed: wp.applySel()
                    Keys.onDownPressed: wp.move(1)
                    Keys.onUpPressed: wp.move(-1)
                }
                DText { visible: search.text === ""; x: 40; anchors.verticalCenter: parent.verticalCenter; text: "Search wallpapers"; font.pixelSize: 13; color: wp.p.onContainer; opacity: 0.55 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: search.forceActiveFocus(); z: -1 }
            }
            Pill { icon: "shuffle"; glyph: wp.d.md(0xF049D); text: "Random"; onClicked: if (wp.shown.length) { wp.sel = Math.floor(Math.random() * wp.shown.length); wp.applySel() } }
            Pill { icon: "folder_open"; glyph: wp.d.md(0xF024B); text: "Folder"; onClicked: if (wp.dir) { Quickshell.execDetached(["xdg-open", wp.dir]); wp.d.close() } }
        }
    }

    // ---------- the big cards ----------
    ListView {
        id: car
        y: top.height + 14
        width: parent.width
        height: parent.height - y
        orientation: ListView.Horizontal
        spacing: 16
        clip: true
        model: wp.shown
        currentIndex: wp.sel
        interactive: false
        readonly property real cardH: height - 30
        readonly property real cardW: cardH * 1.6
        // the chosen card glides to the middle
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - cardW) / 2
        preferredHighlightEnd: (width + cardW) / 2
        highlightMoveDuration: 420
        highlightMoveVelocity: -1
        // wheel: down = next (to the right), up = back
        property real acc: 0
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(e) {
                car.acc += (Math.abs(e.angleDelta.y) >= Math.abs(e.angleDelta.x) ? -e.angleDelta.y : -e.angleDelta.x)
                while (car.acc >= 100) { wp.move(1); car.acc -= 120 }
                while (car.acc <= -100) { wp.move(-1); car.acc += 120 }
            }
        }
        delegate: Item {
            id: wc
            width: car.cardW
            height: car.height
            readonly property bool cur: modelData.path === wp.current
            readonly property bool picked: index === wp.sel
            opacity: picked ? 1 : 0.55
            Behavior on opacity { NumberAnimation { duration: 260 } }
            Rectangle {
                id: frame
                width: parent.width
                height: car.cardH
                radius: 22
                color: wp.p.container
                border.width: wc.picked ? 3 : 0
                border.color: wp.p.primary
                scale: tm.pressed ? 0.96 : (wc.picked ? 1 : (tm.containsMouse ? 0.92 : 0.88))
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                RoundImage {
                    anchors.fill: parent
                    anchors.margins: wc.picked ? 5 : 0
                    cornerRadius: wc.picked ? 17 : 22
                    source: "file://" + modelData.thumb
                    fallback: ""
                }
                Rectangle {
                    visible: wc.cur
                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                    width: curRow.implicitWidth + 18; height: 28; radius: 14
                    color: wp.p.primary
                    Row {
                        id: curRow
                        anchors.centerIn: parent
                        spacing: 4
                        MIcon { name: "check"; glyph: wp.d.md(0xF012C); size: 15; color: wp.p.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                        DText { text: "Current"; font.pixelSize: 11; font.weight: Font.DemiBold; color: wp.p.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                    width: setRow.implicitWidth + 24; height: 32; radius: 16
                    color: Qt.rgba(0, 0, 0, 0.55)
                    opacity: wc.picked && !wc.cur ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Row {
                        id: setRow
                        anchors.centerIn: parent
                        spacing: 6
                        MIcon { name: "imagesmode"; glyph: wp.d.md(0xF02E9); size: 16; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
                        DText { text: "Enter or click to set"; font.pixelSize: 12; font.weight: Font.Medium; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            DText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: car.cardH + 8
                width: parent.width - 20
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: modelData.name
                font.pixelSize: 12
                font.weight: wc.picked ? Font.DemiBold : Font.Normal
                color: wc.picked ? wp.p.text : wp.p.sub
            }
            // click: the chosen one is set, another one gets chosen (and previewed)
            MouseArea { id: tm; width: parent.width; height: car.cardH; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (wc.picked) wp.applySel(); else { wp.sel = index; previewTimer.restart() } } }
        }
    }
    // arrows
    Arrow { anchors.left: car.left; anchors.leftMargin: 10; y: car.y + car.cardH / 2 - height / 2; icon: "chevron_left"; glyph: wp.d.md(0xF0141); visible: wp.sel > 0; onClicked: wp.move(-1) }
    Arrow { anchors.right: car.right; anchors.rightMargin: 10; y: car.y + car.cardH / 2 - height / 2; icon: "chevron_right"; glyph: wp.d.md(0xF0142); visible: wp.sel < wp.shown.length - 1; onClicked: wp.move(1) }
    DText {
        visible: wp.all.length === 0
        anchors.centerIn: car
        text: "No wallpapers yet. Put pictures in ~/Pictures/Wallpapers"
        font.pixelSize: 14; color: wp.p.sub
    }

    component Pill: Rectangle {
        id: pl
        property string icon: ""
        property string glyph: ""
        property string text: ""
        signal clicked()
        height: 38
        width: plr.implicitWidth + 28
        radius: 19
        color: pm.containsMouse ? wp.p.primary : wp.p.container
        Behavior on color { ColorAnimation { duration: 140 } }
        scale: pm.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Row {
            id: plr
            anchors.centerIn: parent
            spacing: 6
            MIcon { name: pl.icon; glyph: pl.glyph; size: 18; color: pm.containsMouse ? wp.p.onPrimary : wp.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
            DText { text: pl.text; font.pixelSize: 13; color: pm.containsMouse ? wp.p.onPrimary : wp.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pl.clicked() }
    }
    component Arrow: Rectangle {
        id: arw
        property string icon: ""
        property string glyph: ""
        signal clicked()
        width: 44; height: 44; radius: 22
        color: am.containsMouse ? wp.p.primary : Qt.rgba(0, 0, 0, 0.5)
        Behavior on color { ColorAnimation { duration: 120 } }
        MIcon { anchors.centerIn: parent; name: arw.icon; glyph: arw.glyph; size: 26; color: am.containsMouse ? wp.p.onPrimary : "#ffffff" }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: arw.clicked() }
    }
}
