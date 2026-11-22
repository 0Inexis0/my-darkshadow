import QtQuick

// A segmented button: `options` [{key, icon, text}], `value` the key that is on.
Rectangle {
    id: s
    property var options: []
    property string value: ""
    signal picked(string key)
    implicitHeight: 36
    implicitWidth: row.implicitWidth
    radius: Theme.sq ? 0 : (height / 2)
    color: "transparent"
    border.width: 1
    border.color: Theme.outlineVariant
    clip: true
    Row {
        id: row
        anchors.fill: parent
        Repeater {
            model: s.options
            Rectangle {
                required property var modelData
                required property int index
                readonly property bool on: modelData.key === s.value
                width: inner.implicitWidth + 28
                height: s.height
                color: on ? Theme.secondaryContainer : "transparent"
                Behavior on color { ColorAnimation { duration: 160 } }
                Rectangle { visible: index > 0; width: 1; height: parent.height; color: Theme.outlineVariant }
                Layer { area: sm; ink: Theme.inkSecondaryC; radius: Theme.sq ? 0 : (0) }
                Row {
                    id: inner
                    anchors.centerIn: parent
                    spacing: 6
                    Ic { visible: modelData.icon !== undefined || on; name: on && !modelData.icon ? "check" : (modelData.icon || ""); size: 18
                         color: on ? Theme.inkSecondaryC : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
                    T { visible: !!modelData.text; text: modelData.text || ""; role: "label"
                        color: on ? Theme.inkSecondaryC : Theme.inkVar; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: s.picked(modelData.key) }
            }
        }
    }
}
