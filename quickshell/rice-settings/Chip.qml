import QtQuick

Rectangle {
    id: chip
    property string label: ""
    property bool canLeft: true
    property bool canRight: true
    signal moveLeft()
    signal moveRight()
    signal removed()

    height: 32
    width: chipRow.implicitWidth + 16
    radius: 9
    color: "#1a1a1a"
    border.width: 1
    border.color: "#2a2a2a"

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 4
        Glyph { glyph: "‹"; active: chip.canLeft; onClicked: chip.moveLeft() }
        T { text: chip.label; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        Glyph { glyph: "›"; active: chip.canRight; onClicked: chip.moveRight() }
        Glyph { glyph: "×"; onClicked: chip.removed() }
    }
}
