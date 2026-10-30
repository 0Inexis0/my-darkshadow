import QtQuick

Item {
    id: slot
    property int idx: 0
    property int cur: 0
    default property alias content: inner.data

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    y: idx === cur ? 0 : (idx < cur ? -44 : 44)
    opacity: idx === cur ? 1 : 0
    visible: opacity > 0.01
    enabled: idx === cur
    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Item { id: inner; anchors.fill: parent }
}
