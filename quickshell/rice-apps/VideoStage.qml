import QtQuick
import QtMultimedia

// Player: a video. A click plays or pauses it, a double click (or F) fills the window with it; the controls show
// while the pointer moves.
Item {
    id: vs
    property var pl
    property alias output: out
    property bool chrome: true
    function poke() { chrome = true; hideT.restart() }
    Timer { id: hideT; interval: 2400; onTriggered: if (!cm.containsMouse && vs.pl.playing) vs.chrome = false }
    onVisibleChanged: if (visible) poke()
    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: vs.chrome ? Qt.ArrowCursor : Qt.BlankCursor
        onPositionChanged: vs.poke()
        onClicked: { vs.pl.toggle(); vs.poke() }
        onDoubleClicked: vs.pl.theater = !vs.pl.theater
        onWheel: function(w) { vs.pl.setVol(vs.pl.vol + (w.angleDelta.y > 0 ? 0.05 : -0.05)); vs.poke() }
    }
    // the top: back to the library
    Item {
        width: parent.width; height: 72
        opacity: vs.chrome ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.6) } GradientStop { position: 1; color: "transparent" } } }
        IconBtn { x: 12; anchors.verticalCenter: parent.verticalCenter; icon: "arrow_back"; ink: "white"; tip: "The library"
                  onClicked: { vs.pl.theater = false; vs.pl.tab = vs.pl.lastTab === "video" ? "videos" : vs.pl.lastTab } }
        T { x: 64; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 140; text: vs.pl.cur ? vs.pl.cur.title : ""; role: "title"; color: "white" }
    }
    // the controls
    Rectangle {
        id: ctl
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 18
        width: Math.min(parent.width - 32, 860); height: 112
        radius: Theme.rXL
        color: Theme.alpha(Theme.surfaceC, 0.88)
        opacity: vs.chrome ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 220 } }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onPositionChanged: vs.poke() }
        Slider {
            x: 20; y: 10; width: parent.width - 40; height: 30
            wavy: true; playing: vs.pl.playing
            value: vs.pl.len > 0 ? vs.pl.pos / vs.pl.len : 0
            onReleased: function(v) { vs.pl.seekTo(v * vs.pl.len) }
        }
        Row {
            x: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            spacing: 6
            PlayBtn { size: 48; playing: vs.pl.playing; onClicked: vs.pl.toggle() }
            IconBtn { icon: "replay_10"; anchors.verticalCenter: parent.verticalCenter; onClicked: vs.pl.seekBy(-10) }
            IconBtn { icon: "forward_10"; anchors.verticalCenter: parent.verticalCenter; onClicked: vs.pl.seekBy(10) }
            IconBtn { icon: "skip_next"; anchors.verticalCenter: parent.verticalCenter; visible: vs.pl.upNext.length > 0; onClicked: vs.pl.next(false) }
            T { anchors.verticalCenter: parent.verticalCenter; text: Theme.clock(vs.pl.pos) + " / " + Theme.clock(vs.pl.len); role: "label"; color: Theme.inkVar; leftPadding: 6 }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.bottom: parent.bottom; anchors.bottomMargin: 16
            spacing: 4
            IconBtn { id: mb; anchors.verticalCenter: parent.verticalCenter; icon: vs.pl.muted || vs.pl.vol === 0 ? "volume_off" : "volume_up"; onClicked: vs.pl.muted = !vs.pl.muted }
            Slider { width: 110; height: 28; trackH: 6; anchors.verticalCenter: parent.verticalCenter; value: vs.pl.muted ? 0 : vs.pl.vol; onMoved: function(v) { vs.pl.setVol(v) } }
            IconBtn { anchors.verticalCenter: parent.verticalCenter; icon: vs.pl.theater ? "close_fullscreen" : "open_in_full"; tip: "Fill the window (F)"; onClicked: vs.pl.theater = !vs.pl.theater }
        }
    }
}
