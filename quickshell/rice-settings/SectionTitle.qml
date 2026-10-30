import QtQuick

Column {
    property string text: ""
    property string sub: ""
    width: parent ? parent.width : 400
    topPadding: 14
    spacing: 3
    T { kind: "title"; text: parent.text; font.pixelSize: 16; font.bold: true }
    T { kind: "reading"; visible: parent.sub.length > 0; text: parent.sub; color: "#8a8a8a"; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap }
}
