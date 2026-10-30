import QtQuick

Rectangle {
    id: row
    property string label: ""
    property string desc: ""
    property real reserved: 0
    readonly property real textW: Math.max(40, width - 32 - reserved)
    width: parent ? parent.width : 400
    height: 60
    radius: 12
    color: "#141414"
    border.width: 1
    border.color: "#1f1f1f"

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        T { text: row.label; font.pixelSize: 14; width: Math.min(implicitWidth, row.textW); elide: Text.ElideRight }
        T { kind: "reading"; text: row.desc; visible: row.desc.length > 0; color: "#8a8a8a"; font.pixelSize: 11; width: Math.min(implicitWidth, row.textW); elide: Text.ElideRight }
    }
}