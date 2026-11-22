import QtQuick

// The state layer of Material: a soft wash of the ink color while the pointer is over its parent, more while pressed.
// Put it inside the item (it fills it and takes its corners).
Rectangle {
    property var area: null
    property color ink: Theme.ink
    property bool on: false
    anchors.fill: parent
    radius: Theme.sq ? 0 : (parent.radius !== undefined ? parent.radius : 0)
    color: ink
    opacity: !area ? 0 : (area.pressed ? 0.14 : (area.containsMouse || on ? 0.08 : 0))
    Behavior on opacity { NumberAnimation { duration: 140 } }
}
