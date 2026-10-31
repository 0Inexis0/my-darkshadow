import QtQuick

Rectangle {
    id: zc
    property string title: ""
    property var items: []
    property var available: []
    property var labelOf: function(n) { return n }
    property bool adding: false
    signal addRequested(string name)
    signal removeRequested(string name)
    signal moveRequested(string name, string dir)
    signal addToggled()

    width: parent ? parent.width : 400
    height: inner.implicitHeight + 28
    radius: 12
    color: "#141414"
    border.width: 1
    border.color: "#1f1f1f"

    Column {
        id: inner
        x: 16
        y: 14
        width: zc.width - 32
        spacing: 10

        T { text: zc.title; font.pixelSize: 12; color: "#8a8a8a" }

        Flow {
            width: parent.width
            spacing: 6

            Repeater {
                model: zc.items
                delegate: Chip {
                    label: zc.labelOf(modelData)
                    canLeft: index > 0
                    canRight: index < zc.items.length - 1
                    onMoveLeft: zc.moveRequested(modelData, "left")
                    onMoveRight: zc.moveRequested(modelData, "right")
                    onRemoved: zc.removeRequested(modelData)
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 9
                color: zc.adding ? "#F6F5F4" : (plusMouse.containsMouse ? "#262626" : "#1a1a1a")
                border.width: 1
                border.color: "#2a2a2a"
                T {
                    anchors.centerIn: parent
                    text: zc.adding ? "−" : "+"
                    font.pixelSize: 16
                    color: zc.adding ? "#0d0d0d" : "#F6F5F4"
                }
                MouseArea {
                    id: plusMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: zc.addToggled()
                }
            }
        }

        Flow {
            visible: zc.adding && zc.available.length > 0
            width: parent.width
            spacing: 6

            Repeater {
                model: zc.available
                delegate: Rectangle {
                    height: 32
                    width: addText.implicitWidth + 26
                    radius: 9
                    color: addMouse.containsMouse ? "#262626" : "#101010"
                    border.width: 1
                    border.color: "#3a3a3a"
                    T { id: addText; anchors.centerIn: parent; text: "+ " + zc.labelOf(modelData); font.pixelSize: 12 }
                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: zc.addRequested(modelData)
                    }
                }
            }
        }

        T {
            visible: zc.adding && zc.available.length === 0
            text: "Every module is already placed in the bar."
            font.pixelSize: 12
            color: "#8a8a8a"
        }
    }
}
