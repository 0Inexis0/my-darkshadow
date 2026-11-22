import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

// One module of the dock (V4.92; Edit mode > Dock > Modules), like the icons on a phone's status bar:
//   clock, battery, volume, network, bluetooth, weather, sysmon (CPU and memory), search (opens the launcher),
//   notifications (the control center; right click: do not disturb), power (the session menu), control (the control
//   center). The song that plays ("music") is the dock's own media pill (Dock.qml).
// Each sits on a small tonal pill as tall as the dock's apps; on a dock at the side it stands upright and narrow.
Item {
    id: dm
    property string kind: ""
    property var host: null              // the dock (not "dock": "dock: dock" would point at itself)
    property var np: null                // NPal
    readonly property bool vert: host ? host.vert : false
    readonly property real tile: host ? host.tile : 40
    // a module with nothing to show (no battery) takes no room
    readonly property bool shown: kind !== "battery" || hasBatt
    visible: shown
    width: !shown ? 0 : (vert ? tile : Math.max(tile, body.implicitWidth + 24))
    height: !shown ? 0 : (vert ? Math.max(tile, body.implicitHeight + 18) : tile)

    function run(c) { Quickshell.execDetached(["bash", "-c", c]) }
    // where the module is on the screen (the Wi-Fi, Bluetooth and session menus open there)
    function sx() { const p = mapToItem(null, width / 2, 0); return Math.round(p.x) }
    // V4.95: the menus open above a dock at the bottom (they opened up by the bar before)
    function at() { return host && host.edge === "bottom" ? " dock:" + Math.round(host.thick + 22) : "" }

    // ---------- what the modules show ----------
    readonly property var batt: UPower.displayDevice
    readonly property bool hasBatt: !!batt && batt.isPresent && batt.isLaptopBattery
    readonly property int battPct: batt ? Math.round(batt.percentage * 100) : 0
    readonly property bool charging: !!batt && (batt.state === UPowerDeviceState.Charging || batt.state === UPowerDeviceState.FullyCharged)
    readonly property var sink: kind === "volume" ? Pipewire.defaultAudioSink : null
    PwObjectTracker { objects: dm.kind === "volume" ? [dm.sink] : [] }
    readonly property real vol: Vol.of(sink)
    readonly property bool muted: !!sink && !!sink.audio && sink.audio.muted
    readonly property var svc: BarSvc.state
    property var now: new Date()
    Timer { interval: 15000; running: dm.kind === "clock" && dm.visible; repeat: true; triggeredOnStart: true; onTriggered: dm.now = new Date() }
    function two(n) { return n < 10 ? "0" + n : "" + n }
    // the weather: asked when the module comes, then every half hour
    Timer { interval: 1800000; running: dm.kind === "weather"; repeat: true; triggeredOnStart: true; onTriggered: BarSvc.refreshWx() }
    // CPU and memory from /proc, every 2 s
    property real cpu: 0
    property real ram: 0
    property var prev: null
    FileView { id: statF; path: dm.kind === "sysmon" ? "/proc/stat" : ""; printErrors: false }
    FileView { id: memF; path: dm.kind === "sysmon" ? "/proc/meminfo" : ""; printErrors: false }
    Timer {
        interval: 2000; running: dm.kind === "sysmon" && dm.visible; repeat: true; triggeredOnStart: true
        onTriggered: {
            statF.reload(); memF.reload()
            const l = (statF.text() || "").split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            if (l.length >= 4) {
                const idle = l[3] + (l[4] || 0), tot = l.reduce(function(a, b) { return a + b }, 0)
                if (dm.prev) { const dt = tot - dm.prev[1]; if (dt > 0) dm.cpu = Math.max(0, Math.min(1, 1 - (idle - dm.prev[0]) / dt)) }
                dm.prev = [idle, tot]
            }
            const m = memF.text() || ""
            const t = /MemTotal:\s+(\d+)/.exec(m), a = /MemAvailable:\s+(\d+)/.exec(m)
            if (t && a) dm.ram = 1 - Number(a[1]) / Number(t[1])
        }
    }

    // ---------- the pill ----------
    Rectangle {
        anchors.fill: parent
        radius: Look.sq ? 0 : (Math.min(width, height) / 2 > 22 ? 22 : Math.min(width, height) / 2)
        color: ma.containsMouse ? dm.np.cardHi : dm.np.card
        Behavior on color { ColorAnimation { duration: 140 } }
        scale: ma.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    }

    Loader {
        id: body
        anchors.centerIn: parent
        sourceComponent: ({ clock: cClock, battery: cBatt, volume: cVol, network: cIcon, bluetooth: cIcon, weather: cWx,
                            sysmon: cSys, search: cSearch, notifications: cIcon, power: cIcon, control: cIcon })[dm.kind] || null
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(m) {
            const right = m.button === Qt.RightButton
            try { Sfx.play("click") } catch (e) { }
            switch (dm.kind) {
            case "clock": dm.run("\"$HOME/.local/bin/rice-cc\" toggle"); break
            case "volume":
                if (right) { if (dm.sink && dm.sink.audio) dm.sink.audio.muted = !dm.sink.audio.muted }
                else dm.run("\"$HOME/.local/bin/rice-volume\" menu " + dm.sx() + dm.at())
                break
            case "network": dm.run("\"$HOME/.local/bin/rice-wifi\" " + dm.sx() + dm.at()); break
            case "bluetooth": dm.run("\"$HOME/.local/bin/rice-bluetooth\" " + dm.sx() + dm.at()); break
            case "weather": BarSvc.refreshWx(); break
            case "sysmon": dm.run("\"$HOME/.local/bin/rice-perf\" >/dev/null 2>&1 || missioncenter || gnome-system-monitor"); break
            case "search": dm.run("\"$HOME/.local/bin/rice-launch\""); break
            case "notifications": dm.run(right ? "\"$HOME/.local/bin/rice-cc\" dnd toggle" : "\"$HOME/.local/bin/rice-cc\" toggle"); BarSvc.refreshSoon(); break
            case "power": dm.run("\"$HOME/.local/bin/rice-power\" " + dm.sx() + dm.at()); break
            case "control": dm.run("\"$HOME/.local/bin/rice-cc\" toggle"); break
            }
        }
        onWheel: function(w) { if (dm.kind === "volume") Vol.nudge(dm.sink, w.angleDelta.y > 0 ? 0.05 : -0.05) }
    }

    // ---------- the faces ----------
    Component { id: cClock
        Column {
            spacing: 0
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: dm.vert ? dm.two(dm.now.getHours()) + "\n" + dm.two(dm.now.getMinutes()) : dm.two(dm.now.getHours()) + ":" + dm.two(dm.now.getMinutes())
                horizontalAlignment: Text.AlignHCenter; lineHeight: 0.9
                color: dm.np.fg; font.family: Fonts.main; font.pixelSize: dm.vert ? 15 : Math.round(dm.tile * 0.4); font.weight: Font.DemiBold }
            Text { visible: !dm.vert && dm.tile >= 34; anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(dm.now, "ddd d MMM"); color: dm.np.dim; font.family: Fonts.main; font.pixelSize: 10 }
        }
    }
    Component { id: cBatt
        Grid {
            columns: dm.vert ? 1 : 2; spacing: 4
            horizontalItemAlignment: Grid.AlignHCenter; verticalItemAlignment: Grid.AlignVCenter
            MIcon { size: 18; name: dm.charging ? "battery_charging_full" : "battery_full"; glyph: String.fromCodePoint(dm.charging ? 0xF0084 : 0xF0079)
                color: !dm.charging && dm.battPct <= 15 ? "#ff8a80" : dm.np.primary }
            Text { text: dm.battPct + (dm.vert ? "" : "%"); color: dm.np.fg; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium }
        }
    }
    Component { id: cVol
        Grid {
            columns: dm.vert ? 1 : 2; spacing: 4
            horizontalItemAlignment: Grid.AlignHCenter; verticalItemAlignment: Grid.AlignVCenter
            MIcon { size: 18; color: dm.muted ? dm.np.dim : dm.np.primary
                name: dm.muted ? "volume_off" : (dm.vol < 0.34 ? "volume_mute" : (dm.vol < 0.67 ? "volume_down" : "volume_up"))
                glyph: String.fromCodePoint(dm.muted ? 0xF0581 : (dm.vol < 0.34 ? 0xF057F : (dm.vol < 0.67 ? 0xF0580 : 0xF057E))) }
            Text { text: Math.round(dm.vol * 100) + (dm.vert ? "" : "%"); color: dm.muted ? dm.np.dim : dm.np.fg; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium }
        }
    }
    Component { id: cIcon
        MIcon {
            size: 19
            readonly property bool on: dm.kind === "network" ? dm.svc.network === true : (dm.kind === "bluetooth" ? dm.svc.bluetooth === true
                                       : (dm.kind === "notifications" ? dm.svc.dnd !== true : true))
            color: on ? (dm.kind === "power" ? dm.np.fg : dm.np.primary) : dm.np.dim
            name: ({ network: on ? "wifi" : "wifi_off", bluetooth: on ? "bluetooth" : "bluetooth_disabled",
                     notifications: on ? "notifications" : "notifications_off", power: "power_settings_new", control: "tune" })[dm.kind] || ""
            glyph: String.fromCodePoint(({ network: on ? 0xF05A9 : 0xF05AA, bluetooth: on ? 0xF00AF : 0xF00B2,
                     notifications: on ? 0xF009A : 0xF009B, power: 0xF0425, control: 0xF062E })[dm.kind] || 0x20)
        }
    }
    Component { id: cWx
        Grid {
            columns: dm.vert ? 1 : 2; spacing: 5
            horizontalItemAlignment: Grid.AlignHCenter; verticalItemAlignment: Grid.AlignVCenter
            WxIcon { size: 18; cond: BarSvc.wx ? BarSvc.wx.cond : ""; color: dm.np.primary
                night: { const h = dm.now.getHours(); return h < 6 || h >= 19 } }
            Text { text: BarSvc.wx ? BarSvc.wx.temp + "°" : "--"; color: dm.np.fg; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium }
        }
    }
    Component { id: cSys
        Grid {
            columns: dm.vert ? 1 : 2; spacing: 6
            Repeater {
                model: [["CPU", dm.cpu], ["RAM", dm.ram]]
                delegate: Item {
                    required property var modelData
                    width: 28; height: 28
                    Canvas {
                        id: ring
                        anchors.fill: parent
                        property real v: modelData[1]
                        onVChanged: requestPaint()
                        onPaint: {
                            const c = getContext("2d"); c.reset()
                            c.lineWidth = 3; c.lineCap = "round"
                            c.strokeStyle = dm.np.track; c.beginPath(); c.arc(14, 14, 11, 0, Math.PI * 2); c.stroke()
                            c.strokeStyle = dm.np.primary; c.beginPath(); c.arc(14, 14, 11, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.02, v)); c.stroke()
                        }
                    }
                    Text { anchors.centerIn: parent; text: Math.round(modelData[1] * 100); color: dm.np.fg; font.family: Fonts.main; font.pixelSize: 9; font.weight: Font.DemiBold }
                }
            }
        }
    }
    Component { id: cSearch
        Row {
            spacing: 8
            MIcon { anchors.verticalCenter: parent.verticalCenter; size: 18; name: "search"; glyph: ""; color: dm.np.primary }
            Text { visible: !dm.vert; anchors.verticalCenter: parent.verticalCenter; text: Tr.t("Search apps ..."); width: 110; elide: Text.ElideRight
                color: dm.np.dim; font.family: Fonts.main; font.pixelSize: 13 }
        }
    }
    // a module can be wider than its own room on a narrow dock: the clock's date never overflows the pill
    clip: false
}
