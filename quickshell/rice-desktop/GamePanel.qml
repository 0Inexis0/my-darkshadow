import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick

// The game bar (SUPER + G): slides in from the left over whatever you play. CPU and GPU in soft shapes with a
// wavy ring, RAM, ping and heat, screenshot / record / microphone, power mode, gaming mode, Do Not Disturb,
// volume and brightness. It reads anything only while it is open.
PanelWindow {
    id: gp
    property bool open: false
    property real t: 0
    Behavior on t { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
    onOpenChanged: { t = open ? 1 : 0; if (open) refresh() }

    // ---------- colors: dark tonal surfaces with the theme color ----------
    readonly property real hue: Look.accent.hslHue < 0 ? 0.55 : Look.accent.hslHue
    readonly property real sat: Math.max(0.35, Math.min(0.85, Look.accent.hslSaturation))
    readonly property color primary: Qt.hsla(hue, sat, 0.78, 1)
    readonly property color inkPrimary: Qt.hsla(hue, Math.min(sat, 0.5), 0.13, 1)
    readonly property color container: Qt.hsla(hue, sat * 0.35, 0.24, 1)
    readonly property color inkContainer: Qt.hsla(hue, sat * 0.6, 0.88, 1)
    readonly property color surface: Qt.hsla(hue, 0.08, 0.085, Look.flat ? 1 : 0.9)
    readonly property color card: Qt.hsla(hue, 0.1, 0.14, 1)
    readonly property color cardHi: Qt.hsla(hue, 0.12, 0.19, 1)
    readonly property color fg: "#ECEDEE"
    readonly property color dim: "#A9ADB2"
    readonly property color track: Qt.rgba(1, 1, 1, 0.1)

    // ---------- data ----------
    property var st: ({ cpu: 0, ram: 0, gpu: 0, temp: 0, gtemp: 0, ramu: 0, ramt: 0 })
    property int ping: -1
    property string profile: ""
    property bool havePP: false
    property var fx: ({ gaming: false, opts: {} })
    property bool recording: false
    property int bright: -1
    property var now: new Date()
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [gp.sink, gp.source] }
    readonly property var win: Hyprland.activeToplevel
    readonly property string game: win && win.title ? win.title : "Desktop"

    Process {
        command: [Quickshell.env("HOME") + "/.local/bin/rice-stats", "1"]
        running: gp.open
        stdout: SplitParser { onRead: function(l) { try { gp.st = JSON.parse(l) } catch (e) { } } }
    }
    Process {
        id: pingProc
        command: ["bash", "-c", "ping -c1 -W1 1.1.1.1 2>/dev/null | sed -n 's/.*time=\\([0-9.]*\\).*/\\1/p'"]
        stdout: StdioCollector { onStreamFinished: { const v = parseFloat(text); gp.ping = isNaN(v) ? -1 : Math.round(v) } }
    }
    Process {
        id: infoProc
        command: ["bash", "-c", [
            "command -v powerprofilesctl >/dev/null && echo \"pp $(powerprofilesctl get 2>/dev/null)\"",
            "echo \"fx $(\"$HOME/.local/bin/rice-effects\" state 2>/dev/null | tr -d '\\n')\"",
            "if pgrep -x wf-recorder >/dev/null || pgrep -f gpu-screen-recorder >/dev/null; then echo 'rec 1'; else echo 'rec 0'; fi",
            "command -v brightnessctl >/dev/null && echo \"br $(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %)\""
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                gp.havePP = false
                text.split("\n").forEach(function(l) {
                    const k = l.substring(0, l.indexOf(" ")), v = l.substring(l.indexOf(" ") + 1).trim()
                    if (k === "pp" && v) { gp.havePP = true; gp.profile = v }
                    else if (k === "fx") { try { gp.fx = JSON.parse(v) } catch (e) { } }
                    else if (k === "rec") gp.recording = v === "1"
                    else if (k === "br") { const n = parseInt(v); gp.bright = isNaN(n) ? -1 : n }
                })
            }
        }
    }
    function refresh() { if (!infoProc.running) infoProc.running = true; if (!pingProc.running) pingProc.running = true; now = new Date() }
    Timer { interval: 3000; running: gp.open; repeat: true; onTriggered: gp.refresh() }
    function sh(cmd) { Quickshell.execDetached(["bash", "-c", cmd]) }
    function bin(a) { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/" + a[0] + "\" \"${@}\"", "_"].concat(a.slice(1))) }
    function later() { again.restart() }
    Timer { id: again; interval: 900; onTriggered: gp.refresh() }

    Trigger {
        name: "gamebar-open"
        onFired: function(o) {
            const w = o.split(" ")[1] || "toggle"
            gp.open = w === "open" ? true : (w === "close" ? false : !gp.open)
        }
    }

    // ---------- the window ----------
    visible: open || t > 0.01
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-gamebar"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // a light dim over the game, click it to close
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.28 * Math.min(1, gp.t)) }
    MouseArea { anchors.fill: parent; onClicked: gp.open = false }
    Item { focus: gp.open; Keys.onEscapePressed: gp.open = false }

    // ---------- pieces ----------
    component Gauge: Item {
        id: g
        property string shape: "pentagon"
        property string name: "CPU"
        property real v: 0
        property int heat: 0
        width: 168; height: 168
        Blob { anchors.fill: parent; kind: g.shape; color: gp.card
            RotationAnimator on rotation { from: 0; to: 360; duration: 90000; loops: Animation.Infinite; running: gp.open && !Look.lite } }
        Canvas {
            id: rc
            anchors.centerIn: parent; width: 122; height: 122
            property real vv: g.v
            property real ph: 0
            Behavior on vv { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            NumberAnimation on ph { from: 0; to: Math.PI * 2; duration: 2000; loops: Animation.Infinite; running: gp.open && !Look.lite }
            onVvChanged: requestPaint(); onPhChanged: requestPaint()
            renderStrategy: Canvas.Cooperative
            onPaint: {
                const c = getContext("2d"); c.reset()
                const cx = 61, cy = 61, r = 52, len = Math.PI * 2 * Math.max(0.005, Math.min(1, vv / 100)), s = -Math.PI / 2
                c.lineCap = "round"; c.lineWidth = 6
                c.strokeStyle = gp.track
                if (vv < 99) { c.beginPath(); c.arc(cx, cy, r, s + len + 0.3, s + Math.PI * 2 - 0.3); c.stroke() }
                c.strokeStyle = gp.primary; c.beginPath()
                const n = Math.max(10, Math.round(len * 18)), amp = 2.4 * Math.sin(Math.PI * Math.min(1, vv / 100))
                for (let i = 0; i <= n; i++) { const a = s + len * i / n, rr = r + amp * Math.sin(a * 10 - ph); const x = cx + rr * Math.cos(a), y = cy + rr * Math.sin(a); if (i === 0) c.moveTo(x, y); else c.lineTo(x, y) }
                c.stroke()
            }
        }
        Column {
            anchors.centerIn: parent
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: g.name; color: gp.dim; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; font.letterSpacing: 1 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(g.v) + "%"; color: gp.fg; font.family: Fonts.numbers; font.pixelSize: 30; font.weight: Font.DemiBold }
            Text { anchors.horizontalCenter: parent.horizontalCenter; visible: g.heat > 0; text: g.heat + "°C"; color: g.heat >= 85 ? "#FFB4AB" : gp.dim; font.family: Fonts.main; font.pixelSize: 12 }
        }
    }
    component Stat: Rectangle {
        property string icon: ""
        property string glyph: ""
        property string value: ""
        property string label: ""
        width: (body.width - 16) / 3; height: 70; radius: 20; color: gp.card
        MIcon { x: 14; y: 13; size: 18; color: gp.primary; name: parent.icon; glyph: parent.glyph }
        Text { x: 14; y: 36; text: parent.value; color: gp.fg; font.family: Fonts.numbers; font.pixelSize: 16; font.weight: Font.DemiBold }
        Text { anchors.right: parent.right; anchors.rightMargin: 14; y: 14; text: parent.label; color: gp.dim; font.family: Fonts.main; font.pixelSize: 11 }
    }
    component RoundBtn: Item {
        id: rb
        property string icon: ""
        property string glyph: ""
        property string label: ""
        property bool on: false
        property color onColor: gp.primary
        signal clicked()
        width: (body.width - 30) / 4; height: 84
        Rectangle {
            id: disc
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56; height: 56
            radius: rbm.pressed ? 16 : (rb.on ? 18 : 28)
            color: rb.on ? rb.onColor : (rbm.containsMouse ? gp.cardHi : gp.card)
            scale: rbm.pressed ? 0.92 : 1
            Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2 } }
            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 120 } }
            MIcon { anchors.centerIn: parent; size: 22; name: rb.icon; glyph: rb.glyph; color: rb.on ? gp.inkPrimary : gp.fg }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; text: rb.label; color: gp.dim; font.family: Fonts.main; font.pixelSize: 11 }
        MouseArea { id: rbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rb.clicked() }
    }
    component Line: Item {
        id: ln
        property string icon: ""
        property string glyph: ""
        property real v: 0
        signal moved(real v)
        width: body.width; height: 52
        Rectangle {
            anchors.fill: parent; radius: 26; color: gp.card
            clip: true
            Rectangle { width: Math.max(52, parent.width * ln.v); height: parent.height; radius: 26; color: gp.container
                Behavior on width { enabled: !lm.pressed; NumberAnimation { duration: 160 } } }
            MIcon { x: 16; anchors.verticalCenter: parent.verticalCenter; size: 20; name: ln.icon; glyph: ln.glyph; color: gp.inkContainer }
            Text { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
                text: Math.round(ln.v * 100) + "%"; color: gp.fg; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium }
        }
        MouseArea {
            id: lm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            function at(x) { return Math.max(0, Math.min(1, x / width)) }
            onPressed: function(m) { ln.moved(at(m.x)) }
            onPositionChanged: function(m) { if (pressed) ln.moved(at(m.x)) }
            onWheel: function(e) { ln.moved(Math.max(0, Math.min(1, ln.v + (e.angleDelta.y > 0 ? 0.05 : -0.05)))) }
        }
    }

    // ---------- the panel ----------
    Rectangle {
        id: panel
        width: 404
        x: 14 - (width + 30) * (1 - gp.t)
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 14
        radius: 32
        color: gp.surface
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.06)
        opacity: Math.min(1, gp.t * 1.4)
        clip: true
        MouseArea { anchors.fill: parent }       // clicks on the panel do not close it

        Flickable {
            anchors.fill: parent
            anchors.margins: 18
            contentHeight: body.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            Column {
                id: body
                width: parent.width
                spacing: 14

                // what you play
                Item {
                    width: parent.width; height: 52
                    Rectangle {
                        id: appIc; width: 52; height: 52; radius: 18; color: gp.container
                        IconImage { anchors.centerIn: parent; implicitSize: 30
                            source: gp.win && gp.win.lastIpcObject && gp.win.lastIpcObject.class ? Quickshell.iconPath(String(gp.win.lastIpcObject.class).toLowerCase(), "applications-games") : Quickshell.iconPath("applications-games", true) }
                    }
                    Column {
                        x: 64; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 64 - 44
                        Text { text: "GAME BAR"; color: gp.primary; font.family: Fonts.main; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.4 }
                        Text { width: parent.width; elide: Text.ElideRight; text: gp.game; color: gp.fg; font.family: Fonts.title; font.pixelSize: 18; font.weight: Font.Medium }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 38; height: 38; radius: 19; color: xm.containsMouse ? gp.cardHi : "transparent"
                        MIcon { anchors.centerIn: parent; size: 20; name: "close"; glyph: "\uf00d"; color: gp.fg }
                        MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gp.open = false }
                    }
                }

                // the two gauges
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16
                    Gauge { shape: "pentagon"; name: "CPU"; v: gp.st.cpu; heat: gp.st.temp }
                    Gauge { shape: "cookie"; name: "GPU"; v: gp.st.gpu; heat: gp.st.gtemp }
                }
                Row {
                    spacing: 8
                    Stat { icon: "memory"; glyph: "\udb80\udf5b"; value: gp.st.ramu + " GB"; label: gp.st.ram + "%" }
                    Stat { icon: "network_ping"; glyph: "\udb80\udd25"; value: gp.ping >= 0 ? gp.ping + " ms" : "–"; label: "Ping" }
                    Stat { icon: "schedule"; glyph: "\uf017"; value: gp.now.toLocaleTimeString(Qt.locale(), "HH:mm"); label: "Time" }
                }

                // capture
                Text { text: "Capture"; color: gp.dim; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; topPadding: 4 }
                Row {
                    spacing: 10
                    RoundBtn { icon: "screenshot_region"; glyph: "\udb80\udd00"; label: "Area"
                        onClicked: { gp.open = false; shotT.cmd = "region"; shotT.restart() } }
                    RoundBtn { icon: "screenshot_monitor"; glyph: "\udb80\udd01"; label: "Screen"
                        onClicked: { gp.open = false; shotT.cmd = "full"; shotT.restart() } }
                    RoundBtn { icon: gp.recording ? "stop" : "radio_button_checked"; glyph: gp.recording ? "\uf04d" : "\uf111"; label: gp.recording ? "Stop" : "Record"
                        on: gp.recording; onColor: "#FFB4AB"
                        onClicked: { gp.bin(["rice-hotcorner", "record", gp.recording ? "stop" : "full"]); gp.recording = !gp.recording; gp.later() } }
                    RoundBtn { readonly property bool muted: gp.source && gp.source.audio ? gp.source.audio.muted : false
                        icon: muted ? "mic_off" : "mic"; glyph: muted ? "\udb80\udf6d" : "\udb80\udf6c"; label: muted ? "Mic off" : "Mic"; on: !muted
                        onClicked: if (gp.source && gp.source.audio) gp.source.audio.muted = !gp.source.audio.muted }
                }
                Timer { id: shotT; property string cmd: "region"; interval: 450; onTriggered: gp.bin(["rice-hotcorner", "shot", cmd]) }

                // performance
                Text { text: "Performance"; color: gp.dim; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; topPadding: 4 }
                Row {
                    visible: gp.havePP
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: [{ k: "power-saver", n: "Saver", i: "eco", g: "\udb80\udf2a" }, { k: "balanced", n: "Balanced", i: "balance", g: "\uf24e" }, { k: "performance", n: "Speed", i: "speed", g: "\udb81\udcc5" }]
                        delegate: Rectangle {
                            readonly property bool on: gp.profile === modelData.k
                            width: (body.width - 8) / 3; height: 48
                            radius: on ? 24 : 12
                            color: on ? gp.primary : (pm.containsMouse ? gp.cardHi : gp.card)
                            Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                            Row {
                                anchors.centerIn: parent; spacing: 6
                                MIcon { size: 17; name: modelData.i; glyph: modelData.g; color: parent.parent.on ? gp.inkPrimary : gp.fg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.n; color: parent.parent.on ? gp.inkPrimary : gp.fg; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { gp.profile = modelData.k; gp.bin(["rice-services", "profile", modelData.k]); gp.later() } }
                        }
                    }
                }
                Row {
                    spacing: 8
                    Repeater {
                        model: [
                            { k: "gaming", n: "Gaming mode", d: "Effects off", i: "sports_esports", g: "\uf11b" },
                            { k: "dnd", n: "Do Not Disturb", d: "No popups", i: "do_not_disturb_on", g: "\udb80\udc9b" }
                        ]
                        delegate: Rectangle {
                            readonly property bool on: modelData.k === "gaming" ? gp.fx.gaming === true : !!(gp.fx.opts && gp.fx.opts.dnd === true)
                            width: (body.width - 8) / 2; height: 64; radius: 22
                            color: on ? gp.container : (tm.containsMouse ? gp.cardHi : gp.card)
                            Behavior on color { ColorAnimation { duration: 160 } }
                            MIcon { x: 16; anchors.verticalCenter: parent.verticalCenter; size: 22; name: modelData.i; glyph: modelData.g; color: parent.on ? gp.primary : gp.fg; filled: parent.on }
                            Column {
                                x: 50; anchors.verticalCenter: parent.verticalCenter
                                Text { text: modelData.n; color: gp.fg; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium }
                                Text { text: parent.parent.on ? "On" : modelData.d; color: parent.parent.on ? gp.inkContainer : gp.dim; font.family: Fonts.main; font.pixelSize: 11 }
                            }
                            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const n = JSON.parse(JSON.stringify(gp.fx))
                                    if (modelData.k === "gaming") { n.gaming = !parent.on; gp.bin(["rice-effects", "gaming", n.gaming ? "on" : "off"]) }
                                    else { n.opts = n.opts || {}; n.opts.dnd = !parent.on; gp.sh("command -v swaync-client >/dev/null && swaync-client -d -sw >/dev/null"); gp.bin(["rice-effects", "set", "dnd", n.opts.dnd ? "on" : "off"]) }
                                    gp.fx = n; gp.later()
                                } }
                        }
                    }
                }

                // sound and screen
                Text { text: "Sound & screen"; color: gp.dim; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; topPadding: 4 }
                Line {
                    icon: gp.sink && gp.sink.audio && gp.sink.audio.muted ? "volume_off" : "volume_up"; glyph: "\udb81\udd7e"
                    v: gp.sink && gp.sink.audio ? gp.sink.audio.volume : 0
                    onMoved: function(x) { if (gp.sink && gp.sink.audio) { gp.sink.audio.muted = false; gp.sink.audio.volume = x } }
                }
                Line {
                    visible: gp.bright >= 0
                    icon: "brightness_6"; glyph: "\udb80\udcdf"
                    v: gp.bright / 100
                    onMoved: function(x) { const p = Math.max(1, Math.round(x * 100)); gp.bright = p; gp.sh("brightnessctl -q set " + p + "%") }
                }
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; topPadding: 6; text: "SUPER + G or Esc to close"; color: Qt.rgba(1, 1, 1, 0.35); font.family: Fonts.main; font.pixelSize: 11 }
            }
        }
    }
}
