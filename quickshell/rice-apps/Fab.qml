import QtQuick

// A floating action button: 56 high, the primary container; with `text` it is an extended one.
Rectangle {
    id: f
    property string icon: "add"
    property string text: ""
    property bool small: false
    property bool expanded: true
    signal clicked()
    implicitHeight: small ? 48 : 56
    implicitWidth: text !== "" && expanded ? row.implicitWidth + 40 : implicitHeight
    Behavior on implicitWidth { NumberAnimation { duration: Theme.d(320); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
    radius: Theme.sq ? 0 : (small ? 14 : 18)
    color: Theme.primaryContainer
    clip: true
    Rectangle { anchors.fill: parent; anchors.topMargin: 3; radius: Theme.sq ? 0 : (parent.radius); color: Qt.rgba(0, 0, 0, 0.25); z: -1 }
    Layer { area: ma; ink: Theme.inkPrimaryC }
    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: f.text !== "" && f.expanded ? 18 : (f.width - 24) / 2
        spacing: 10
        Ic { name: f.icon; size: 24; color: Theme.inkPrimaryC; anchors.verticalCenter: parent.verticalCenter }
        T { text: f.text; role: "label"; color: Theme.inkPrimaryC; anchors.verticalCenter: parent.verticalCenter
            opacity: f.expanded ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 160 } } }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: f.clicked() }
    scale: ma.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
}
