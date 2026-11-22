import QtQuick

// A round icon button. `kind`: standard (no fill), tonal, filled, outlined. `toggled` fills a standard one.
Rectangle {
    id: b
    property string icon: ""
    property string tip: ""
    property string kind: "standard"
    property bool toggled: false
    property bool enabledBtn: true
    property real iconSize: 22
    property color ink: kind === "filled" ? Theme.inkPrimary : (kind === "tonal" || toggled ? Theme.inkSecondaryC : Theme.inkVar)
    signal clicked(var mouse)
    signal rightClicked(var mouse)
    implicitWidth: 40
    implicitHeight: 40
    radius: Theme.sq ? 0 : (ma.pressed ? Math.min(width, height) * 0.32 : Math.min(width, height) / 2)
    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    color: kind === "filled" ? Theme.primary : (kind === "tonal" || toggled ? Theme.secondaryContainer : "transparent")
    border.width: kind === "outlined" ? 1 : 0
    border.color: Theme.outlineVariant
    opacity: enabledBtn ? 1 : 0.38
    Behavior on color { ColorAnimation { duration: 160 } }
    Layer { area: ma; ink: b.ink }
    Ic { anchors.centerIn: parent; name: b.icon; size: b.iconSize; color: b.ink
        scale: ma.pressed ? 0.88 : 1; Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } } }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: b.enabledBtn
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(m) { Ui.untip(b); if (m.button === Qt.RightButton) b.rightClicked(m); else b.clicked(m) }
        onContainsMouseChanged: if (b.tip !== "") { if (containsMouse) Ui.tip(b, b.tip); else Ui.untip(b) }
    }
}
