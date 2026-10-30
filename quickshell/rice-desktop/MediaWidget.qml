import Quickshell.Services.Mpris
import QtQuick

Item {
    id: me
    function pick() {
        const l = Mpris.players.values
        for (let i = 0; i < l.length; i++) if (l[i].isPlaying) return l[i]
        return l.length > 0 ? l[0] : null
    }
    readonly property var player: pick()

    Card { anchors.fill: parent }

    RoundImage {
        id: art
        x: 0
        y: 0
        width: 120
        height: parent.height
        cornerRadius: 26
        fallback: ""
        source: me.player && me.player.trackArtUrl ? me.player.trackArtUrl : ""
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 22
        spacing: 3
        T {
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 16
            font.bold: true
            text: me.player ? (me.player.trackTitle || "Unknown") : "Nothing playing"
        }
        T {
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: 12
            color: "#a8a8ad"
            text: me.player ? (me.player.trackArtist || "") : "Start some music"
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        spacing: 10
        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: "transparent"
            opacity: me.player ? 1 : 0.35
            T { anchors.centerIn: parent; text: ""; font.pixelSize: 14 }
            MouseArea {
                anchors.fill: parent
                enabled: me.player !== null
                cursorShape: Qt.PointingHandCursor
                onClicked: me.player.previous()
            }
        }
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: "#F6F5F4"
            opacity: me.player ? 1 : 0.35
            T {
                anchors.centerIn: parent
                text: me.player && me.player.isPlaying ? "" : ""
                font.pixelSize: 16
                color: "#0d0d0d"
            }
            MouseArea {
                anchors.fill: parent
                enabled: me.player !== null
                cursorShape: Qt.PointingHandCursor
                onClicked: me.player.togglePlaying()
            }
        }
        Rectangle {
            width: 34
            height: 34
            radius: 17
            color: "transparent"
            opacity: me.player ? 1 : 0.35
            T { anchors.centerIn: parent; text: ""; font.pixelSize: 14 }
            MouseArea {
                anchors.fill: parent
                enabled: me.player !== null
                cursorShape: Qt.PointingHandCursor
                onClicked: me.player.next()
            }
        }
    }
}
