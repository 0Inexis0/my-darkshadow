import Quickshell
import Quickshell.Io
import QtQuick

// Wallpaper tab: every wallpaper as a big thumbnail, search, random, folder, color schemes.
Item {
    id: wp
    property var d
    property bool live: false
    readonly property var p: d.p
    property var all: []
    property string current: ""
    property string dir: ""
    property string query: ""
    property var schemes: []
    property string scheme: ""
    readonly property var shown: query === "" ? all : all.filter(function(w) { return w.name.toLowerCase().indexOf(query.toLowerCase()) >= 0 })

    Process {
        id: list
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" walls; echo '@@'; \"$HOME/.local/bin/rice-colors\" list 2>/dev/null; echo '@@'; \"$HOME/.local/bin/rice-colors\" get 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const q = text.split("@@")
                try { const j = JSON.parse(q[0]); wp.all = j.walls; wp.current = j.current; wp.dir = j.dir } catch (e) { }
                try { wp.schemes = JSON.parse(q[1]) } catch (e) { }
                wp.scheme = (q[2] || "").trim()
            }
        }
    }
    onLiveChanged: if (live) { list.running = true; search.text = ""; query = "" }
    // thumbnails are made in the background the first time: look again a bit later
    Timer { interval: 4000; running: wp.live; repeat: true; onTriggered: if (!list.running && wp.all.some(function(w) { return w.thumb === w.path })) list.running = true }

    function apply(path) {
        current = path
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" wall \"$1\"", "_", path])
    }

    // ---------- top row ----------
    DCard {
        id: top
        p: wp.p; live: wp.live; order: 0
        width: parent.width; height: 48
        Row {
            x: 16; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            T { kind: "icon"; text: wp.d.md(0xF02E9); font.pixelSize: 18; color: wp.p.primary; anchors.verticalCenter: parent.verticalCenter }
            T { text: "Wallpapers"; font.pixelSize: 16; font.bold: true; color: wp.p.text; anchors.verticalCenter: parent.verticalCenter }
            T { text: wp.shown.length + (wp.query ? " found" : ""); font.pixelSize: 12; color: wp.p.sub; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            // search
            Rectangle {
                width: 220; height: 34; radius: 17
                color: wp.p.container
                border.width: search.activeFocus ? 2 : 0
                border.color: wp.p.primary
                T { kind: "icon"; x: 12; anchors.verticalCenter: parent.verticalCenter; text: wp.d.md(0xF0349); font.pixelSize: 14; color: wp.p.onContainer }
                TextInput {
                    id: search
                    x: 34; width: parent.width - 46
                    anchors.verticalCenter: parent.verticalCenter
                    color: wp.p.onContainer
                    selectionColor: wp.p.primary
                    font.pixelSize: 13
                    clip: true
                    onTextChanged: wp.query = text
                    Keys.onEscapePressed: { if (text !== "") text = ""; else wp.d.close() }
                    Keys.onReturnPressed: if (wp.shown.length > 0) wp.apply(wp.shown[0].path)
                }
                T { visible: search.text === ""; x: 34; anchors.verticalCenter: parent.verticalCenter; text: "Search"; font.pixelSize: 13; color: wp.p.onContainer; opacity: 0.6 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: search.forceActiveFocus(); z: -1 }
            }
            Pill { icon: wp.d.md(0xF049D); text: "Random"; onClicked: if (wp.all.length) wp.apply(wp.all[Math.floor(Math.random() * wp.all.length)].path) }
            Pill { icon: wp.d.md(0xF024B); text: "Folder"; onClicked: if (wp.dir) { Quickshell.execDetached(["xdg-open", wp.dir]); wp.d.close() } }
        }
    }

    // ---------- grid ----------
    DCard {
        id: gridCard
        p: wp.p; live: wp.live; order: 1
        y: top.height + 10
        width: parent.width; height: parent.height - y - colorsC.height - 10
        clip: true
        GridView {
            id: grid
            anchors.fill: parent
            anchors.margins: 10
            cellWidth: width / Math.max(1, Math.floor(width / 190))
            cellHeight: cellWidth * 0.66
            model: wp.shown
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    const max = Math.max(0, grid.contentHeight - grid.height)
                    grid.contentY = Math.max(0, Math.min(max, grid.contentY - e.angleDelta.y * 0.8))
                }
            }
            delegate: Item {
                width: grid.cellWidth; height: grid.cellHeight
                readonly property bool cur: modelData.path === wp.current
                Rectangle {
                    id: frame
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 16
                    color: wp.p.container
                    border.width: parent.cur ? 3 : 0
                    border.color: wp.p.primary
                    scale: tm.pressed ? 0.96 : (tm.containsMouse ? 1.03 : 1)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    RoundImage {
                        anchors.fill: parent
                        anchors.margins: parent.parent.cur ? 4 : 0
                        cornerRadius: parent.parent.cur ? 12 : 16
                        source: "file://" + modelData.thumb
                        fallback: ""
                    }
                    // name on hover
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.margins: 6
                        height: 24; radius: 10
                        color: Qt.rgba(0, 0, 0, 0.55)
                        opacity: tm.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        T { anchors.centerIn: parent; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name; font.pixelSize: 11; color: "#ffffff" }
                    }
                    Rectangle {
                        visible: parent.parent.cur
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                        width: 22; height: 22; radius: 11
                        color: wp.p.primary
                        T { kind: "icon"; anchors.centerIn: parent; text: wp.d.md(0xF012C); font.pixelSize: 13; color: wp.p.onPrimary }
                    }
                }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wp.apply(modelData.path) }
            }
        }
        T {
            visible: wp.all.length === 0
            anchors.centerIn: parent
            text: "No wallpapers yet. Put pictures in ~/Pictures/Wallpapers"
            font.pixelSize: 13; color: wp.p.sub
        }
    }

    // ---------- color schemes ----------
    DCard {
        id: colorsC
        p: wp.p; live: wp.live; order: 2
        y: parent.height - height
        width: parent.width; height: 46
        Row {
            x: 16; anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            T { kind: "icon"; text: wp.d.md(0xF03D8); font.pixelSize: 15; color: wp.p.primary; anchors.verticalCenter: parent.verticalCenter }
            T { text: "Colors"; font.pixelSize: 13; font.bold: true; color: wp.p.text; anchors.verticalCenter: parent.verticalCenter; width: 52 }
            Repeater {
                model: wp.schemes
                Item {
                    width: 26; height: 26
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool cur: modelData.key === wp.scheme
                    readonly property var pv: modelData.preview || ["#111", "#ddd", "#fff"]
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24; height: 24; radius: 12
                        color: pv[0]
                        border.width: parent.cur ? 2 : 1
                        border.color: parent.cur ? wp.p.primary : Qt.rgba(0.5, 0.5, 0.5, 0.4)
                        scale: sm.containsMouse ? 1.18 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: pv[1] }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { wp.scheme = modelData.key; Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-colors\" mode \"$1\"", "_", modelData.key]) }
                    }
                }
            }
        }
    }

    component Pill: Rectangle {
        id: pl
        property string icon: ""
        property string text: ""
        signal clicked()
        height: 34
        width: plr.implicitWidth + 26
        radius: 17
        color: pm.containsMouse ? wp.p.primary : wp.p.container
        Behavior on color { ColorAnimation { duration: 120 } }
        scale: pm.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Row {
            id: plr
            anchors.centerIn: parent
            spacing: 6
            T { kind: "icon"; text: pl.icon; font.pixelSize: 14; color: pm.containsMouse ? wp.p.onPrimary : wp.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
            T { text: pl.text; font.pixelSize: 12; color: pm.containsMouse ? wp.p.onPrimary : wp.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pl.clicked() }
    }
}
