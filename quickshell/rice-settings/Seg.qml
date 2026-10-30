import QtQuick

Row {
    id: seg
    property var options: []
    property string current: ""
    signal chosen(string value)
    spacing: 4

    Repeater {
        model: seg.options
        delegate: Rectangle {
            width: segText.implicitWidth + 26
            height: 32
            radius: 9
            color: seg.current === modelData.value ? "#F6F5F4" : (segMouse.containsMouse ? "#262626" : "#1a1a1a")
            border.width: 1
            border.color: "#2a2a2a"
            Behavior on color { ColorAnimation { duration: 140 } }
            T {
                id: segText
                anchors.centerIn: parent
                text: modelData.label
                font.pixelSize: 12
                color: seg.current === modelData.value ? "#0d0d0d" : "#F6F5F4"
            }
            MouseArea {
                id: segMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: seg.chosen(modelData.value)
            }
        }
    }
}
