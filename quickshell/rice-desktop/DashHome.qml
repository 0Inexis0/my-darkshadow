import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Dashboard tab: weather, you, clock, calendar, usage rings and music. Cards can be edited.
Item {
    id: h
    property var d
    property bool live: false
    readonly property var p: d.p
    property date now: new Date()
    property int monthOff: 0
    Timer { interval: 1000; running: h.live; repeat: true; triggeredOnStart: true; onTriggered: h.now = new Date() }
    onLiveChanged: if (live) monthOff = 0

    // ---------- weather ----------
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
    function wIcon(c) {
        const s = c.toLowerCase(), night = now.getHours() < 6 || now.getHours() >= 20
        if (s.indexOf("thunder") >= 0) return ["thunderstorm", 0xF0593]
        if (s.indexOf("snow") >= 0 || s.indexOf("sleet") >= 0 || s.indexOf("ice") >= 0) return ["weather_snowy", 0xF0598]
        if (s.indexOf("rain") >= 0 || s.indexOf("drizzle") >= 0 || s.indexOf("shower") >= 0) return ["rainy", 0xF0597]
        if (s.indexOf("fog") >= 0 || s.indexOf("mist") >= 0 || s.indexOf("haze") >= 0) return ["foggy", 0xF0591]
        if (s.indexOf("partly") >= 0) return ["partly_cloudy_day", 0xF0595]
        if (s.indexOf("cloud") >= 0 || s.indexOf("overcast") >= 0) return ["cloud", 0xF0590]
        return night ? ["clear_night", 0xF0594] : ["sunny", 0xF0599]
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
    function mmss(s) { s = Math.max(0, Math.floor(s || 0)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    DashGrid {
        anchors.fill: parent
        d: h.d
        tabId: "dashboard"
        layoutKey: h.d.side ? "dashboard-side" : ""
        cols: h.d.side ? 6 : 12
        rows: h.d.side ? 6 : 3
        live: h.live
        catalog: [
            { id: "weather", name: "Weather", sizes: [[3, 1], [4, 1], [2, 1]] },
            { id: "profile", name: "You", sizes: [[5, 1], [4, 1], [6, 1]] },
            { id: "media", name: "Music", sizes: [[4, 3], [3, 3], [4, 2], [5, 1]] },
            { id: "clock", name: "Clock", sizes: [[1, 2], [2, 2], [2, 1]] },
            { id: "calendar", name: "Calendar", sizes: [[5, 2], [4, 2], [6, 2]] },
            { id: "rings", name: "Usage", sizes: [[2, 2], [1, 2], [3, 1]] }
        ]
        defaults: h.d.side ? [
            { id: "profile", x: 0, y: 0, w: 6, h: 1 }, { id: "weather", x: 0, y: 1, w: 4, h: 1 }, { id: "clock", x: 4, y: 1, w: 2, h: 1 },
            { id: "calendar", x: 0, y: 2, w: 6, h: 2 }, { id: "media", x: 0, y: 4, w: 4, h: 2 }, { id: "rings", x: 4, y: 4, w: 2, h: 2 }
        ] : [
            { id: "weather", w: 3, h: 1 }, { id: "profile", w: 5, h: 1 }, { id: "media", w: 4, h: 3 },
            { id: "clock", w: 1, h: 2 }, { id: "calendar", w: 5, h: 2 }, { id: "rings", w: 2, h: 2 }
        ]
        comps: ({ weather: weatherC, profile: profileC, media: mediaC, clock: clockC, calendar: calC, rings: ringsC })
    }

    // ================= cards =================
    Component {
        id: weatherC
        DCard {
            id: wc
            p: h.p
            readonly property var ic: h.wIcon(h.wCond)
            MIcon { id: wi; x: 18; anchors.verticalCenter: parent.verticalCenter; name: wc.ic[0]; glyph: h.d.md(wc.ic[1]); size: Math.min(48, wc.height * 0.48); color: h.p.primary }
            Column {
                anchors.left: wi.right; anchors.leftMargin: 14
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                DText { text: h.wTemp; font.pixelSize: Math.min(32, wc.height * 0.3); font.weight: Font.DemiBold; color: h.p.text }
                DText { width: parent.width; elide: Text.ElideRight; text: h.wCond !== "" ? h.wCond : "No weather yet"; font.pixelSize: 12; color: h.p.sub }
            }
        }
    }
    Component {
        id: profileC
        DCard {
            id: pc
            p: h.p
            Item {
                id: av
                readonly property real s: Math.min(64, pc.height - 30)
                x: 18; anchors.verticalCenter: parent.verticalCenter
                width: s; height: s
                Rectangle { anchors.fill: parent; radius: width / 2; color: h.p.container }
                MIcon { anchors.centerIn: parent; name: "person"; glyph: h.d.md(0xF0004); size: av.s * 0.45; color: h.p.onContainer }
                Image { id: faceProbe; visible: false; source: "file://" + Quickshell.env("HOME") + "/.face"; sourceSize.width: 8 }
                RoundImage { visible: faceProbe.status === Image.Ready; anchors.fill: parent; cornerRadius: width / 2; source: faceProbe.source; fallback: "" }
                Rectangle {
                    x: -4; y: -4
                    width: 24; height: 24; radius: 12
                    color: h.p.primary
                    border.width: 2; border.color: h.p.solidBg
                    Text { anchors.centerIn: parent; text: h.d.distroGlyph(); font.family: DashFont.nerd; font.pixelSize: 11; color: h.p.inkOn }
                }
            }
            Column {
                anchors.left: av.right; anchors.leftMargin: 16
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                DText { width: parent.width; elide: Text.ElideRight; text: h.d.greeting(h.now) + ", " + (Quickshell.env("USER") || "you"); font.pixelSize: 16; font.weight: Font.DemiBold; color: h.p.text }
                Flow {
                    width: parent.width
                    spacing: 6
                    Chip { icon: "computer"; glyph: h.d.md(0xF0379); text: h.d.about.host || "Hyprland" }
                    Chip { icon: "schedule"; glyph: h.d.md(0xF051B); text: "up " + h.d.uptimeText(h.d.stats.uptime || h.d.about.uptime || 0) }
                }
            }
        }
    }
    Component {
        id: clockC
        DCard {
            id: cc
            p: h.p
            readonly property bool tall: height > width * 1.2
            Column {
                visible: cc.tall
                anchors.centerIn: parent
                spacing: 0
                DText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(h.now, "HH"); font.pixelSize: Math.min(40, cc.width * 0.5); font.weight: Font.DemiBold; color: h.p.primary }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5
                    Repeater { model: 3; Rectangle { width: 5; height: 5; radius: 2.5; color: h.p.primary; opacity: index === (h.now.getSeconds() % 3) ? 1 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 300 } } } }
                }
                DText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(h.now, "mm"); font.pixelSize: Math.min(40, cc.width * 0.5); font.weight: Font.DemiBold; color: h.p.primary }
                DText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(h.now, "ddd").toUpperCase(); font.pixelSize: 11; font.weight: Font.Medium; color: h.p.sub; topPadding: 6 }
            }
            Column {
                visible: !cc.tall
                anchors.centerIn: parent
                DText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(h.now, "HH:mm"); font.pixelSize: Math.min(44, cc.height * 0.4); font.weight: Font.DemiBold; color: h.p.primary }
                DText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(h.now, "dddd, d MMMM"); font.pixelSize: 12; color: h.p.sub }
            }
        }
    }
    Component {
        id: calC
        DCard {
            id: cal
            p: h.p
            readonly property date first: new Date(h.now.getFullYear(), h.now.getMonth() + h.monthOff, 1)
            readonly property int lead: (first.getDay() + 6) % 7
            Item {
                id: calHead
                x: 14; y: 8
                width: parent.width - 28; height: 28
                DText { anchors.centerIn: parent; text: Qt.formatDate(cal.first, "MMMM yyyy"); font.pixelSize: 14; font.weight: Font.DemiBold; color: h.p.primary }
                IconBtn { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; icon: "chevron_left"; glyph: h.d.md(0xF0141); onClicked: h.monthOff-- }
                IconBtn { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; icon: "chevron_right"; glyph: h.d.md(0xF0142); onClicked: h.monthOff++ }
            }
            Grid {
                id: cg
                x: 10; y: calHead.y + calHead.height + 2
                columns: 7
                readonly property real cw: (cal.width - 20) / 7
                readonly property real ch: (cal.height - y - 8) / 7
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    DText { width: cg.cw; height: cg.ch; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: modelData; font.pixelSize: 11; font.weight: Font.Medium; color: h.p.sub }
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
                            width: Math.min(parent.width, parent.height) + 3; height: width; radius: width / 2
                            color: h.p.primary
                        }
                        DText { anchors.centerIn: parent; text: parent.day.getDate(); font.pixelSize: 11; font.weight: parent.today ? Font.DemiBold : Font.Normal
                            color: parent.today ? h.p.inkOn : h.p.text; opacity: parent.inMonth ? 1 : 0.35 }
                    }
                }
            }
        }
    }
    Component {
        id: ringsC
        DCard {
            id: rc
            p: h.p
            readonly property bool tall: height >= width
            readonly property var items: [
                { n: "memory", g: 0xF061A, v: h.d.stats.cpu ? h.d.stats.cpu.usage : 0, t: "CPU" },
                { n: "memory_alt", g: 0xF035B, v: h.d.stats.mem ? h.d.stats.mem.pct : 0, t: "RAM" },
                { n: "hard_drive", g: 0xF02CA, v: h.d.disk ? h.d.disk.pct : 0, t: "Disk" }
            ]
            Grid {
                anchors.centerIn: parent
                columns: rc.tall ? 1 : 3
                spacing: rc.tall ? 6 : 16
                Repeater {
                    model: rc.items
                    Item {
                        readonly property real s: rc.tall ? Math.min(rc.width - 20, (rc.height - 32) / 3) : Math.min(rc.height - 30, (rc.width - 50) / 3)
                        width: s; height: s
                        DRing { anchors.fill: parent; p: h.p; value: h.live ? modelData.v : 0; line: 5 }
                        MIcon { anchors.centerIn: parent; name: modelData.n; glyph: h.d.md(modelData.g); size: parent.s * 0.32; color: h.p.text }
                    }
                }
            }
        }
    }
    Component {
        id: mediaC
        DCard {
            id: mc
            p: h.p
            strong: true
            readonly property bool tall: height > width * 0.9
            readonly property real cs: tall ? Math.min(width - 60, height * 0.42) : height - 28
            Rectangle {
                id: cover
                x: mc.tall ? (mc.width - width) / 2 : 14
                y: mc.tall ? 18 : 14
                width: mc.cs; height: mc.cs
                radius: Math.min(26, width * 0.2)
                color: h.p.container
                MIcon { anchors.centerIn: parent; name: "music_note"; glyph: h.d.md(0xF075A); size: cover.width * 0.36; color: h.p.onContainer; visible: !(h.player && h.player.trackArtUrl) }
                RoundImage { anchors.fill: parent; cornerRadius: cover.radius; fallback: ""; source: h.player && h.player.trackArtUrl ? h.player.trackArtUrl : "" }
            }
            Column {
                id: info
                x: mc.tall ? 16 : cover.x + cover.width + 16
                y: mc.tall ? cover.y + cover.height + 14 : 16
                width: mc.tall ? mc.width - 32 : mc.width - x - 16
                spacing: 2
                DText { width: parent.width; horizontalAlignment: mc.tall ? Text.AlignHCenter : Text.AlignLeft; elide: Text.ElideRight
                    text: h.player && h.player.trackTitle ? h.player.trackTitle : "Nothing playing"; font.pixelSize: 15; font.weight: Font.DemiBold; color: h.p.text }
                DText { width: parent.width; horizontalAlignment: mc.tall ? Text.AlignHCenter : Text.AlignLeft; elide: Text.ElideRight
                    text: h.player && h.player.trackArtist ? h.player.trackArtist : "Play something to see it here"; font.pixelSize: 12; color: h.p.sub }
            }
            Item {
                id: prog
                x: info.x; width: info.width; height: 14
                y: mc.height - 86
                visible: !!h.player && h.player.length > 0 && mc.height > 150
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: h.p.track }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * (h.player && h.player.length > 0 ? Math.min(1, h.pos / h.player.length) : 0); height: 4; radius: 2; color: h.p.primary
                    Behavior on width { NumberAnimation { duration: 900 } } }
                DText { anchors.left: parent.left; y: 12; text: h.mmss(h.pos); font.pixelSize: 9; color: h.p.sub }
                DText { anchors.right: parent.right; y: 12; text: h.player ? h.mmss(h.player.length) : ""; font.pixelSize: 9; color: h.p.sub }
            }
            Row {
                x: mc.tall ? (mc.width - width) / 2 : info.x
                y: mc.height - height - 14
                spacing: 10
                IconBtn { size: 38; icon: "skip_previous"; glyph: h.d.md(0xF04AE); enabled: !!h.player; onClicked: h.player.previous() }
                Rectangle {
                    width: 60; height: 38; radius: 19
                    color: playM.containsMouse ? Qt.lighter(h.p.primary, 1.08) : h.p.primary
                    scale: playM.pressed ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    MIcon { anchors.centerIn: parent; name: h.player && h.player.isPlaying ? "pause" : "play_arrow"; glyph: h.player && h.player.isPlaying ? h.d.md(0xF03E4) : h.d.md(0xF040A); size: 22; color: h.p.inkOn }
                    MouseArea { id: playM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (h.player) h.player.togglePlaying() }
                }
                IconBtn { size: 38; icon: "skip_next"; glyph: h.d.md(0xF04AD); enabled: !!h.player; onClicked: h.player.next() }
            }
        }
    }

    // ---------- small parts ----------
    component Chip: Rectangle {
        id: chp
        property string icon: ""
        property string glyph: ""
        property string text: ""
        height: 28
        width: Math.min(230, cr.implicitWidth + 22)
        radius: 14
        color: h.p.container
        Row {
            id: cr
            anchors.centerIn: parent
            spacing: 6
            MIcon { name: chp.icon; glyph: chp.glyph; size: 14; color: h.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
            DText { text: chp.text; font.pixelSize: 11; color: h.p.onContainer; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: Math.min(implicitWidth, 180) }
        }
    }
    component IconBtn: Rectangle {
        id: ib
        property string icon: ""
        property string glyph: ""
        property real size: 26
        signal clicked()
        width: size; height: size; radius: size / 2
        color: im.containsMouse ? h.p.container : "transparent"
        opacity: enabled ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: 120 } }
        MIcon { anchors.centerIn: parent; name: ib.icon; glyph: ib.glyph; size: ib.size * 0.6; color: h.p.text }
        MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
    }
}
