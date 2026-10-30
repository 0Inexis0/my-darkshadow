import QtQuick

Rectangle {
    id: sw
    property bool checked: false
    signal toggled(bool value)
    width: 44
    height: 24
    radius: 12
    color: sw.checked ? "#F6F5F4" : "#2a2a2a"
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 18
        height: 18
        radius: 9
        y: 3
        x: sw.checked ? 23 : 3
        color: sw.checked ? "#0d0d0d" : "#8a8a8a"
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
