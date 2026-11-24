import QtQuick

// A filter chip: outlined, a check and the secondary container when it is on.
Rectangle {
    id: c
    property string text: ""
    property string icon: ""
    property bool on: false
    signal clicked()
    implicitHeight: 32
    implicitWidth: row.implicitWidth + 24
    radius: Theme.sq ? 0 : (Theme.rS)
    color: on ? Theme.secondaryContainer : "transparent"
    border.width: on ? 0 : 1
    border.color: Theme.outlineVariant
    Behavior on color { ColorAnimation { duration: 160 } }
    Layer { area: ma; ink: Theme.inkSecondaryC }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Ic { visible: c.on || c.icon !== ""; name: c.on ? "check" : c.icon; size: 17; color: c.on ? Theme.inkSecondaryC : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
        T { text: c.text; role: "label"; color: c.on ? Theme.inkSecondaryC : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.clicked() }
}
