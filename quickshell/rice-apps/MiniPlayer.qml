import QtQuick

// Player: the small bar at the bottom of narrow windows (a click opens Now playing).
Rectangle {
    id: m
    property var pl
    signal open()
    height: 72
    radius: Theme.sq ? 0 : (Theme.rXL)
    color: Theme.secondaryContainer
    readonly property var t: pl.cur || ({ title: "", artist: "", cover: "" })
    clip: true
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m.open() }
    Rectangle { anchors.bottom: parent.bottom; x: 20; width: (parent.width - 40) * (m.pl.len > 0 ? m.pl.pos / m.pl.len : 0); height: 3; radius: Theme.sq ? 0 : (2); color: Theme.primary }
    Rectangle {
        id: c
        x: 12; width: 48; height: 48; radius: Theme.sq ? 0 : (14)
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.surfaceHighest
        Pic { anchors.fill: parent; radius: Theme.sq ? 0 : (14); res: 96; source: Theme.url(m.t.cover || ""); onSourceChanged: miniIn.restart() }
        // V4.93: a new song: the cover turns and springs in
        SequentialAnimation { id: miniIn
            ParallelAnimation { NumberAnimation { target: c; property: "scale"; to: 0.7; duration: Theme.d(110) }
                                NumberAnimation { target: c; property: "rotation"; to: -10; duration: Theme.d(110) } }
            ParallelAnimation { NumberAnimation { target: c; property: "scale"; to: 1; duration: Theme.d(520); easing.type: Easing.OutBack; easing.overshoot: 2 }
                                NumberAnimation { target: c; property: "rotation"; to: 0; duration: Theme.d(520); easing.type: Easing.OutBack } } }
    }
    Column {
        anchors.left: c.right; anchors.leftMargin: 14
        anchors.right: btns.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        T { width: parent.width; text: m.t.title; font.weight: 500; color: Theme.inkSecondaryC }
        T { width: parent.width; text: m.t.artist || ""; role: "small"; color: Theme.inkSecondaryC; opacity: 0.8 }
    }
    Row {
        id: btns
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        IconBtn { icon: "skip_previous"; ink: Theme.inkSecondaryC; onClicked: m.pl.prev() }
        PlayBtn { size: 48; playing: m.pl.playing; onClicked: m.pl.toggle() }
        IconBtn { icon: "skip_next"; ink: Theme.inkSecondaryC; onClicked: m.pl.next(false) }
    }
}
