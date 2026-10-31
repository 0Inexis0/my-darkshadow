import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: we
    property real bg: 1   // card background opacity (widget editor)
    property bool running: true
    property string cond: ""
    property string temp: "--"
    property string place: ""
    property string error: ""

    function glyph(c) {
        const s = c.toLowerCase()
        if (s.indexOf("thunder") >= 0) return ""
        if (s.indexOf("snow") >= 0 || s.indexOf("sleet") >= 0 || s.indexOf("ice") >= 0) return ""
        if (s.indexOf("rain") >= 0 || s.indexOf("drizzle") >= 0 || s.indexOf("shower") >= 0) return ""
        if (s.indexOf("fog") >= 0 || s.indexOf("mist") >= 0) return ""
        if (s.indexOf("cloud") >= 0 || s.indexOf("overcast") >= 0) return ""
        return ""
    }

    Process {
        id: fetch
        command: [Quickshell.env("HOME") + "/.local/bin/rice-weather"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                if (p.length >= 3) {
                    we.cond = p[0]
                    we.temp = p[1].replace("+", "")
                    we.place = p[2]
                    we.error = ""
                } else {
                    we.error = "No weather data"
                }
            }
        }
    }
    Timer {
        interval: 1200000
        running: we.running
        repeat: true
        triggeredOnStart: true
        onTriggered: fetch.running = true
    }
    onRunningChanged: if (running) fetch.running = true

    Card { anchors.fill: parent; k: we.bg }

    T {
        id: ic
        kind: "icon"
        x: 24
        anchors.verticalCenter: parent.verticalCenter
        text: we.glyph(we.cond)
        font.pixelSize: 52
    }
    Column {
        anchors.left: ic.right
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        T { kind: "number"; text: we.temp; font.pixelSize: 34; font.bold: true }
        T { text: we.error !== "" ? we.error : we.cond; font.pixelSize: 13; color: "#c8c8cc"; width: parent.width; elide: Text.ElideRight }
        T { text: we.place; font.pixelSize: 11; color: "#8a8a8f"; width: parent.width; elide: Text.ElideRight }
    }
}
