import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Dashboard tab: weather, you and this computer, clock, calendar, usage rings and music.
Item {
    id: h
    property var d
    property bool live: false
    readonly property var p: d.p
    property date now: new Date()
    property int monthOff: 0
    Timer { interval: 1000; running: h.live; repeat: true; triggeredOnStart: true; onTriggered: h.now = new Date() }
    onLiveChanged: if (live) monthOff = 0

    // ---------- weather (wttr.in through rice-weather, cached) ----------
    property string wCond: ""
    property string wTemp: "--"
    property string wPlace: ""
    Process {
        id: wCache
        command: ["bash", "-c", "cat \"$HOME/.cache/rice/weather.txt\" 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: h.takeWeather(text) }
    }
    Process {
        id: wFetch
        command: [Quickshell.env("HOME") + "/.local/bin/rice-weather"]
        stdout: StdioCollector { onStreamFinished: h.takeWeather(text) }
    }
    Timer { interval: 1200000; running: h.live; repeat: true; triggeredOnStart: true; onTriggered: if (!wFetch.running) wFetch.running = true }
    function takeWeather(t) {
        const q = t.trim().split("|")
        if (q.length >= 3) { wCond = q[0]; wTemp = q[1].replace("+", ""); wPlace = q[2] }
    }
    function wGlyph(c) {
        const s = c.toLowerCase(), night = now.getHours() < 6 || now.getHours() >= 20
        if (s.indexOf("thunder") >= 0) return d.md(0xF0593)
        if (s.indexOf("snow") >= 0 || s.indexOf("sleet") >= 0 || s.indexOf("ice") >= 0) return d.md(0xF0598)
        if (s.indexOf("heavy rain") >= 0 || s.indexOf("torrential") >= 0) return d.md(0xF0596)
        if (s.indexOf("rain") >= 0 || s.indexOf("drizzle") >= 0 || s.indexOf("shower") >= 0) return d.md(0xF0597)
        if (s.indexOf("fog") >= 0 || s.indexOf("mist") >= 0 || s.indexOf("haze") >= 0) return d.md(0xF0591)
        if (s.indexOf("partly") >= 0) return d.md(0xF0595)
        if (s.indexOf("cloud") >= 0 || s.indexOf("overcast") >= 0) return d.md(0xF0590)
        return night ? d.md(0xF0594) : d.md(0xF0599)
    }

    // ---------- music ----------
    function pickPlayer() {
        const l = Mpris.players.values
        for (let i = 0; i < l.length; i++) if (l[i].isPlaying) return l[i]
        return l.length > 0 ? l[0] : null
    }
    readonly property var player: pickPlayer()
    property real pos: 0
    Timer { interval: 1000; running: h.live && !!h.player && h.player.isPlaying; repeat: true; triggeredOnStart: true
            onTriggered: h.pos = h.player && h.player.position !== undefined ? h.player.position : 0 }
    function mmss(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    readonly property real gap: 12
    readonly property real mediaW: 250
    readonly property real leftW: width - mediaW - gap
    readonly property real row1: 96

    // ======== row 1: weather + you ========
    DCard {
        id: weather
        p: h.p; live: h.live; order: 0
        x: 0; y: 0
        width: 250; height: h.row1
        T { kind: "icon"; x: 22; anchors.verticalCenter: parent.verticalCenter; text: h.wGlyph(h.wCond); font.pixelSize: 44; color: h.p.sub }
        Column {
            x: 94; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 104
            spacing: 0
            T { kind: "number"; text: h.wTemp; font.pixelSize: 30; font.bold: true; color: h.p.primary }
            T { width: parent.width; elide: Text.ElideRight; text: h.wCond !== "" ? h.wCond : "No weather yet"; font.pixelSize: 12; color: h.p.text }
            T { width: parent.width; elide: Text.ElideRight; visible: h.wPlace !== ""; text: h.wPlace; font.pixelSize: 10; color: h.p.sub }
        }
    }
    DCard {
        id: you
        p: h.p; live: h.live; order: 1
        x: weather.width + h.gap; y: 0
        width: h.leftW - weather.width - h.gap; height: h.row1
        // avatar with the distro logo as a badge
        Item {
            id: av
            x: 18; anchors.verticalCenter: parent.verticalCenter
            width: 64; height: 64
            Rectangle { anchors.fill: parent; radius: 32; color: h.p.container }
            RoundImage {
                anchors.fill: parent
                cornerRadius: 32
                source: "file://" + Quickshell.env("HOME") + "/.face"
                fallback: ""
            }
            T { visible: true; kind: "icon"; anchors.centerIn: parent; z: -1; text: h.d.md(0xF0014); font.pixelSize: 26; color: h.p.onContainer }
            Rectangle {
                x: -6; y: -6
                width: 26; height: 26; radius: 13
                color: h.p.primary
                border.width: 2
                border.color: h.p.card
                T { kind: "icon"; anchors.centerIn: parent; text: h.d.distroGlyph(); font.pixelSize: 12; color: h.p.onPrimary }
            }
        }
        Column {
            anchors.left: av.right; anchors.leftMargin: 18
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            T { width: parent.width; elide: Text.ElideRight; text: h.d.greeting(h.now) + ", " + (Quickshell.env("USER") || "you"); font.pixelSize: 15; font.bold: true; color: h.p.text }
            Row {
                spacing: 8
                Chip { icon: h.d.md(0xF0379); text: h.d.about.host || "Hyprland" }
                Chip { icon: h.d.md(0xF051B); text: "up " + h.d.uptimeText(h.d.stats.uptime || h.d.about.uptime || 0) }
            }
        }
    }

    // ======== row 2: clock, calendar, rings ========
    DCard {
        id: clockC
        p: h.p; live: h.live; order: 2
        x: 0; y: h.row1 + h.gap
        width: 100; height: h.height - y
        Column {
            anchors.centerIn: parent
            spacing: 2
            T { anchors.horizontalCenter: parent.horizontalCenter; kind: "number"; text: Qt.formatTime(h.now, "HH"); font.pixelSize: 34; font.bold: true; color: h.p.primary }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Repeater { model: 3; Rectangle { width: 5; height: 5; radius: 2.5; color: h.p.primary; opacity: index === (h.now.getSeconds() % 3) ? 1 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 300 } } } }
            }
            T { anchors.horizontalCenter: parent.horizontalCenter; kind: "number"; text: Qt.formatTime(h.now, "mm"); font.pixelSize: 34; font.bold: true; color: h.p.primary }
            T { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(h.now, "ddd").toUpperCase(); font.pixelSize: 12; font.bold: true; color: h.p.sub; topPadding: 4 }
        }
    }
    DCard {
        id: cal
        p: h.p; live: h.live; order: 3
        x: clockC.width + h.gap; y: clockC.y
        width: h.leftW - clockC.width - rings.width - 2 * h.gap; height: clockC.height
        readonly property date first: new Date(h.now.getFullYear(), h.now.getMonth() + h.monthOff, 1)
        readonly property int lead: (first.getDay() + 6) % 7
        Item {
            id: calHead
            x: 16; y: 10
            width: parent.width - 32; height: 26
            T { anchors.centerIn: parent; text: Qt.formatDate(cal.first, "MMMM yyyy"); font.pixelSize: 14; font.bold: true; color: h.p.primary }
            IconBtn { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; icon: h.d.md(0xF0141); onClicked: h.monthOff-- }
            IconBtn { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; icon: h.d.md(0xF0142); onClicked: h.monthOff++ }
        }
        Grid {
            id: cg
            x: 12; y: calHead.y + calHead.height + 4
            columns: 7
            readonly property real cw: (cal.width - 24) / 7
            readonly property real ch: (cal.height - y - 8) / 7
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                T { width: cg.cw; height: cg.ch; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: modelData; font.pixelSize: 11; font.bold: true; color: h.p.text }
            }
            Repeater {
                model: 42
                Item {
                    width: cg.cw; height: cg.ch
                    readonly property date day: new Date(cal.first.getFullYear(), cal.first.getMonth(), index - cal.lead + 1)
                    readonly property bool inMonth: day.getMonth() === cal.first.getMonth()
                    readonly property bool today: day.toDateString() === h.now.toDateString()
                    Rectangle {
                        visible: parent.today
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) + 2; height: width; radius: width / 2
                        color: h.p.primary
                    }
                    T { anchors.centerIn: parent; text: parent.day.getDate(); font.pixelSize: 11; font.bold: parent.today
                        color: parent.today ? h.p.onPrimary : (parent.inMonth ? h.p.text : h.p.sub); opacity: parent.inMonth ? 1 : 0.45 }
                }
            }
        }
    }
    DCard {
        id: rings
        p: h.p; live: h.live; order: 4
        x: h.leftW - width; y: clockC.y
        width: 88; height: clockC.height
        Column {
            anchors.centerIn: parent
            spacing: 8
            Repeater {
                model: [
                    { g: 0xF061A, v: h.d.stats.cpu ? h.d.stats.cpu.usage : 0, n: "CPU" },
                    { g: 0xF035B, v: h.d.stats.mem ? h.d.stats.mem.pct : 0, n: "RAM" },
                    { g: 0xF02CA, v: h.d.disk ? h.d.disk.pct : 0, n: "Disk" }
                ]
                Item {
                    width: 60; height: (rings.height - 32) / 3
                    DRing { anchors.centerIn: parent; width: Math.min(60, parent.height); height: width; p: h.p; value: h.live ? modelData.v : 0; line: 5 }
                    T { kind: "icon"; anchors.centerIn: parent; text: h.d.md(modelData.g); font.pixelSize: 16; color: h.p.text }
                }
            }
        }
    }

    // ======== music ========
    DCard {
        id: media
        p: h.p; live: h.live; order: 5; strong: true
        x: h.leftW + h.gap; y: 0
        width: h.mediaW; height: h.height
        Rectangle {
            id: coverBox
            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            width: 132; height: 132; radius: 26
            color: h.p.container
            clip: true
            T { anchors.centerIn: parent; kind: "icon"; text: h.d.md(0xF075A); font.pixelSize: 46; color: h.p.onContainer; visible: !(h.player && h.player.trackArtUrl) }
            RoundImage {
                anchors.fill: parent
                cornerRadius: 26
                fallback: ""
                source: h.player && h.player.trackArtUrl ? h.player.trackArtUrl : ""
            }
        }
        Column {
            y: coverBox.y + coverBox.height + 14
            x: 16; width: parent.width - 32
            spacing: 2
            T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: h.player && h.player.trackTitle ? h.player.trackTitle : "No media"; font.pixelSize: 14; font.bold: true; color: h.p.primary }
            T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: h.player && h.player.trackArtist ? h.player.trackArtist : "Play something"; font.pixelSize: 12; color: h.p.sub }
        }
        // progress
        Item {
            id: prog
            x: 18; width: parent.width - 36; height: 14
            y: parent.height - 92
            visible: !!h.player && h.player.length > 0
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: h.p.track }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * (h.player && h.player.length > 0 ? Math.min(1, h.pos / h.player.length) : 0); height: 4; radius: 2; color: h.p.primary
                Behavior on width { NumberAnimation { duration: 900 } } }
            T { anchors.left: parent.left; y: 12; text: h.mmss(h.pos); font.pixelSize: 9; color: h.p.sub }
            T { anchors.right: parent.right; y: 12; text: h.player ? h.mmss(h.player.length) : ""; font.pixelSize: 9; color: h.p.sub }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 56
            spacing: 10
            IconBtn { size: 40; icon: h.d.md(0xF04AE); enabled: !!h.player; onClicked: h.player.previous() }
            Rectangle {
                width: 64; height: 40; radius: 20
                color: playM.containsMouse ? Qt.lighter(h.p.primary, 1.1) : h.p.primary
                scale: playM.pressed ? 0.93 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                T { kind: "icon"; anchors.centerIn: parent; text: h.player && h.player.isPlaying ? h.d.md(0xF03E4) : h.d.md(0xF040A); font.pixelSize: 20; color: h.p.onPrimary }
                MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (h.player) h.player.togglePlaying() }
            }
            IconBtn { size: 40; icon: h.d.md(0xF04AD); enabled: !!h.player; onClicked: h.player.next() }
        }
    }

    // ---------- small parts ----------
    component Chip: Rectangle {
        property string icon: ""
        property string text: ""
        height: 28
        width: Math.min(220, cr.implicitWidth + 22)
        radius: 14
        color: h.p.container
        Row {
            id: cr
            anchors.centerIn: parent
            spacing: 6
            T { kind: "icon"; text: parent.parent.icon; font.pixelSize: 12; color: h.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
            T { text: parent.parent.text; font.pixelSize: 11; color: h.p.onContainer; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: Math.min(implicitWidth, 180) }
        }
    }
    component IconBtn: Rectangle {
        id: ib
        property string icon: ""
        property real size: 26
        signal clicked()
        width: size; height: size; radius: size / 2
        color: im.containsMouse ? h.p.container : "transparent"
        opacity: enabled ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: 120 } }
        T { kind: "icon"; anchors.centerIn: parent; text: ib.icon; font.pixelSize: ib.size * 0.48; color: h.p.text }
        MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
    }
}
