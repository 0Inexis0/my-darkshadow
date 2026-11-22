import QtQuick

// One setting: a tonal card with the name and a short line under it; the control sits on the right.
// Rows that follow each other join into one group, the way Android 16 shows its settings: a thin gap and small
// corners inside the group, round corners at its two ends. An optional icon sits on the left in a tonal square.
Item {
    id: row
    property string label: ""
    property string desc: ""
    property real reserved: 0
    property string icon: ""          // a Nerd Font glyph
    property string sym: ""           // or a Google icon by name
    property bool lit: false          // the icon square in the key color (e.g. while the setting is on)
    property real cardHeight: desc.length > 0 ? 72 : 60
    // the item that stands in the Column (a wrapper, like a cell of OptionsList, sets it)
    property Item host: row
    readonly property bool joinable: true
    readonly property bool hasIcon: icon.length > 0 || sym.length > 0
    readonly property real textX: hasIcon ? 70 : 20
    readonly property real textW: Math.max(40, width - textX - 18 - reserved)
    // the list of children does not tell a binding when it changes: look again when the Column adds,
    // removes, shows or hides one
    property int look: 0
    readonly property bool joinPrev: look >= 0 && M3.near(host, -1)
    readonly property bool joinNext: look >= 0 && M3.near(host, 1)
    function again() { look++ }
    Component.onCompleted: Qt.callLater(again)
    Connections {
        target: row.host ? row.host.parent : null
        ignoreUnknownSignals: true
        function onChildrenChanged() { Qt.callLater(row.again) }
        function onVisibleChildrenChanged() { Qt.callLater(row.again) }
    }
    // the Column keeps its spacing; a row joined to the next one takes that much less room, so the gap is thin
    readonly property real squeeze: joinNext && host && host.parent && host.parent.spacing !== undefined
                                    ? Math.max(0, host.parent.spacing - M3.rowGap) : 0
    readonly property real radius: M3.rRowOut
    default property alias content: face.data
    width: parent ? parent.width : 400
    height: cardHeight - squeeze

    Rectangle {
        id: face
        width: parent.width
        height: row.cardHeight
        topLeftRadius: M3.sq ? 0 : (row.joinPrev ? M3.rRowIn : M3.rRowOut)
        topRightRadius: M3.sq ? 0 : (topLeftRadius)
        bottomLeftRadius: M3.sq ? 0 : (row.joinNext ? M3.rRowIn : M3.rRowOut)
        bottomRightRadius: M3.sq ? 0 : (bottomLeftRadius)
        Behavior on topLeftRadius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on bottomLeftRadius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        color: hov.hovered ? M3.surfaceHigh : M3.surfaceC
        Behavior on color { ColorAnimation { duration: 160 } }
        HoverHandler { id: hov }

        Rectangle {
            visible: row.hasIcon
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40
            radius: M3.sq ? 0 : (row.lit ? 20 : 12 * M3.shapeK)
            color: row.lit ? M3.primaryContainer : M3.surfaceHighest
            Behavior on radius { NumberAnimation { duration: M3.d(320); easing.type: M3.springy; easing.overshoot: 1.6 * Prefs.bounce } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Icon {
                anchors.centerIn: parent
                name: row.sym; glyph: row.icon; size: 19
                color: row.lit ? M3.inkPrimaryC : M3.inkDim
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
        Column {
            x: row.textX
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            T { text: row.label; font.pixelSize: 14; font.weight: Font.Medium; width: Math.min(implicitWidth, row.textW); elide: Text.ElideRight }
            T { kind: "reading"; text: row.desc; visible: row.desc.length > 0; color: M3.inkDim; font.pixelSize: 12; width: Math.min(implicitWidth, row.textW); elide: Text.ElideRight }
        }
    }
}
