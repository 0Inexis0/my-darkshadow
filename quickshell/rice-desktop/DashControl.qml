import Quickshell
import Quickshell.Io
import QtQuick

// Control tab: switches, volume, brightness, power mode, capture and session buttons.
Item {
    id: c
    property var d
    property bool live: false
    readonly property var p: d.p

    // ---------- volume ----------
    property real vol: 0
    property bool muted: false
    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: {
            const m = text.match(/Volume:\s*([0-9.]+)/)
            if (m) { c.vol = Math.min(1, parseFloat(m[1])); c.muted = text.indexOf("MUTED") >= 0 }
        } }
    }
    Timer { id: volSend; interval: 70; property real val: 0
        onTriggered: Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)]) }
    function setVol(v) { vol = v; if (muted) { muted = false; Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]) } volSend.val = v; volSend.restart() }
    function toggleMute() { muted = !muted; Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) }

    // ---------- brightness ----------
    property real bl: -1
    Process {
        id: blProc
        command: ["bash", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: {
            const q = text.trim().split(",")
            if (q.length >= 4) c.bl = parseInt(q[3]) / 100
            else c.bl = -1
        } }
    }
    Timer { id: blSend; interval: 70; property real val: 0
        onTriggered: Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.max(1, Math.round(val * 100)) + "%"]) }
    function setBl(v) { bl = v; blSend.val = v; blSend.restart() }

    // ---------- power mode ----------
    property var modes: []
    property string mode: ""
    Process {
        id: modeProc
        command: ["bash", "-c", "command -v powerprofilesctl >/dev/null || exit 0; powerprofilesctl list 2>/dev/null | grep -oE '^[* ] *(power-saver|balanced|performance):' | tr -d '*: '; echo CUR; powerprofilesctl get 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: {
            const parts = text.split("CUR")
            c.modes = parts[0].split("\n").map(function(x) { return x.trim() }).filter(function(x) { return x !== "" })
            c.mode = parts.length > 1 ? parts[1].trim() : ""
        } }
    }
    function setMode(m) { mode = m; Quickshell.execDetached(["powerprofilesctl", "set", m]) }

    function poll() { volProc.running = true; blProc.running = true; modeProc.running = true; d.svcRefresh() }
    Timer { interval: 3000; running: c.live; repeat: true; triggeredOnStart: true; onTriggered: if (!volSend.running && !blSend.running) c.poll() }

    function sh(cmd, arg) {
        d.close()
        Quickshell.execDetached(["bash", "-c", "sleep 0.45; \"$HOME/.local/bin/rice-hotcorner\" \"$1\" \"$2\"", "_", cmd, arg])
    }
    function session(w) {
        d.close()
        Quickshell.execDetached(["bash", "-c", "sleep 0.3; \"$HOME/.local/bin/rice-services\" session \"$1\"", "_", w])
    }

    DashGrid {
        anchors.fill: parent
        d: c.d
        tabId: "control"
        layoutKey: c.d.side ? "control-side" : ""
        cols: c.d.side ? 6 : 12
        rows: c.d.side ? 6 : 3
        live: c.live
        catalog: [
            { id: "switches", name: "Switches", sizes: [[5, 2], [4, 2], [6, 2], [4, 1], [6, 1]] },
            { id: "volume", name: "Volume", sizes: [[4, 1], [3, 1], [5, 1], [6, 1]] },
            { id: "bright", name: "Brightness", sizes: [[3, 1], [4, 1], [5, 1], [6, 1]] },
            { id: "modes", name: "Power mode", sizes: [[7, 1], [5, 1], [6, 1], [4, 1], [4, 2]] },
            { id: "capture", name: "Capture", sizes: [[5, 1], [4, 1], [6, 1], [4, 2]] },
            { id: "session", name: "Session", sizes: [[7, 1], [6, 1], [5, 1], [4, 2]] }
        ]
        defaults: c.d.side ? [
            { id: "switches", x: 0, y: 0, w: 6, h: 2 }, { id: "volume", x: 0, y: 2, w: 6, h: 1 }, { id: "bright", x: 0, y: 3, w: 6, h: 1 },
            { id: "modes", x: 0, y: 4, w: 6, h: 1 }, { id: "session", x: 0, y: 5, w: 6, h: 1 }
        ] : [
            { id: "switches", x: 0, y: 0, w: 5, h: 2 }, { id: "volume", x: 5, y: 0, w: 4, h: 1 }, { id: "bright", x: 9, y: 0, w: 3, h: 1 },
            { id: "modes", x: 5, y: 1, w: 7, h: 1 }, { id: "capture", x: 0, y: 2, w: 5, h: 1 }, { id: "session", x: 5, y: 2, w: 7, h: 1 }
        ]
        comps: ({ switches: switchesC, volume: volumeC, bright: brightC, modes: modesC, capture: captureC, session: sessionC })
    }

    // ================= cards =================
    Component {
        id: switchesC
        DCard {
            id: sw
            p: c.p
            readonly property var defs: [
                { k: "wifi", n: "Wi-Fi", have: "nmcli", on: "wifi", off: "wifi_off", go: 0xF05A9, gf: 0xF05AA },
                { k: "bluetooth", n: "Bluetooth", have: "bluetoothctl", on: "bluetooth", off: "bluetooth_disabled", go: 0xF00AF, gf: 0xF00B2 },
                { k: "dnd", n: "Do not disturb", have: "swaync-client", on: "notifications_off", off: "notifications", go: 0xF009B, gf: 0xF009A },
                { k: "nightlight", n: "Night light", have: "hyprsunset", on: "bedtime", off: "bedtime", go: 0xF0594, gf: 0xF0594 },
                { k: "sound", n: "Sound", have: "wpctl", on: "volume_up", off: "volume_off", go: 0xF057E, gf: 0xF0581 },
                { k: "mic", n: "Microphone", have: "wpctl", on: "mic", off: "mic_off", go: 0xF036C, gf: 0xF036D },
                { k: "awake", n: "Stay awake", have: "", on: "coffee", off: "coffee", go: 0xF0176, gf: 0xF0176 },
                { k: "airplane", n: "Airplane", have: "nmcli", on: "flight", off: "flight", go: 0xF001D, gf: 0xF001D }
            ].filter(function(x) { return x.have === "" || !c.d.svc.have || c.d.svc.have[x.have] !== false })
            readonly property int cols: width >= 400 ? 4 : (width >= 270 ? 3 : 2)
            readonly property int rws: Math.max(1, Math.min(Math.ceil(defs.length / cols), Math.floor((height - 20 + 8) / 64)))
            Grid {
                x: 10; y: 10
                width: parent.width - 20; height: parent.height - 20
                columns: sw.cols
                spacing: 8
                Repeater {
                    model: sw.defs.slice(0, sw.cols * sw.rws)
                    Rectangle {
                        readonly property bool on: c.d.svc[modelData.k] === true
                        width: (parent.width - (sw.cols - 1) * 8) / sw.cols
                        height: (parent.height - (sw.rws - 1) * 8) / sw.rws
                        radius: Math.min(20, c.p.cardRadius - 2)
                        color: on ? (tm.containsMouse ? Qt.lighter(c.p.primary, 1.06) : c.p.primary) : (tm.containsMouse ? c.p.card2 : c.p.track)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        scale: tm.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        MIcon { x: 12; y: 10; name: parent.on ? modelData.on : modelData.off; glyph: c.d.md(parent.on ? modelData.go : modelData.gf); size: 22; color: parent.on ? c.p.inkOn : c.p.text }
                        Column {
                            x: 12; y: parent.height - height - 9
                            width: parent.width - 20
                            spacing: 0
                            DText { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: modelData.n; font.pixelSize: 12; font.weight: Font.DemiBold; color: parent.parent.on ? c.p.inkOn : c.p.text }
                            DText { text: parent.parent.on ? "On" : "Off"; font.pixelSize: 10; color: parent.parent.on ? c.p.inkOn : c.p.sub; opacity: 0.8 }
                        }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.d.svcToggle(modelData.k) }
                    }
                }
            }
        }
    }
    Component {
        id: volumeC
        DCard {
            id: vc
            p: c.p
            DText { x: 16; y: 12; text: "Volume"; font.pixelSize: 12; font.weight: Font.Medium; color: c.p.sub }
            DText { anchors.right: parent.right; anchors.rightMargin: 16; y: 12; text: c.muted ? "muted" : Math.round(c.vol * 100) + "%"; font.pixelSize: 12; font.weight: Font.DemiBold; color: c.muted ? c.p.sub : c.p.text }
            Rectangle {
                id: mb
                x: 14; y: parent.height - height - 14
                width: 40; height: 40; radius: 20
                color: mm.containsMouse ? c.p.card2 : c.p.track
                MIcon { anchors.centerIn: parent; name: c.muted || c.vol <= 0 ? "volume_off" : "volume_up"; glyph: c.d.md(c.muted || c.vol <= 0 ? 0xF0581 : 0xF057E); size: 20; color: c.p.text }
                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.toggleMute() }
            }
            DSlide {
                p: c.p
                x: mb.x + mb.width + 14; width: parent.width - x - 18
                y: mb.y + (mb.height - height) / 2
                value: c.muted ? 0 : c.vol
                onMoved: function(v) { c.setVol(v) }
            }
        }
    }
    Component {
        id: brightC
        DCard {
            id: bc
            p: c.p
            DText { x: 16; y: 12; text: "Brightness"; font.pixelSize: 12; font.weight: Font.Medium; color: c.p.sub }
            DText { visible: c.bl >= 0; anchors.right: parent.right; anchors.rightMargin: 16; y: 12; text: Math.round(c.bl * 100) + "%"; font.pixelSize: 12; font.weight: Font.DemiBold; color: c.p.text }
            Rectangle {
                id: bb
                x: 14; y: parent.height - height - 14
                width: 40; height: 40; radius: 20
                color: c.p.track
                MIcon { anchors.centerIn: parent; name: "brightness_6"; glyph: c.d.md(0xF00DF); size: 20; color: c.p.text }
            }
            DSlide {
                visible: c.bl >= 0
                p: c.p
                x: bb.x + bb.width + 14; width: parent.width - x - 18
                y: bb.y + (bb.height - height) / 2
                value: Math.max(0, c.bl)
                onMoved: function(v) { c.setBl(v) }
            }
            DText { visible: c.bl < 0; x: bb.x + bb.width + 12; width: parent.width - x - 14; y: bb.y + (bb.height - implicitHeight) / 2; wrapMode: Text.WordWrap; text: "No backlight on this screen"; font.pixelSize: 11; color: c.p.sub }
        }
    }
    Component {
        id: modesC
        DCard {
            id: mc
            p: c.p
            readonly property var meta: ({ "performance": ["Performance", "speed", 0xF04C5], "balanced": ["Balanced", "balance", 0xF05D1], "power-saver": ["Power saver", "eco", 0xF032A] })
            DText { x: 16; y: 12; text: "Power mode"; font.pixelSize: 12; font.weight: Font.Medium; color: c.p.sub }
            Row {
                visible: c.modes.length > 0
                x: 12; y: 36
                width: parent.width - 24; height: parent.height - 36 - 12
                spacing: 8
                Repeater {
                    model: c.modes
                    Rectangle {
                        readonly property bool on: c.mode === modelData
                        width: (parent.width - (c.modes.length - 1) * 8) / c.modes.length; height: parent.height
                        radius: Math.min(18, c.p.cardRadius - 2)
                        color: on ? c.p.primary : (pm.containsMouse ? c.p.card2 : c.p.track)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            MIcon { anchors.verticalCenter: parent.verticalCenter; name: mc.meta[modelData][1]; glyph: c.d.md(mc.meta[modelData][2]); size: 20; color: parent.parent.on ? c.p.inkOn : c.p.text }
                            DText { anchors.verticalCenter: parent.verticalCenter; visible: parent.parent.width > 120; text: mc.meta[modelData][0]; font.pixelSize: 12; font.weight: Font.DemiBold; color: parent.parent.on ? c.p.inkOn : c.p.text }
                        }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.setMode(modelData) }
                    }
                }
            }
            DText { visible: c.modes.length === 0; x: 16; y: 40; width: parent.width - 32; wrapMode: Text.WordWrap; text: "Power modes need power-profiles-daemon"; font.pixelSize: 12; color: c.p.sub }
        }
    }
    Component {
        id: captureC
        DCard {
            id: cp
            p: c.p
            readonly property var btns: [
                { n: "Screenshot", sub: "Screenshot", i: "screenshot_monitor", g: 0xF0293, cmd: "shot", arg: "full" },
                { n: "Screenshot", sub: "Region shot", i: "crop_free", g: 0xF019E, cmd: "shot", arg: "region" },
                { n: "Record", sub: "Record screen", i: "videocam", g: 0xF0567, cmd: "record", arg: "full" },
                { n: "Record", sub: "Record region", i: "fiber_manual_record", g: 0xF044A, cmd: "record", arg: "region" }
            ]
            DText { x: 16; y: 12; text: "Capture"; font.pixelSize: 12; font.weight: Font.Medium; color: c.p.sub }
            Grid {
                x: 12; y: 36
                width: parent.width - 24; height: parent.height - 36 - 12
                columns: cp.height >= 170 ? 2 : 4
                spacing: 8
                Repeater {
                    model: cp.btns
                    Rectangle {
                        readonly property int cl: cp.height >= 170 ? 2 : 4
                        readonly property int rw: Math.ceil(4 / cl)
                        width: (parent.width - (cl - 1) * 8) / cl; height: (parent.height - (rw - 1) * 8) / rw
                        radius: Math.min(18, c.p.cardRadius - 2)
                        color: cm.containsMouse ? c.p.card2 : c.p.track
                        Behavior on color { ColorAnimation { duration: 140 } }
                        scale: cm.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            MIcon { anchors.horizontalCenter: parent.horizontalCenter; name: modelData.i; glyph: c.d.md(modelData.g); size: 20; color: modelData.cmd === "record" ? "#ff8a80" : c.p.text }
                            DText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.sub; font.pixelSize: 10; color: c.p.sub }
                        }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.sh(modelData.cmd, modelData.arg) }
                    }
                }
            }
        }
    }
    Component {
        id: sessionC
        DCard {
            id: se
            p: c.p
            readonly property var btns: [
                { n: "Lock", i: "lock", g: 0xF033E, w: "lock" },
                { n: "Sleep", i: "bedtime", g: 0xF04B2, w: "suspend" },
                { n: "Log out", i: "logout", g: 0xF0343, w: "logout" },
                { n: "Restart", i: "restart_alt", g: 0xF0709, w: "reboot", warn: true },
                { n: "Shut down", i: "power_settings_new", g: 0xF0425, w: "poweroff", warn: true }
            ]
            DText { x: 16; y: 12; text: "Session"; font.pixelSize: 12; font.weight: Font.Medium; color: c.p.sub }
            Row {
                x: 12; y: 36
                width: parent.width - 24; height: parent.height - 36 - 12
                spacing: 8
                Repeater {
                    model: se.btns
                    Rectangle {
                        width: (parent.width - 4 * 8) / 5; height: parent.height
                        radius: Math.min(18, c.p.cardRadius - 2)
                        color: sm.containsMouse ? (modelData.warn ? Qt.rgba(1, 0.35, 0.3, 0.28) : c.p.card2) : c.p.track
                        Behavior on color { ColorAnimation { duration: 140 } }
                        scale: sm.pressed ? 0.95 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            MIcon { anchors.horizontalCenter: parent.horizontalCenter; name: modelData.i; glyph: c.d.md(modelData.g); size: 20; color: modelData.warn && sm.containsMouse ? "#ff8a80" : c.p.text }
                            DText { anchors.horizontalCenter: parent.horizontalCenter; visible: parent.parent.width > 62; text: modelData.n; font.pixelSize: 10; color: c.p.sub }
                        }
                        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.session(modelData.w) }
                    }
                }
            }
        }
    }
}
