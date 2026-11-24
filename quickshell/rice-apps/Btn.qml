import QtQuick

// A Material 3 button with a label and an optional icon. `kind`: filled, tonal, outlined, text, danger
Rectangle {
    id: b
    property string text: ""
    property string icon: ""
    property string kind: "filled"
    property bool enabledBtn: true
    signal clicked()
    readonly property color ink: kind === "filled" ? Theme.inkPrimary : (kind === "tonal" ? Theme.inkSecondaryC
                                 : (kind === "danger" ? Theme.inkErrorC : Theme.primary))
    implicitHeight: 40
    implicitWidth: row.implicitWidth + (icon !== "" ? 40 : 48)
    radius: Theme.sq ? 0 : (ma.pressed ? 12 : height / 2)
    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    color: kind === "filled" ? Theme.primary : (kind === "tonal" ? Theme.secondaryContainer : (kind === "danger" ? Theme.errorContainer : "transparent"))
    border.width: kind === "outlined" ? 1 : 0
    border.color: Theme.outlineVariant
    opacity: enabledBtn ? 1 : 0.38
    Layer { area: ma; ink: b.ink }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Ic { visible: b.icon !== ""; name: b.icon; size: 18; color: b.ink; anchors.verticalCenter: parent.verticalCenter }
        T { text: b.text; role: "label"; color: b.ink; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; enabled: b.enabledBtn; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
