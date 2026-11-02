import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Dashboard tab: a day board (time and day line, weather, quick switches, week, now playing, pulse, to-do).
// The older cards (You, Clock, Calendar, Usage, Music) can still be added in edit mode. Cards can be edited.
Item {
    id: h
    property var d
    property bool live: false
    readonly property var p: d.p
    property date now: new Date()
    property int monthOff: 0
    property int weekOff: 0
    Timer { interval: 1000; running: h.live; repeat: true; triggeredOnStart: true; onTriggered: h.now = new Date() }
    onLiveChanged: if (live) { monthOff = 0; weekOff = 0 }

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
    function isoWeek(dt) {
        const t = new Date(Date.UTC(dt.getFullYear(), dt.getMonth(), dt.getDate()))
        const dn = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - dn)
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - y0) / 86400000 + 1) / 7)
    }
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
            { id: "hero", name: "Time", sizes: [[5, 1], [6, 1], [4, 1], [5, 2], [6, 2], [8, 2]] },
            { id: "weather", name: "Weather", sizes: [[3, 1], [4, 1], [2, 1], [3, 2]] },
            { id: "quick", name: "Switches", sizes: [[4, 1], [3, 1], [5, 1], [6, 1], [3, 2]] },
            { id: "now", name: "Now playing", sizes: [[4, 2], [5, 2], [6, 2], [4, 3], [3, 2]] },
            { id: "week", name: "Week", sizes: [[4, 1], [5, 1], [6, 1], [4, 2]] },
            { id: "pulse", name: "Pulse", sizes: [[4, 2], [3, 2], [4, 3], [5, 1], [6, 1]] },
            { id: "tasks", name: "To-do", sizes: [[4, 1], [3, 1], [4, 2], [5, 2], [3, 2], [6, 2]] },
            { id: "profile", name: "You", sizes: [[5, 1], [4, 1], [6, 1]] },
            { id: "media", name: "Music", sizes: [[4, 3], [3, 3], [4, 2], [5, 1]] },
            { id: "clock", name: "Clock", sizes: [[1, 2], [2, 2], [2, 1]] },
            { id: "calendar", name: "Calendar", sizes: [[5, 2], [4, 2], [6, 2]] },
            { id: "rings", name: "Usage", sizes: [[2, 2], [1, 2], [3, 1]] }
        ]
        defaults: h.d.side ? [
            { id: "hero", x: 0, y: 0, w: 6, h: 1 }, { id: "weather", x: 0, y: 1, w: 3, h: 1 }, { id: "quick", x: 3, y: 1, w: 3, h: 1 },
            { id: "week", x: 0, y: 2, w: 6, h: 1 }, { id: "now", x: 0, y: 3, w: 3, h: 2 }, { id: "pulse", x: 3, y: 3, w: 3, h: 2 },
            { id: "tasks", x: 0, y: 5, w: 6, h: 1 }
        ] : [
            { id: "hero", x: 0, y: 0, w: 5, h: 1 }, { id: "weather", x: 5, y: 0, w: 3, h: 1 }, { id: "quick", x: 8, y: 0, w: 4, h: 1 },
            { id: "now", x: 0, y: 1, w: 4, h: 2 }, { id: "week", x: 4, y: 1, w: 4, h: 1 }, { id: "tasks", x: 4, y: 2, w: 4, h: 1 },
            { id: "pulse", x: 8, y: 1, w: 4, h: 2 }
        ]
        comps: ({ hero: heroC, weather: weatherC, quick: quickC, now: nowC, week: weekC, pulse: pulseC, tasks: tasksC,
                  profile: profileC, media: mediaC, clock: clockC, calendar: calC, rings: ringsC })
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
                DText { visible: wc.height > 90 && h.wPlace !== ""; width: parent.width; elide: Text.ElideRight; text: h.wPlace; font.pixelSize: 11; color: h.p.sub; opacity: 0.7 }
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
            readonly property bool tall: height > width * 0.9 || width < 340   // narrow card: cover on top, text and buttons under it
            readonly property real cs: tall ? Math.min(width - 60, height * 0.42) : Math.min(height - 28, width * 0.4)
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

    // ================= the day board =================
    // Time, with a line for the day that has passed
    Component {
        id: heroC
        DCard {
            id: hc
            p: h.p
            strong: true
            readonly property real frac: (h.now.getHours() * 3600 + h.now.getMinutes() * 60 + h.now.getSeconds()) / 86400
            readonly property bool big: height > 150
            readonly property real ts: Math.max(32, Math.min(big ? 84 : 58, (height - 40) * 0.8, width * 0.2))
            readonly property real lineY: height - 24
            DText {
                id: tm
                x: 20; y: Math.max(6, (hc.lineY - 8 - height) / 2 + 2)
                text: Qt.formatTime(h.now, "HH:mm")
                font.pixelSize: hc.ts; font.weight: Font.Light; color: h.p.text
            }
            DText {
                id: sec
                x: tm.x + tm.width + 4; y: tm.y + tm.height * 0.2
                text: Qt.formatTime(h.now, "ss")
                font.pixelSize: Math.max(12, hc.ts * 0.3); font.weight: Font.Medium; color: h.p.primary
            }
            Column {
                visible: hc.width - sec.x - sec.width > 150
                x: sec.x + sec.width + 18; y: tm.y + 2
                width: hc.width - x - 16
                spacing: 2
                DText { width: parent.width; elide: Text.ElideRight; text: h.d.greeting(h.now) + ", " + (Quickshell.env("USER") || "you"); font.pixelSize: 14; font.weight: Font.DemiBold; color: h.p.text }
                DText { width: parent.width; elide: Text.ElideRight; text: Qt.formatDate(h.now, "dddd, d MMMM"); font.pixelSize: 12; color: h.p.sub }
                DText { visible: hc.big; width: parent.width; elide: Text.ElideRight; topPadding: 6; text: "up " + h.d.uptimeText(h.d.stats.uptime || h.d.about.uptime || 0); font.pixelSize: 12; color: h.p.sub }
            }
            // the day, 00 to 24: the line fills while it passes
            Item {
                x: 20; y: hc.lineY
                width: hc.width - 40; height: 16
                Rectangle { y: 2; width: parent.width; height: 4; radius: 2; color: h.p.track }
                Rectangle { y: 2; width: parent.width * hc.frac; height: 4; radius: 2; color: h.p.primary }
                Rectangle { x: parent.width * hc.frac - 5; y: -1; width: 10; height: 10; radius: 5; color: h.p.primary; border.width: 2; border.color: h.p.solidBg }
                Repeater {
                    model: ["0", "6", "12", "18", "24"]
                    DText { x: index * (parent.width - width) / 4; y: 8; text: modelData; font.pixelSize: 8; color: h.p.sub; opacity: 0.8 }
                }
            }
        }
    }
    // Round switches (Wi-Fi, Bluetooth, Do not disturb, Night light, ...), the same as in the Control tab
    Component {
        id: quickC
        DCard {
            id: qc
            p: h.p
            readonly property var defs: [
                { k: "wifi", have: "nmcli", on: "wifi", off: "wifi_off", go: 0xF05A9, gf: 0xF05AA },
                { k: "bluetooth", have: "bluetoothctl", on: "bluetooth", off: "bluetooth_disabled", go: 0xF00AF, gf: 0xF00B2 },
                { k: "dnd", have: "swaync-client", on: "notifications_off", off: "notifications", go: 0xF009B, gf: 0xF009A, inv: true },
                { k: "nightlight", have: "hyprsunset", on: "bedtime", off: "bedtime", go: 0xF0594, gf: 0xF0594 },
                { k: "sound", have: "wpctl", on: "volume_up", off: "volume_off", go: 0xF057E, gf: 0xF0581 },
                { k: "mic", have: "wpctl", on: "mic", off: "mic_off", go: 0xF036C, gf: 0xF036D },
                { k: "awake", have: "", on: "coffee", off: "coffee", go: 0xF0176, gf: 0xF0176 }
            ].filter(function(x) { return x.have === "" || !h.d.svc.have || h.d.svc.have[x.have] !== false })
            readonly property int cols: Math.max(1, Math.floor((width - 28 + 8) / 54))
            readonly property int rws: Math.max(1, Math.floor((height - 12 + 8) / 54))
            Grid {
                anchors.centerIn: parent
                columns: qc.cols
                spacing: 8
                Repeater {
                    model: qc.defs.slice(0, qc.cols * qc.rws)
                    Rectangle {
                        readonly property bool on: h.d.svc[modelData.k] === true
                        width: 46; height: 46; radius: 23
                        color: on ? (qm.containsMouse ? Qt.lighter(h.p.primary, 1.08) : h.p.primary) : (qm.containsMouse ? h.p.card2 : h.p.track)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        scale: qm.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        MIcon { anchors.centerIn: parent; name: parent.on ? modelData.on : modelData.off; glyph: h.d.md(parent.on ? modelData.go : modelData.gf); size: 22; color: parent.on ? h.p.inkOn : h.p.text }
                        MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: h.d.svcToggle(modelData.k) }
                    }
                }
            }
        }
    }
    // The week you are in, today lit
    Component {
        id: weekC
        DCard {
            id: wk
            p: h.p
            readonly property date monday: new Date(h.now.getFullYear(), h.now.getMonth(), h.now.getDate() - ((h.now.getDay() + 6) % 7) + 7 * h.weekOff)
            readonly property date mid: new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 3)
            readonly property bool head: height >= 90
            Item {
                id: wkHead
                visible: wk.head
                x: 16; y: 8
                width: parent.width - 32; height: 24
                DText { anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDate(wk.mid, "MMMM yyyy"); font.pixelSize: 13; font.weight: Font.DemiBold; color: h.p.primary }
                Row {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    DText { anchors.verticalCenter: parent.verticalCenter; rightPadding: 4; text: "W" + h.isoWeek(wk.mid); font.pixelSize: 11; color: h.p.sub }
                    IconBtn { size: 24; icon: "chevron_left"; glyph: h.d.md(0xF0141); onClicked: h.weekOff-- }
                    IconBtn { size: 24; icon: "chevron_right"; glyph: h.d.md(0xF0142); onClicked: h.weekOff++ }
                }
            }
            Row {
                x: 10; y: wk.head ? wkHead.y + wkHead.height + 4 : 10
                width: parent.width - 20; height: parent.height - y - 10
                spacing: 4
                Repeater {
                    model: 7
                    Rectangle {
                        readonly property date day: new Date(wk.monday.getFullYear(), wk.monday.getMonth(), wk.monday.getDate() + index)
                        readonly property bool today: day.toDateString() === h.now.toDateString()
                        width: (parent.width - 6 * 4) / 7; height: parent.height
                        radius: Math.min(16, width * 0.34)
                        color: today ? h.p.primary : "transparent"
                        border.width: today ? 0 : 1
                        border.color: h.p.track
                        Column {
                            anchors.centerIn: parent
                            spacing: 0
                            DText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(parent.parent.day, "ddd").toUpperCase().substring(0, 2); font.pixelSize: 9; font.weight: Font.Medium; color: parent.parent.today ? h.p.inkOn : h.p.sub }
                            DText { anchors.horizontalCenter: parent.horizontalCenter; text: parent.parent.day.getDate(); font.pixelSize: 15; font.weight: Font.DemiBold; color: parent.parent.today ? h.p.inkOn : h.p.text; opacity: parent.parent.day.getDay() === 0 || parent.parent.day.getDay() === 6 ? 0.6 : 1 }
                        }
                    }
                }
            }
        }
    }
    // Music as a record: the cover turns while a song plays
    Component {
        id: nowC
        DCard {
            id: nc
            p: h.p
            strong: true
            readonly property bool playing: !!h.player && h.player.isPlaying
            readonly property bool wide: width >= 300 && height >= 120
            readonly property real ds: wide ? Math.min(height - 28, width * 0.4, 170) : Math.max(40, Math.min(width - 60, height * 0.42, 120))
            property real angle: 0
            Timer { interval: 40; running: h.live && nc.playing; repeat: true; onTriggered: nc.angle = (nc.angle + 1.4) % 360 }
            Item {
                id: disc
                x: nc.wide ? 16 : (nc.width - width) / 2
                y: nc.wide ? (nc.height - height) / 2 : 14
                width: nc.ds; height: nc.ds
                rotation: nc.angle
                Rectangle { anchors.fill: parent; radius: width / 2; color: h.p.container }
                RoundImage { anchors.fill: parent; cornerRadius: width / 2; fallback: ""; source: h.player && h.player.trackArtUrl ? h.player.trackArtUrl : "" }
                Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 3; border.color: Qt.rgba(0, 0, 0, 0.28) }
                Rectangle { visible: !!(h.player && h.player.trackArtUrl); anchors.centerIn: parent; width: disc.width * 0.16; height: width; radius: width / 2; color: h.p.solidBg; border.width: 2; border.color: h.p.track }
            }
            MIcon { x: disc.x + (disc.width - width) / 2; y: disc.y + (disc.height - height) / 2; width: disc.width * 0.4; height: width; name: "music_note"; glyph: h.d.md(0xF075A); size: disc.width * 0.34; color: h.p.onContainer; visible: !(h.player && h.player.trackArtUrl) }
            Column {
                id: ncInfo
                x: nc.wide ? disc.x + disc.width + 18 : 16
                y: nc.wide ? 18 : disc.y + disc.height + 10
                width: nc.wide ? nc.width - x - 16 : nc.width - 32
                spacing: 2
                DText { width: parent.width; horizontalAlignment: nc.wide ? Text.AlignLeft : Text.AlignHCenter; elide: Text.ElideRight
                    text: h.player && h.player.trackTitle ? h.player.trackTitle : "Nothing playing"; font.pixelSize: 16; font.weight: Font.DemiBold; color: h.p.text }
                DText { width: parent.width; horizontalAlignment: nc.wide ? Text.AlignLeft : Text.AlignHCenter; elide: Text.ElideRight
                    text: h.player && h.player.trackArtist ? h.player.trackArtist : "Play something to see it here"; font.pixelSize: 12; color: h.p.sub }
            }
            Item {
                id: ncProg
                x: ncInfo.x; width: ncInfo.width; height: 14
                y: nc.height - 14 - 38 - 22
                visible: !!h.player && h.player.length > 0 && nc.height > 150
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: h.p.track }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * (h.player && h.player.length > 0 ? Math.min(1, h.pos / h.player.length) : 0); height: 4; radius: 2; color: h.p.primary
                    Behavior on width { NumberAnimation { duration: 900 } } }
                DText { anchors.left: parent.left; y: 12; text: h.mmss(h.pos); font.pixelSize: 9; color: h.p.sub }
                DText { anchors.right: parent.right; y: 12; text: h.player ? h.mmss(h.player.length) : ""; font.pixelSize: 9; color: h.p.sub }
            }
            Row {
                x: nc.wide ? ncInfo.x : (nc.width - width) / 2
                y: nc.height - height - 14
                spacing: 10
                IconBtn { size: 38; icon: "skip_previous"; glyph: h.d.md(0xF04AE); enabled: !!h.player; onClicked: h.player.previous() }
                Rectangle {
                    width: 60; height: 38; radius: 19
                    color: npm.containsMouse ? Qt.lighter(h.p.primary, 1.08) : h.p.primary
                    scale: npm.pressed ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    MIcon { anchors.centerIn: parent; name: nc.playing ? "pause" : "play_arrow"; glyph: nc.playing ? h.d.md(0xF03E4) : h.d.md(0xF040A); size: 22; color: h.p.inkOn }
                    MouseArea { id: npm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (h.player) h.player.togglePlaying() }
                }
                IconBtn { size: 38; icon: "skip_next"; glyph: h.d.md(0xF04AD); enabled: !!h.player; onClicked: h.player.next() }
            }
        }
    }
    // CPU, memory, disk and graphics as bars
    Component {
        id: pulseC
        DCard {
            id: pc2
            p: h.p
            readonly property var rowsData: {
                const r = [{ t: "CPU", v: h.d.stats.cpu ? h.d.stats.cpu.usage : 0, x: h.d.stats.cpu && h.d.stats.cpu.temp ? h.d.stats.cpu.temp + "°" : "" },
                           { t: "RAM", v: h.d.stats.mem ? h.d.stats.mem.pct : 0, x: "" },
                           { t: "DISK", v: h.d.disk ? h.d.disk.pct : 0, x: "" }]
                if (h.d.stats.gpu && h.d.stats.gpu.name) r.splice(1, 0, { t: "GPU", v: h.d.stats.gpu.usage || 0, x: h.d.stats.gpu.temp ? h.d.stats.gpu.temp + "°" : "" })
                return r
            }
            readonly property var bat: h.d.stats.battery && h.d.stats.battery.main ? h.d.stats.battery.main : null
            readonly property int shown: Math.max(1, Math.min(rowsData.length, Math.floor((height - 56) / 38)))
            Item {
                id: pHead
                x: 16; y: 12
                width: parent.width - 32; height: 22
                DText { anchors.verticalCenter: parent.verticalCenter; text: "Pulse"; font.pixelSize: 14; font.weight: Font.DemiBold; color: h.p.text }
                Rectangle {
                    visible: !!pc2.bat
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: bt.implicitWidth + 16; height: 22; radius: 11; color: h.p.container
                    DText { id: bt; anchors.centerIn: parent; text: pc2.bat ? (pc2.bat.status === "Charging" ? "⚡ " : "") + pc2.bat.pct + "%" : ""; font.pixelSize: 11; font.weight: Font.Medium; color: h.p.onContainer }
                }
            }
            Column {
                x: 16; y: pHead.y + pHead.height + 10
                width: parent.width - 32
                spacing: pc2.shown > 1 ? Math.max(8, Math.min(26, (pc2.height - y - 14 - pc2.shown * 26) / (pc2.shown - 1))) : 0
                Repeater {
                    model: pc2.rowsData.slice(0, pc2.shown)
                    Item {
                        width: parent.width; height: 26
                        DText { text: modelData.t; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1; color: h.p.sub }
                        DText { anchors.right: parent.right; text: (modelData.x !== "" ? modelData.x + "  " : "") + Math.round(modelData.v) + "%"; font.pixelSize: 12; font.weight: Font.DemiBold; color: h.p.text }
                        Rectangle { y: 18; width: parent.width; height: 6; radius: 3; color: h.p.track }
                        Rectangle { y: 18; width: parent.width * Math.max(0, Math.min(100, h.live ? modelData.v : 0)) / 100; height: 6; radius: 3; color: modelData.v > 88 ? "#ff8a80" : h.p.primary
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } } }
                    }
                }
            }
        }
    }
    // The first tasks of your to-do list: click one to tick it
    Component {
        id: tasksC
        DCard {
            id: tk
            p: h.p
            readonly property var items: h.d.todos
            readonly property int remain: items.filter(function(x) { return !x.done }).length
            readonly property int shown: Math.max(1, Math.floor((height - 50) / 28))
            Item {
                id: tHead
                x: 16; y: 12
                width: parent.width - 32; height: 22
                DText { anchors.verticalCenter: parent.verticalCenter; text: "To-do"; font.pixelSize: 14; font.weight: Font.DemiBold; color: h.p.text }
                DText { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: tk.items.length > 0 ? tk.remain + " left" : ""; font.pixelSize: 11; color: h.p.sub }
            }
            Column {
                x: 16; y: tHead.y + tHead.height + 6
                width: parent.width - 32
                spacing: 2
                Repeater {
                    model: tk.items.map(function(x, i) { return { t: x.t, done: x.done, i: i } }).slice(0, tk.shown)
                    Item {
                        width: parent.width; height: 26
                        Rectangle {
                            id: cb
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18; height: 18; radius: 9
                            color: modelData.done ? h.p.primary : "transparent"
                            border.width: modelData.done ? 0 : 2; border.color: h.p.sub
                            MIcon { anchors.centerIn: parent; visible: modelData.done; name: "check"; glyph: h.d.md(0xF012C); size: 12; color: h.p.inkOn }
                        }
                        DText { x: 28; width: parent.width - 28; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: modelData.t; font.pixelSize: 13
                            color: modelData.done ? h.p.sub : h.p.text; font.strikeout: modelData.done }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: h.d.todoToggle(modelData.i) }
                    }
                }
            }
            DText {
                visible: tk.items.length === 0
                anchors.centerIn: parent; anchors.verticalCenterOffset: 10
                text: "Nothing to do"; font.pixelSize: 12; color: h.p.sub
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
