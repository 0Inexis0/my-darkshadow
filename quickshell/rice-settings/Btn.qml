import QtQuick

Rectangle {
    id: b
    property string text: ""
    property string icon: ""
    property bool primary: false
    signal clicked()
    width: Math.max(120, row.implicitWidth + 36)
    height: 38
    radius: 12
    color: primary ? (m.containsMouse ? "#ffffff" : "#F6F5F4")
                   : (m.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
    border.width: primary ? 0 : 1
    border.color: Qt.rgba(1, 1, 1, 0.06)
    Behavior on color { ColorAnimation { duration: 120 } }
    scale: m.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        T { kind: "icon"; visible: b.icon.length > 0; text: b.icon; font.pixelSize: 14; color: b.primary ? "#0d0d0d" : "#F6F5F4"; anchors.verticalCenter: parent.verticalCenter }
        T { text: b.text; font.pixelSize: 13; font.bold: b.primary; color: b.primary ? "#0d0d0d" : "#F6F5F4"; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
