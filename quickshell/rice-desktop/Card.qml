import QtQuick

Rectangle {
    property real k: 1     // 0 = no background, 1 = normal
    radius: 26
    color: Qt.rgba(0.17, 0.17, 0.19, 0.74 * k)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.06 * k)
}
