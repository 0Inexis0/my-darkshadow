import QtQuick

// Our folder: a tab behind, a body in front with a lighter face, and a small symbol for the special ones
// (Downloads, Music ...). Drawn from shapes, so it takes the wallpaper's colors at any size.
Item {
    id: g
    property string symbol: ""
    property color base: Theme.primary
    property bool open: false
    readonly property color back: Theme.mix(base, Theme.surface, 0.55)
    readonly property color face: Theme.mix(base, Theme.surface, 0.28)
    implicitWidth: 64
    implicitHeight: 52
    Rectangle {
        x: width * 0.02; y: 0
        width: g.width * 0.44; height: g.height * 0.32
        radius: Math.max(3, g.width * 0.07)
        color: g.back
    }
    Rectangle {
        y: g.height * 0.12
        width: g.width; height: g.height * 0.88
        radius: Math.max(4, g.width * 0.1)
        color: g.back
    }
    Rectangle {
        y: g.open ? g.height * 0.36 : g.height * 0.24
        width: g.width; height: g.height - y
        radius: Math.max(4, g.width * 0.1)
        color: g.face
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 1
            width: parent.width - parent.radius * 2; height: 1; color: Theme.alpha("#ffffff", 0.12) }
        Ic {
            visible: g.symbol !== "" && g.width >= 30
            anchors.centerIn: parent
            name: g.symbol
            size: Math.round(g.width * 0.32)
            color: Theme.mix(g.base, "#000000", 0.55)
        }
    }
}
