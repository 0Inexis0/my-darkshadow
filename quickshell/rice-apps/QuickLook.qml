import Quickshell.Io
import QtQuick

// Files: Quick look (Space): a picture, the first part of a text file, or a big card of the file, over the window.
// Left / Right go to the files beside it, Space or Escape closes.
Item {
    id: q
    property var fa
    property var e: null
    property bool open: false
    readonly property string kind: e ? Theme.kind(e.name, e.dir) : ""
    readonly property bool text: kind === "code" || kind === "doc" && /\.(txt|md|log|csv|org)$/i.test(e ? e.name : "") || kind === "other" && e && Number(e.size) < 65536
    visible: bg.opacity > 0.01
    function show(x) {
        if (!x) return
        e = x
        open = true
        forceActiveFocus()
    }
    function close() { open = false; fa.forceActiveFocus() }
    function step(d) {
        let i = fa.indexOf(e ? e.path : "")
        for (let n = 0; n < fa.count; n++) {
            i = (i + d + fa.count) % fa.count
            const x = fa.at(i)
            if (x && !x.dir) { e = x; fa.selectOnly(i); return }
        }
    }
    Keys.onPressed: function(k) {
        if (k.key === Qt.Key_Escape || k.key === Qt.Key_Space) { close(); k.accepted = true }
        else if (k.key === Qt.Key_Left || k.key === Qt.Key_Up) { step(-1); k.accepted = true }
        else if (k.key === Qt.Key_Right || k.key === Qt.Key_Down) { step(1); k.accepted = true }
        else if (k.key === Qt.Key_Return) { fa.openE(e); close(); k.accepted = true }
    }
    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.scrim
        opacity: q.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(200) } }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: q.close(); onWheel: function(w) { q.step(w.angleDelta.y > 0 ? -1 : 1) } }
    }
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 96, 980)
        height: Math.min(parent.height - 80, 720)
        radius: Theme.rXL
        color: Theme.surfaceC
        opacity: q.open ? 1 : 0
        scale: q.open ? 1 : 0.94
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.d(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.d(340); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
        MouseArea { anchors.fill: parent }
        Item {
            id: top
            width: parent.width; height: 64
            FileTile { x: 20; width: 30; height: 30; anchors.verticalCenter: parent.verticalCenter
                path: q.e ? q.e.path : ""; name: q.e ? q.e.name : ""; isDir: false; thumb: q.e ? (q.fa.thumbs[q.e.path] || "") : "" }
            T { x: 62; width: parent.width - x - 200; anchors.verticalCenter: parent.verticalCenter; role: "title"
                text: q.e ? q.e.name : "" }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                IconBtn { icon: "chevron_left"; tip: "The one before (Left)"; onClicked: q.step(-1) }
                IconBtn { icon: "chevron_right"; tip: "The next one (Right)"; onClicked: q.step(1) }
                Btn { kind: "tonal"; text: "Open"; icon: "open_in_new"; anchors.verticalCenter: parent.verticalCenter; onClicked: { q.fa.openE(q.e); q.close() } }
                IconBtn { icon: "close"; onClicked: q.close() }
            }
        }
        Rectangle {
            anchors.top: top.bottom
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 12; anchors.topMargin: 0
            radius: Theme.rL
            color: Theme.surfaceLowest
            clip: true
            Image {
                visible: q.kind === "image" || q.kind === "video" || q.kind === "pdf"
                anchors.fill: parent
                anchors.margins: 12
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                source: !q.open || !q.e ? "" : (q.kind === "image" ? Theme.url(q.e.path) : (q.fa.thumbs[q.e.path] ? Theme.url(q.fa.thumbs[q.e.path]) : ""))
                sourceSize.width: 1600
                sourceSize.height: 1600
                smooth: true
            }
            Rectangle {
                visible: q.kind === "video" || q.kind === "audio"
                anchors.centerIn: parent
                width: 72; height: 72; radius: 28
                color: Theme.primary
                Ic { anchors.centerIn: parent; name: "play_arrow"; size: 40; color: Theme.inkPrimary }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Sys.app("player", [q.e.path]); q.close() } }
            }
            Flickable {
                visible: q.text
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: tx.implicitHeight
                contentWidth: width
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: tx
                    width: parent.width
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    font.family: Theme.mono
                    font.pixelSize: 13
                    color: Theme.ink
                    text: fv.ready ? fv.text().substring(0, 60000) : ""
                }
            }
            FileView {
                id: fv
                property bool ready: false
                path: q.open && q.text && q.e && Number(q.e.size) < 524288 ? q.e.path : ""
                printErrors: false
                onPathChanged: ready = false
                onLoaded: ready = true
            }
            Column {
                visible: !q.text && q.kind !== "image" && q.kind !== "video" && q.kind !== "audio" && !(q.kind === "pdf" && q.fa.thumbs[q.e ? q.e.path : ""])
                anchors.centerIn: parent
                spacing: 12
                FileTile { width: 140; height: 140; anchors.horizontalCenter: parent.horizontalCenter
                    path: q.e ? q.e.path : ""; name: q.e ? q.e.name : ""; isDir: false }
                T { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.inkVar
                    text: q.e ? Theme.size(Number(q.e.size)) + " · " + Theme.when(q.e.mod) : "" }
            }
        }
    }
}
