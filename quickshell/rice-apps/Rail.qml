import QtQuick

// A Material 3 navigation rail: the app's mark, an optional FAB, then the places; the one you are on gets a pill.
Item {
    id: r
    property var items: []            // [{ key, icon, text }]
    property string value: ""
    property string fabIcon: ""
    property string fabTip: ""
    property alias mark: markSlot.data
    signal picked(string key)
    signal fab()
    width: 88
    Column {
        y: 14
        width: parent.width
        spacing: 6
        Item { id: markSlot; width: parent.width; height: 44 }
        Item {
            width: parent.width; height: r.fabIcon !== "" ? 72 : 8
            Fab { visible: r.fabIcon !== ""; small: false; icon: r.fabIcon; anchors.horizontalCenter: parent.horizontalCenter; y: 4; onClicked: r.fab()
                  MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; hoverEnabled: true; onContainsMouseChanged: if (containsMouse && r.fabTip !== "") Ui.tip(parent, r.fabTip); else Ui.untip(parent) } }
        }
        Repeater {
            model: r.items
            Item {
                id: it
                required property var modelData
                readonly property bool on: modelData.key === r.value
                width: r.width; height: 64
                Rectangle {
                    id: pill
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    width: it.on ? 56 : 32; height: 32; radius: Theme.sq ? 0 : (16)
                    color: it.on ? Theme.secondaryContainer : "transparent"
                    Behavior on width { NumberAnimation { duration: Theme.d(260); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emph } }
                    Layer { area: ma; ink: Theme.inkSecondaryC; width: 56; x: (pill.width - 56) / 2; anchors.fill: undefined; height: 32; radius: Theme.sq ? 0 : (16) }
                    Ic { anchors.centerIn: parent; name: it.modelData.icon; size: 22; color: it.on ? Theme.inkSecondaryC : Theme.inkVar }
                }
                T { anchors.horizontalCenter: parent.horizontalCenter; y: 40; text: it.modelData.text; role: "small"
                    font.weight: it.on ? 700 : 500; color: it.on ? Theme.ink : Theme.inkVar }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.picked(it.modelData.key) }
            }
        }
    }
}
