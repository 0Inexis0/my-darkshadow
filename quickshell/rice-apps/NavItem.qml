import QtQuick

// One place in the drawer: a full pill when it is the one you are in. In a rail: the icon in a small pill, the name
// under it. Folders and drives take files dropped on them.
Item {
    id: n
    property var fa: null
    property bool rail: false
    property string icon: ""
    property string text: ""
    property string sub: ""
    property string badge: ""
    property string path: ""
    property real usage: -1
    property bool on: false
    signal clicked()
    signal menu(var item)
    width: parent ? parent.width : 220
    height: rail ? 60 : (usage >= 0 ? 58 : 48)
    readonly property bool dropOn: da.containsDrag

    Rectangle {
        id: pill
        x: n.rail ? (n.width - 56) / 2 : 0
        y: n.rail ? 4 : 0
        width: n.rail ? 56 : n.width
        height: n.rail ? 32 : n.height
        radius: Theme.sq ? 0 : (height / 2)
        color: n.on || n.dropOn ? Theme.secondaryContainer : "transparent"
        Behavior on color { ColorAnimation { duration: 160 } }
        Layer { area: ma; ink: Theme.inkSecondaryC }
        Ic { id: ic; name: n.icon; size: 22; color: n.on ? Theme.inkSecondaryC : Theme.inkVar
             x: n.rail ? (parent.width - width) / 2 : 16; anchors.verticalCenter: parent.verticalCenter
             anchors.verticalCenterOffset: !n.rail && n.usage >= 0 ? -8 : 0 }
        T {
            visible: !n.rail
            x: 52; width: parent.width - x - (badgeR.visible ? badgeR.width + 24 : 16)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: n.usage >= 0 ? -9 : 0
            text: n.text; role: "label"
            color: n.on ? Theme.inkSecondaryC : Theme.inkVar
        }
        Rectangle {
            id: badgeR
            visible: !n.rail && n.badge !== ""
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
            width: Math.max(22, bt.implicitWidth + 12); height: 22; radius: Theme.sq ? 0 : (11)
            color: Theme.alpha(Theme.inkVar, 0.14)
            T { id: bt; anchors.centerIn: parent; text: n.badge; role: "small"; color: Theme.inkVar }
        }
        // how full a drive is
        Item {
            visible: !n.rail && n.usage >= 0
            x: 52; width: parent.width - x - 16; height: 18
            anchors.top: parent.verticalCenter; anchors.topMargin: 2
            Rectangle { y: 2; width: parent.width; height: 4; radius: Theme.sq ? 0 : (2); color: Theme.alpha(Theme.inkVar, 0.18)
                Rectangle { width: parent.width * Math.max(0.02, n.usage); height: 4; radius: Theme.sq ? 0 : (2)
                            color: n.usage > 0.9 ? Theme.error : Theme.primary } }
            T { y: 7; text: n.sub; role: "small"; color: Theme.inkVar; width: parent.width }
        }
    }
    T {
        visible: n.rail
        anchors.horizontalCenter: parent.horizontalCenter
        y: 38
        width: n.width - 4
        horizontalAlignment: Text.AlignHCenter
        text: n.text; role: "small"; font.weight: n.on ? 600 : 500
        color: n.on ? Theme.ink : Theme.inkVar
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(m) {
            Ui.untip(n)
            if (m.button === Qt.RightButton) n.menu(n)
            else if (m.button === Qt.MiddleButton) { if (n.path !== "") Sys.app("files", [n.path]) }
            else n.clicked()
        }
        onContainsMouseChanged: if (n.rail) { if (containsMouse) Ui.tip(n, n.text); else Ui.untip(n) }
    }
    DropArea {
        id: da
        anchors.fill: parent
        enabled: n.path !== "" && n.fa !== null
        onDropped: function(d) { if (n.fa) n.fa.dropInto(n.path, d) }
    }
}
