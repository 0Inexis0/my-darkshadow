import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: rs
    property real bg: 1   // card background opacity (widget editor)
    property var pal: null
    property bool running: true
    property int cpu: 0
    property int ram: 0
    property int gpu: 0

    Process {
        command: [Quickshell.env("HOME") + "/.local/bin/rice-stats"]
        running: rs.running
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    const j = JSON.parse(line)
                    rs.cpu = j.cpu
                    rs.ram = j.ram
                    rs.gpu = j.gpu
                } catch (e) { }
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12
        Repeater {
            model: [
                { name: "CPU", icon: "", key: "cpu" },
                { name: "RAM", icon: "󰍛", key: "ram" },
                { name: "GPU", icon: "", key: "gpu" }
            ]
            delegate: Item {
                id: cell
                width: rs.width
                height: (rs.height - 24) / 3
                readonly property int val: modelData.key === "cpu" ? rs.cpu : (modelData.key === "ram" ? rs.ram : rs.gpu)
                Card { anchors.fill: parent; k: rs.bg; pal: rs.pal }

                Canvas {
                    id: ring
                    width: 52
                    height: 52
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    property real v: cell.val
                    Behavior on v { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    onVChanged: requestPaint()
                    property color trackC: rs.pal ? rs.pal.track : Qt.rgba(1, 1, 1, 0.12)
                    property color fillC: rs.pal ? rs.pal.primary : "#F6F5F4"
                    onTrackCChanged: requestPaint()
                    onFillCChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d")
                        c.reset()
                        c.lineWidth = 5
                        c.lineCap = "round"
                        c.strokeStyle = trackC
                        c.beginPath()
                        c.arc(26, 26, 21, 0, Math.PI * 2)
                        c.stroke()
                        c.strokeStyle = fillC
                        c.beginPath()
                        c.arc(26, 26, 21, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.01, v / 100))
                        c.stroke()
                    }
                    T { kind: "icon"; anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 15; color: rs.pal ? rs.pal.fg2 : "#c8c8cc" }
                }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    spacing: 0
                    T { kind: "number"; text: cell.val + "%"; font.pixelSize: 26; font.bold: true; color: rs.pal ? rs.pal.fg : "#F6F5F4" }
                    T { text: modelData.name; font.pixelSize: 12; color: rs.pal ? rs.pal.fg3 : "#8a8a8f" }
                }
            }
        }
    }
}
