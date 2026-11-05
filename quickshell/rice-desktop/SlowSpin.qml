import QtQuick

// A slow, endless turn for a decorative shape (the parent), at about 20 steps a second.
// A RotationAnimator redraws the shape on every frame of the screen (144 times a second on a 144 Hz screen) for a
// turn that takes 30 seconds; the compositor then redraws and blurs that part of the desktop just as often. On
// laptops with integrated graphics many of them together made the whole desktop slow. This looks the same.
Item {
    id: sp
    property bool running: true
    property int period: 30000          // ms for one full turn
    property real turn: 360             // -360 turns the other way
    visible: false
    width: 0; height: 0
    Timer {
        interval: 50
        repeat: true
        running: sp.running && sp.parent !== null
        onTriggered: sp.parent.rotation = (sp.parent.rotation + sp.turn * interval / sp.period) % 360
    }
}
