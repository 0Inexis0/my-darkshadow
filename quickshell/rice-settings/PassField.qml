import QtQuick

// A password field: a lock, dots while you type (or the text with the eye), Enter to go on.
Rectangle {
    id: pf
    property alias text: input.text
    property string placeholder: ""
    property string icon: ""
    property string sym: "lock"
    property bool bad: false
    property bool show: false
    property bool secret: true       // false: an ordinary text field with the same look (no dots, no eye)
    signal accepted()
    function clear() { input.text = "" }
    function focusIn() { input.forceActiveFocus() }
    height: 52
    radius: M3.sq ? 0 : (26 * M3.shapeK)
    color: input.activeFocus ? M3.surfaceHighest : M3.surfaceHigh
    border.width: input.activeFocus || bad ? 2 : 0
    border.color: bad ? M3.error : M3.primary
    Behavior on color { ColorAnimation { duration: 140 } }

    Icon { x: 18; anchors.verticalCenter: parent.verticalCenter; name: pf.sym; glyph: pf.icon; size: 17; color: input.activeFocus ? M3.primary : M3.inkDim }
    TextInput {
        id: input
        x: 48
        width: parent.width - x - 52
        anchors.verticalCenter: parent.verticalCenter
        echoMode: pf.show || !pf.secret ? TextInput.Normal : TextInput.Password
        passwordCharacter: "●"
        color: M3.ink
        font.family: Fonts.main
        font.pixelSize: 15
        font.letterSpacing: pf.show || !pf.secret ? 0 : 2
        clip: true
        selectByMouse: true
        onAccepted: pf.accepted()
    }
    T {
        x: 48
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - 52
        elide: Text.ElideRight
        text: pf.placeholder
        color: M3.inkDim
        font.pixelSize: 14
        visible: input.text.length === 0
    }
    Rectangle {
        visible: pf.secret
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 36; height: 36; radius: M3.sq ? 0 : (18)
        color: em.containsMouse ? M3.surfaceHighest : "transparent"
        Icon { anchors.centerIn: parent; name: pf.show ? "visibility_off" : "visibility"; glyph: pf.show ? "" : ""; size: 17; color: M3.inkDim }
        MouseArea { id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pf.show = !pf.show }
    }
}
