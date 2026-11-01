import QtQuick

// A short tour over the Settings window (after the welcome intro, or: rice-welcome tour).
// Everything gets darker except one part, which gets a glowing outline and a card that explains it.
// Next moves the light to the next part; Done (or Esc, or Skip) gives the window back.
//   steps: [{ rect: function() -> {x, y, w, h}, r, title, body }]
Item {
    id: tour
    property var steps: []
    property int index: 0
    property bool active: false
    readonly property var step: steps.length > 0 ? steps[Math.min(index, steps.length - 1)] : null
    signal finished()

    anchors.fill: parent
    visible: opacity > 0.01
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    z: 100

    // the lit part (window coordinates); it glides from one part to the next
    property real tx: width / 2
    property real ty: height / 2
    property real tw: 0
    property real th: 0
    property real tr: 16
    Behavior on tx { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    Behavior on ty { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    Behavior on tw { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    Behavior on th { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    Behavior on tr { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

    function place() {
        if (!step) return
        const r = step.rect()
        tx = r.x; ty = r.y; tw = r.w; th = r.h; tr = step.r !== undefined ? step.r : 16
    }
    function start() {
        index = 0
        place()
        active = true
        keys.forceActiveFocus()
    }
    function next() {
        if (index >= steps.length - 1) { stop(); return }
        index++
        place()
    }
    function stop() {
        if (!active) return
        active = false
        finished()
    }

    // ---- the dark around the lit part: one rectangle with a very thick border and a rounded hole
    readonly property real bw: 3000
    Item {
        anchors.fill: parent
        clip: true
        Rectangle {
            x: tour.tx - tour.bw; y: tour.ty - tour.bw
            width: tour.tw + 2 * tour.bw; height: tour.th + 2 * tour.bw
            radius: tour.tr + tour.bw
            color: "transparent"
            border.width: tour.bw
            border.color: Qt.rgba(0.01, 0.01, 0.02, 0.72)
        }
    }
    // clicks outside the card do nothing while the tour is on
    MouseArea { anchors.fill: parent; enabled: tour.active; hoverEnabled: true; acceptedButtons: Qt.AllButtons; onWheel: function(w) { w.accepted = true } }

    // ---- the glowing outline
    Rectangle {
        x: tour.tx - 3; y: tour.ty - 3
        width: tour.tw + 6; height: tour.th + 6
        radius: tour.tr + 3
        color: "transparent"
        border.width: 2
        border.color: "#F6F5F4"
        SequentialAnimation on opacity {
            running: tour.active; loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.45; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.45; to: 1; duration: 1100; easing.type: Easing.InOutSine }
        }
    }
    Rectangle {
        // soft halo
        x: tour.tx - 9; y: tour.ty - 9
        width: tour.tw + 18; height: tour.th + 18
        radius: tour.tr + 9
        color: "transparent"
        border.width: 6
        border.color: Qt.rgba(1, 1, 1, 0.07)
    }

    // ---- the card that explains it: next to the lit part, wherever there is room
    Rectangle {
        id: bubble
        width: 320
        height: bcol.implicitHeight + 36
        radius: 18
        color: "#151517"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        readonly property bool onRight: tour.tx + tour.tw + 24 + width <= tour.width - 12
        readonly property bool onLeft: !onRight && tour.tx - 24 - width >= 12
        x: onRight ? tour.tx + tour.tw + 24
           : onLeft ? tour.tx - 24 - width
           : Math.max(12, Math.min(tour.width - width - 12, tour.tx + tour.tw / 2 - width / 2))
        y: (onRight || onLeft) ? Math.max(12, Math.min(tour.height - height - 12, tour.ty + Math.min(tour.th, 160) / 2 - 40))
           : (tour.ty + tour.th + 24 + height <= tour.height ? tour.ty + tour.th + 24 : Math.max(12, tour.ty - 24 - height))
        Behavior on x { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

        Column {
            id: bcol
            x: 18; y: 18
            width: parent.width - 36
            spacing: 8
            T { text: tour.step ? tour.step.title : ""; kind: "title"; font.pixelSize: 18; font.bold: true; width: parent.width; wrapMode: Text.WordWrap }
            T { text: tour.step ? tour.step.body : ""; font.pixelSize: 13; color: "#a8a8b0"; width: parent.width; wrapMode: Text.WordWrap; lineHeight: 1.15 }
            Item { width: 1; height: 6 }
            Item {
                width: parent.width
                height: 34
                // where you are: one dot per step
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: tour.steps.length
                        Rectangle {
                            width: index === tour.index ? 18 : 6; height: 6; radius: 3
                            color: index === tour.index ? "#F6F5F4" : Qt.rgba(1, 1, 1, 0.22)
                            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Rectangle {
                        visible: tour.index < tour.steps.length - 1
                        width: skipT.implicitWidth + 22; height: 34; radius: 17
                        color: skipM.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        T { id: skipT; anchors.centerIn: parent; text: "Skip"; font.pixelSize: 13; color: "#a8a8b0" }
                        MouseArea { id: skipM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tour.stop() }
                    }
                    Rectangle {
                        width: nextT.implicitWidth + 30; height: 34; radius: 17
                        color: nextM.containsMouse ? "#ffffff" : "#ECECEE"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        T {
                            id: nextT
                            anchors.centerIn: parent
                            text: tour.index < tour.steps.length - 1 ? "Next" : "Done"
                            font.pixelSize: 13; font.bold: true; color: "#0d0d0d"
                        }
                        MouseArea { id: nextM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tour.next() }
                    }
                }
            }
        }
    }

    Item {
        id: keys
        focus: tour.active
        Keys.onEscapePressed: tour.stop()
        Keys.onReturnPressed: tour.next()
        Keys.onEnterPressed: tour.next()
        Keys.onRightPressed: tour.next()
        Keys.onSpacePressed: tour.next()
    }
}
