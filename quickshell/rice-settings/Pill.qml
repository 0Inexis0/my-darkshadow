import QtQuick

Rectangle {
    id: pill
    property string label: ""
    signal clicked()
    implicitWidth: pillText.implicitWidth + 32
    height: 38
    radius: 10
    color: pillMouse.containsMouse ? "#262626" : "#1a1a1a"
    border.width: 1
    border.color: "#2a2a2a"
    Behavior on color { ColorAnimation { duration: 140 } }

    T { id: pillText; anchors.centerIn: parent; text: pill.label; font.pixelSize: 13 }
    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.clicked()
    }
}
