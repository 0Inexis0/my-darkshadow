import QtQuick

// A small fake notification popup that mirrors the swaync popup styles.
Item {
    id: m
    property string look: "glass"          // glass | solid | outline | minimal | pill | accent | glow | island | light
    property string acc: "#d4d4d4"
    property string accFg: "#0d0d0d"
    property real baseRadius: 18
    property real op: 0.8
    property real iconSize: 36
    property bool showBody: true
    property real fs: 1                     // font scale

    readonly property bool light: look === "light"
    readonly property real r: look === "pill" ? height / 2 : look === "minimal" ? 8 : look === "accent" ? 10
                            : look === "island" ? Math.min(28, height / 2) : baseRadius
    readonly property color fg: light ? "#111111" : "#F6F5F4"
    readonly property color dim: light ? "#555555" : "#9a9aa4"

    // fake glow
    Rectangle {
        visible: m.look === "glow"
        anchors.fill: card
        anchors.margins: -5
        radius: card.radius + 5
        color: m.acc
        opacity: 0.22
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: m.r
        color: m.look === "solid" ? "#1c1c20"
             : m.look === "island" ? "#000000"
             : m.look === "light" ? Qt.rgba(0.965, 0.96, 0.957, 0.95)
             : m.look === "minimal" ? Qt.rgba(0.05, 0.05, 0.055, 0.85)
             : m.look === "glass" ? Qt.rgba(0.07, 0.07, 0.08, 0.62)
             : m.look === "outline" ? Qt.rgba(0.04, 0.04, 0.05, m.op)
             : Qt.rgba(0.07, 0.07, 0.08, 0.9)
        border.width: (m.look === "minimal" || m.look === "island") ? 0 : 1
        border.color: (m.look === "outline" || m.look === "glow") ? m.acc
                    : m.light ? Qt.rgba(0, 0, 0, 0.08)
                    : m.look === "glass" ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07)
        Behavior on radius { NumberAnimation { duration: 180 } }
        Behavior on color { ColorAnimation { duration: 180 } }

        Rectangle {
            visible: m.look === "accent"
            x: 0; y: 0
            width: 4; height: parent.height
            radius: 2
            color: m.acc
        }

        Rectangle {
            id: ico
            x: m.look === "pill" || m.look === "island" ? parent.height * 0.18 : 10 * m.fs + (m.look === "accent" ? 4 : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(m.iconSize, parent.height - 12); height: width
            radius: m.look === "pill" || m.look === "island" ? width / 2 : Math.max(5, width * 0.3)
            color: m.acc
            T { kind: "icon"; anchors.centerIn: parent; text: ""; font.pixelSize: ico.width * 0.45; color: m.accFg }
        }
        Column {
            anchors.left: ico.right
            anchors.leftMargin: 10 * m.fs
            anchors.right: parent.right
            anchors.rightMargin: 12 * m.fs
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * m.fs
            Item {
                width: parent.width
                height: sum.implicitHeight
                T { id: sum; text: "Shadow's Shell"; font.pixelSize: 13 * m.fs; font.bold: true; color: m.fg; width: parent.width - 30 * m.fs; elide: Text.ElideRight }
                T { anchors.right: parent.right; text: "now"; font.pixelSize: 10 * m.fs; color: m.dim }
            }
            T { visible: m.showBody; width: parent.width; text: "This is how your notifications look."; font.pixelSize: 11 * m.fs; color: m.dim; elide: Text.ElideRight }
        }
    }
}
