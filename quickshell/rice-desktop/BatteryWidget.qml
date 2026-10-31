import Quickshell.Io
import QtQuick

// Battery: ring with the charge, state and time left. Shows "No battery" on desktops.
Item {
    id: bt
    property real bg: 1
    property bool running: true
    property int pct: -1
    property string status: ""
    property string remain: ""

    Process {
        id: proc
        command: ["bash", "-c", "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -n \"$b\" ] || exit 0; " +
                  "printf '%s\\n%s\\n' \"$(cat $b/capacity)\" \"$(cat $b/status)\"; " +
                  "upower -i $(upower -e 2>/dev/null | grep -m1 BAT) 2>/dev/null | grep -E 'time to (empty|full)' | sed 's/.*: *//' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("\n")
                bt.pct = p[0] && p[0].length ? parseInt(p[0]) : -1
                bt.status = p[1] ? p[1].trim() : ""
                bt.remain = p[2] ? p[2].trim() : ""
            }
        }
    }
    Timer { interval: 30000; running: bt.running && bt.visible; repeat: true; triggeredOnStart: true; onTriggered: if (!proc.running) proc.running = true }

    readonly property bool charging: status === "Charging" || status === "Full"
    Card { anchors.fill: parent; k: bt.bg }

    Canvas {
        id: ring
        width: 72; height: 72
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        property real v: Math.max(0, bt.pct)
        Behavior on v { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        onVChanged: requestPaint()
        onPaint: {
            const c = getContext("2d")
            c.reset()
            c.lineWidth = 6
            c.lineCap = "round"
            c.strokeStyle = "rgba(255,255,255,0.12)"
            c.beginPath(); c.arc(36, 36, 30, 0, Math.PI * 2); c.stroke()
            c.strokeStyle = bt.pct >= 0 && bt.pct <= 15 && !bt.charging ? "#e06c75" : "#F6F5F4"
            c.beginPath(); c.arc(36, 36, 30, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.01, v / 100)); c.stroke()
        }
        T { kind: "icon"; anchors.centerIn: parent; text: bt.charging ? "" : ""; font.pixelSize: 18; color: "#c8c8cc" }
    }
    Column {
        anchors.left: ring.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        T { kind: "number"; text: bt.pct >= 0 ? bt.pct + "%" : "No battery"; font.pixelSize: bt.pct >= 0 ? 30 : 18; font.bold: true }
        T {
            text: bt.pct < 0 ? "This computer runs on power" : (bt.status === "Full" ? "Fully charged" : (bt.charging ? "Charging" : "On battery") + (bt.remain ? "  ·  " + bt.remain : ""))
            font.pixelSize: 12; color: "#8a8a8f"
        }
    }
}
