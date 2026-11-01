import QtQuick

Rectangle {
    id: f
    property alias text: input.text
    property string placeholder: ""
    signal accepted()
    height: 38
    radius: 10
    color: "#141414"
    border.width: 1
    border.color: input.activeFocus ? "#5a5a5a" : "#2a2a2a"

    TextInput {
        id: input
        onTextChanged: if (activeFocus) Sfx.play("type")
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        color: "#F6F5F4"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        clip: true
        selectByMouse: true
        onAccepted: f.accepted()
    }
    T {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: f.placeholder
        color: "#6a6a6a"
        font.pixelSize: 13
        visible: input.text.length === 0
    }
}