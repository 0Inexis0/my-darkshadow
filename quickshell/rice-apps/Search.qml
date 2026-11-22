import QtQuick

// A Material 3 search bar: a full pill, a leading icon, the text, and a clear button.
Rectangle {
    id: s
    property alias text: input.text
    property string hint: "Search"
    property string icon: "search"
    property alias input: input
    signal accepted()
    signal escaped()
    implicitHeight: 48
    radius: height / 2
    color: input.activeFocus ? Theme.surfaceHighest : Theme.surfaceHigh
    Behavior on color { ColorAnimation { duration: 160 } }
    Ic { id: lead; name: s.icon; size: 22; color: Theme.inkVar; anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter }
    TextInput {
        id: input
        anchors.left: lead.right; anchors.leftMargin: 12
        anchors.right: clear.left; anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.font
        font.pixelSize: 15
        color: Theme.ink
        selectionColor: Theme.alpha(Theme.primary, 0.4)
        selectedTextColor: Theme.ink
        clip: true
        selectByMouse: true
        onAccepted: s.accepted()
        Keys.onEscapePressed: s.escaped()
        T { visible: input.text === ""; text: s.hint; color: Theme.inkVar; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter; width: parent.width }
    }
    MouseArea { anchors.fill: parent; z: -1; cursorShape: Qt.IBeamCursor; onClicked: input.forceActiveFocus() }
    IconBtn { id: clear; icon: "close"; anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
        visible: input.text !== ""; onClicked: { input.text = ""; input.forceActiveFocus() } }
}
