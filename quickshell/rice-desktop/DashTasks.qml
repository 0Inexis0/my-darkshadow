import Quickshell
import Quickshell.Io
import QtQuick

// Tasks tab: a focus timer, the to-do list and a note (the same list and note as the desktop widgets).
Item {
    id: t
    property var d
    property bool live: false
    readonly property var p: d.p

    // ---------- focus timer: keeps running while the dashboard is closed ----------
    readonly property var modeLen: ({ focus: 25 * 60, short: 5 * 60, long: 15 * 60 })
    property string fmode: "focus"
    property bool frun: false
    property real fend: 0
    property int fleft: modeLen[fmode]
    property int fdone: 0
    function fstart() { fend = Date.now() + fleft * 1000; frun = true }
    function fpause() { fleft = Math.max(0, Math.round((fend - Date.now()) / 1000)); frun = false }
    function freset() { frun = false; fleft = modeLen[fmode] }
    function fmodeSet(m) { fmode = m; freset() }
    function ffinish() {
        frun = false
        if (fmode === "focus") {
            fdone++
            Quickshell.execDetached(["notify-send", "-a", "Focus", "Focus session finished", fdone % 4 === 0 ? "Time for a long break" : "Take a short break"])
            fmode = fdone % 4 === 0 ? "long" : "short"
        } else {
            Quickshell.execDetached(["notify-send", "-a", "Focus", "Break is over", "Ready for the next focus session?"])
            fmode = "focus"
        }
        fleft = modeLen[fmode]
        Sfx.play("done")
    }
    Timer {
        interval: 500; running: t.frun; repeat: true
        onTriggered: { const s = Math.max(0, Math.round((t.fend - Date.now()) / 1000)); t.fleft = s; if (s <= 0) t.ffinish() }
    }
    function mmss(s) { return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    // ---------- note ----------
    property bool noteLoaded: false
    property string noteText: ""
    Process {
        command: ["bash", "-c", "cat \"$HOME/.config/rice/note.txt\" 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { if (!t.noteLoaded) { t.noteText = text.replace(/\n$/, ""); t.noteLoaded = true } } }
    }
    Timer {
        id: noteSave; interval: 700
        onTriggered: Quickshell.execDetached(["bash", "-c", "mkdir -p \"$HOME/.config/rice\" && printf '%s\\n' \"$1\" > \"$HOME/.config/rice/note.txt\"", "_", t.noteText])
    }

    onLiveChanged: if (live) d.todoRefresh()

    DashGrid {
        anchors.fill: parent
        d: t.d
        tabId: "tasks"
        layoutKey: t.d.side ? "tasks-side" : ""
        cols: t.d.side ? 6 : 12
        rows: t.d.side ? 6 : 3
        live: t.live
        catalog: [
            { id: "focus", name: "Focus timer", sizes: [[3, 3], [4, 3], [3, 2], [4, 2], [6, 2]] },
            { id: "todo", name: "To-do", sizes: [[5, 3], [6, 3], [4, 3], [5, 2], [6, 2]], min: [3, 2] },
            { id: "note", name: "Note", sizes: [[4, 3], [3, 3], [5, 3], [4, 2], [6, 2]], min: [2, 1] }
        ]
        defaults: t.d.side ? [
            { id: "focus", x: 0, y: 0, w: 6, h: 2 }, { id: "todo", x: 0, y: 2, w: 6, h: 2 }, { id: "note", x: 0, y: 4, w: 6, h: 2 }
        ] : [
            { id: "todo", x: 0, y: 0, w: 5, h: 3 }, { id: "note", x: 5, y: 0, w: 4, h: 3 }, { id: "focus", x: 9, y: 0, w: 3, h: 3 }
        ]
        comps: ({ focus: focusC, todo: todoC, note: noteC })
    }

    // ================= cards =================
    Component {
        id: focusC
        DCard {
            id: fc
            p: t.p
            strong: true
            readonly property bool wide: width >= 380 && height < 260
            readonly property real rs: wide ? Math.min(height - 28, 150) : Math.max(70, Math.min(width - 40, height - 130, 190))
            readonly property var chips: [["focus", "Focus"], ["short", "Short"], ["long", "Long"]]
            Row {
                id: chipRow
                x: wide ? 16 : (fc.width - width) / 2; y: 12
                spacing: 6
                Repeater {
                    model: fc.chips
                    Rectangle {
                        readonly property bool on: t.fmode === modelData[0]
                        width: ct.implicitWidth + 18; height: 24; radius: 12
                        color: on ? t.p.primary : (cmm.containsMouse ? t.p.card2 : t.p.track)
                        DText { id: ct; anchors.centerIn: parent; text: modelData[1]; font.pixelSize: 11; font.weight: Font.Medium; color: parent.on ? t.p.inkOn : t.p.text }
                        MouseArea { id: cmm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.fmodeSet(modelData[0]) }
                    }
                }
            }
            Item {
                id: ringBox
                x: fc.wide ? 16 : (fc.width - width) / 2
                y: fc.wide ? chipRow.y + 36 : chipRow.y + 36
                width: fc.rs; height: fc.rs
                visible: !fc.wide || height > 60
                DRing { anchors.fill: parent; p: t.p; line: Math.max(6, parent.width * 0.06); gapped: false
                    value: 100 - 100 * t.fleft / t.modeLen[t.fmode] }
                DText { anchors.centerIn: parent; text: t.mmss(t.fleft); font.pixelSize: Math.max(18, parent.width * 0.22); font.weight: Font.Light; color: t.p.text }
            }
            Row {
                x: fc.wide ? ringBox.x + ringBox.width + 20 : (fc.width - width) / 2
                y: fc.wide ? chipRow.y + 48 : fc.height - height - 14
                spacing: 10
                Rectangle {
                    width: 62; height: 40; radius: 20; color: fpm.containsMouse ? Qt.lighter(t.p.primary, 1.08) : t.p.primary
                    MIcon { anchors.centerIn: parent; name: t.frun ? "pause" : "play_arrow"; glyph: t.d.md(t.frun ? 0xF03E4 : 0xF040A); size: 22; color: t.p.inkOn }
                    MouseArea { id: fpm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.frun ? t.fpause() : t.fstart() }
                }
                Rectangle {
                    width: 40; height: 40; radius: 20; color: frm.containsMouse ? t.p.card2 : t.p.track
                    MIcon { anchors.centerIn: parent; name: "restart_alt"; glyph: t.d.md(0xF0709); size: 20; color: t.p.text }
                    MouseArea { id: frm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.freset() }
                }
            }
            Row {
                x: fc.wide ? ringBox.x + ringBox.width + 20 : (fc.width - width) / 2
                y: fc.wide ? chipRow.y + 100 : chipRow.y + 36 + fc.rs + 6
                spacing: 6
                visible: !fc.wide || fc.height > 110
                Repeater {
                    model: 4
                    Rectangle { width: 8; height: 8; radius: 4; color: index < (t.fdone % 4 === 0 && t.fdone > 0 && t.fmode !== "focus" ? 4 : t.fdone % 4) ? t.p.primary : t.p.track }
                }
            }
        }
    }
    Component {
        id: todoC
        DCard {
            id: td
            p: t.p
            readonly property int remain: t.d.todos.filter(function(x) { return !x.done }).length
            readonly property bool anyDone: t.d.todos.length - remain > 0
            Item {
                id: tdHead
                x: 16; y: 12
                width: parent.width - 32; height: 24
                DText { anchors.verticalCenter: parent.verticalCenter; text: "To-do"; font.pixelSize: 15; font.weight: Font.DemiBold; color: t.p.text }
                Row {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    DText { anchors.verticalCenter: parent.verticalCenter; text: t.d.todos.length > 0 ? td.remain + " left" : ""; font.pixelSize: 11; color: t.p.sub }
                    Rectangle {
                        visible: td.anyDone
                        anchors.verticalCenter: parent.verticalCenter
                        width: clr.implicitWidth + 16; height: 22; radius: 11; color: cm2.containsMouse ? t.p.card2 : t.p.track
                        DText { id: clr; anchors.centerIn: parent; text: "Clear done"; font.pixelSize: 10; font.weight: Font.Medium; color: t.p.text }
                        MouseArea { id: cm2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { t.d.todoClear(); Sfx.play("remove") } }
                    }
                }
            }
            Flickable {
                id: tdList
                x: 12; y: tdHead.y + tdHead.height + 6
                width: parent.width - 24; height: parent.height - y - 62
                contentWidth: width; contentHeight: tdCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: tdCol
                    width: tdList.width
                    spacing: 2
                    Repeater {
                        model: t.d.todos.map(function(x, i) { return { t: x.t, done: x.done, i: i } })
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: rm.containsMouse ? t.p.track : "transparent"
                            Rectangle {
                                x: 6; anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20; radius: 10
                                color: modelData.done ? t.p.primary : "transparent"
                                border.width: modelData.done ? 0 : 2; border.color: t.p.sub
                                MIcon { anchors.centerIn: parent; visible: modelData.done; name: "check"; glyph: t.d.md(0xF012C); size: 13; color: t.p.inkOn }
                            }
                            DText { x: 38; width: parent.width - 38 - 34; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: modelData.t; font.pixelSize: 13
                                color: modelData.done ? t.p.sub : t.p.text; font.strikeout: modelData.done }
                            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { t.d.todoToggle(modelData.i); Sfx.play(modelData.done ? "switch-off" : "switch-on") } }
                            Rectangle {
                                visible: rm.containsMouse || xm.containsMouse
                                anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                                width: 24; height: 24; radius: 12; color: xm.containsMouse ? Qt.rgba(1, 0.35, 0.3, 0.3) : "transparent"
                                MIcon { anchors.centerIn: parent; name: "close"; glyph: t.d.md(0xF0156); size: 14; color: xm.containsMouse ? "#ff8a80" : t.p.sub }
                                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { t.d.todoRemove(modelData.i); Sfx.play("remove") } }
                            }
                        }
                    }
                }
                DText { visible: t.d.todos.length === 0; x: 8; y: 8; text: "Nothing to do. Add a task below."; font.pixelSize: 12; color: t.p.sub }
            }
            Rectangle {
                id: addBox
                x: 12; y: parent.height - height - 12
                width: parent.width - 24; height: 40; radius: 20
                color: t.p.track
                border.width: ti.activeFocus ? 2 : 0; border.color: t.p.primary
                MIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "add"; glyph: t.d.md(0xF0415); size: 18; color: t.p.sub }
                TextInput {
                    id: ti
                    x: 38; width: parent.width - 38 - 14; anchors.verticalCenter: parent.verticalCenter
                    color: t.p.text; selectionColor: t.p.primary; selectedTextColor: t.p.inkOn
                    font.family: DashFont.sans; font.pixelSize: 13
                    clip: true
                    maximumLength: 200
                    onAccepted: { if (text.trim() !== "") { t.d.todoAdd(text); text = ""; Sfx.play("add") } }
                    onTextChanged: if (activeFocus) Sfx.play("type")
                    Keys.onEscapePressed: focus = false
                    DText { visible: ti.text.length === 0; text: ti.activeFocus ? "Type a task, Enter to add" : "Add a task"; font.pixelSize: 13; color: t.p.sub }
                }
            }
        }
    }
    Component {
        id: noteC
        DCard {
            id: nt
            p: t.p
            DText { x: 16; y: 12; text: "Note"; font.pixelSize: 15; font.weight: Font.DemiBold; color: t.p.text }
            Flickable {
                id: nf
                x: 16; y: 44
                width: parent.width - 32; height: parent.height - 44 - 14
                contentWidth: width; contentHeight: Math.max(height, ne.contentHeight + 8)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: ne
                    width: nf.width
                    text: t.noteText
                    color: t.p.text; selectionColor: t.p.primary; selectedTextColor: t.p.inkOn
                    font.family: DashFont.sans; font.pixelSize: 14
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    onTextChanged: {
                        if (text.length > 4000) { text = text.substring(0, 4000); return }
                        if (activeFocus && text !== t.noteText) { t.noteText = text; noteSave.restart(); Sfx.play("type") }
                    }
                    Keys.onEscapePressed: focus = false
                }
                DText { visible: ne.text.length === 0; text: ne.activeFocus ? "Type here" : "Click to write a note"; font.pixelSize: 14; color: t.p.sub }
            }
        }
    }
}
