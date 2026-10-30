import QtQuick

// Scrollable page body: put rows inside, they stack in a Column.
Item {
    id: ps
    default property alias content: col.data
    property alias column: col

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 6
        contentWidth: width
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Behavior on contentY {
            enabled: !flick.dragging && !flick.flicking
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(e) {
                const max = Math.max(0, flick.contentHeight - flick.height)
                flick.contentY = Math.max(0, Math.min(max, flick.contentY - e.angleDelta.y * 0.6))
            }
        }

        Column {
            id: col
            width: flick.width
            spacing: 10
        }
    }
}
