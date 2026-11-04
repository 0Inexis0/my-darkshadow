import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// The DarkShadow bar: the bar of this shell, made in Quickshell (Settings > DarkShadow bar and Bar layout).
// Styles: flat, island (one pill), islands (a pill for each side), pills (a pill for each module), notch (the middle
// grows out of the screen edge, the sides are islands), dynamic (Material 3: tonal pills in your theme color, the
// launcher and the active workspace in your key color, soft state layers on hover, and in the middle an island that
// grows into the player, the volume, the workspace, notifications and recording: DynIsland.qml). The old "google"
// style is dynamic now. Auto-hide: it slides away and a thin strip at the edge brings it back.
// What sits where comes from ~/.config/rice/bar.json (layout: left, center, right).
PanelWindow {
    id: bar

    // ---------- settings (~/.config/rice/bar.json) ----------
    property var bc: ({})
    readonly property bool on: bc.enabled !== false     // no bar.json yet (a fresh install or an update) = on
    // the style asked for; the bar fades and settles into it (sty follows want once the old look has gone)
    readonly property string want: bc.style === "google" ? "dynamic"
        : (bc.style === "flat" || bc.style === "islands" || bc.style === "pills" || bc.style === "notch" || bc.style === "dynamic" ? bc.style : "island")
    property string sty: "island"
    property real swap: 0                       // 0 shown .. 1 gone (while the style changes)
    property bool styReady: false
    onWantChanged: {
        if (!styReady) { sty = want; return }
        if (want !== sty) styAnim.restart()
    }
    Timer { running: true; interval: 1200; onTriggered: { bar.sty = bar.want; bar.styReady = true } }
    SequentialAnimation {
        id: styAnim
        NumberAnimation { target: bar; property: "swap"; to: 1; duration: 170; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.accel }
        ScriptAction { script: bar.sty = bar.want }
        PauseAnimation { duration: 60 }
        NumberAnimation { target: bar; property: "swap"; to: 0; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.decel }
    }
    readonly property bool notch: sty === "notch"
    readonly property bool dyn: sty === "dynamic"
    readonly property bool goo: dyn                              // the Material 3 look of the Dynamic style
    property var nf: null                                         // Notifs.qml, for the island
    readonly property bool islandNotifs: hasIsland && bc.island_notifs !== false
    readonly property bool islandVolume: hasIsland && bc.island_volume !== false
    // the Google style's colors: tonal, made from your theme color (the same as the control center)
    NPal { id: gp; theme: "shell"; alpha: Math.min(1, bar.alpha + 0.14) }
    readonly property bool hideOn: bc.autohide === true
    readonly property bool shadowOn: bc.shadow !== false && Look.shadows && Look.shadowBar
    // auto-hide: shown while the pointer is on it (and a moment after it leaves)
    property bool peek: false
    readonly property bool shownBar: !hideOn || peek
    Timer { id: leaveT; interval: 700; onTriggered: bar.peek = false }
    readonly property bool island: sty === "island"
    readonly property bool floating: sty !== "flat"
    readonly property var layRaw: bc.layout ? bc.layout : ({ left: ["launcher", "workspaces", "title"], center: ["clock"], right: ["media", "tray", "volume", "network", "battery", "notifications", "power"] })
    function laid(l, k) { return (l.left || []).indexOf(k) >= 0 || (l.center || []).indexOf(k) >= 0 || (l.right || []).indexOf(k) >= 0 }
    // the island is a module of the layout ("island", any zone, any style, with modules beside it). Dynamic without
    // it in the layout puts it in the middle, as before
    readonly property var lay: dyn && !laid(layRaw, "island")
        ? ({ left: layRaw.left || [], center: ["island"], right: layRaw.right || [] }) : layRaw
    readonly property bool hasIsland: on && laid(lay, "island")
    property Item islSlot: null                 // where the island sits in its zone
    readonly property bool islAlone: ["left", "center", "right"].some(function(z) { const m = lay[z] || []; return m.length === 1 && m[0] === "island" })
    readonly property bool atBottom: bc.position === "bottom"
    readonly property int barH: bc.height ? bc.height : 38
    // tray icons: Settings > DarkShadow bar > Tray icon size (never taller than the bar)
    readonly property int traySize: Math.min(barH - 8, bc.tray_size ? bc.tray_size : 18)
    readonly property int nws: bc.workspaces ? bc.workspaces : 5
    readonly property string wsStyle: bc.ws_style === "pacman" || bc.ws_style === "letters" || bc.ws_style === "numbers" ? bc.ws_style : "dots"
    // the launcher button: a distro logo (Nerd Font) or the app grid (Settings > DarkShadow bar > Launcher icon)
    readonly property var logos: ({
        tux: 0xF17C, arch: 0xF303, gentoo: 0xF30D, fedora: 0xF30A, debian: 0xF306, ubuntu: 0xF31B, nixos: 0xF313,
        cachyos: 0xF385, endeavouros: 0xF322, manjaro: 0xF312, linuxmint: 0xF30E, opensuse: 0xF314, void: 0xF32E,
        alpine: 0xF300, pop: 0xF32A, kali: 0xF327, centos: 0xF304, raspbian: 0xF315, elementary: 0xF309, zorin: 0xF32F,
        nobara: 0xF380, artix: 0xF31F, slackware: 0xF318, garuda: 0xF303, mageia: 0xF310, rocky: 0xF32B
    })
    property var osIds: []
    Process {
        id: osProc
        running: true
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; echo \"$ID $ID_LIKE\""]
        stdout: StdioCollector { onStreamFinished: bar.osIds = text.trim().toLowerCase().split(/\s+/) }
    }
    readonly property string logoKey: {
        const k = bc.logo || "auto"
        if (k === "apps") return "apps"
        if (k !== "auto") return logos[k] !== undefined ? k : "apps"
        for (let i = 0; i < osIds.length; i++) {
            const id = osIds[i] === "opensuse-tumbleweed" || osIds[i] === "opensuse-leap" ? "opensuse" : osIds[i]
            if (logos[id] !== undefined) return id
        }
        return "tux"
    }
    readonly property color fg: goo ? gp.fg : "#F6F5F4"
    readonly property color dim: goo ? gp.dim : Qt.rgba(0.965, 0.961, 0.957, 0.66)
    readonly property color line: goo ? "transparent" : Qt.rgba(1, 1, 1, 0.09)
    readonly property real alpha: Look.flat ? 1 : (bc.opacity !== undefined ? bc.opacity : 0.72)
    readonly property color bg: goo ? gp.surface : Qt.rgba(0.05, 0.05, 0.05, alpha)
    readonly property real gap: floating ? 8 : 0
    property string cfgText: ""
    readonly property string home: Quickshell.env("HOME")

    Trigger {
        path: bar.home + "/.config/rice/bar.json"
        every: 2000
        onContent: function(t) {
            const x = t.trim()
            if (x === bar.cfgText) return
            bar.cfgText = x
            try { bar.bc = x === "" ? ({}) : JSON.parse(x) } catch (e) { }
        }
    }

    // ---------- the window ----------
    visible: on
    color: "transparent"
    anchors { top: !atBottom; bottom: atBottom; left: true; right: true }
    // room below for the recording island; windows only keep away from the bar itself
    implicitHeight: barH + gap * 2 + (hasIsland || dyn ? 196 : 54)      // room for the island to grow (any style)
    exclusionMode: hideOn ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: hideOn ? 0 : barH + gap * 2
    // only the bar (and the recording island) take the pointer; auto-hide: only a thin strip at the edge
    mask: Region { item: bar.shownBar ? hitBar : hitStrip; Region { item: hitRec } Region { item: hitIsl } }
    // the island when it has grown out of the bar
    Item { id: hitIsl; x: bar.gap + isl.x + isl.ux; y: body.y + isl.y + isl.uy; width: isl.visible && bar.shownBar ? isl.uw : 0; height: isl.uh }
    Item { id: hitBar; width: parent.width; height: bar.barH + bar.gap * 2; y: bar.atBottom ? parent.height - height : 0 }
    Item { id: hitRec; x: recIsland.x + bar.gap; width: recIsland.width; height: bar.recOn && bar.shownBar ? 54 : 0; y: bar.atBottom ? 0 : bar.barH + bar.gap * 2 }
    Item { id: hitAll; anchors.fill: parent }
    Item { id: hitStrip; width: parent.width; height: 3; y: bar.atBottom ? parent.height - 3 : 0 }
    HoverHandler {
        enabled: bar.hideOn
        onHoveredChanged: { if (hovered) { leaveT.stop(); bar.peek = true } else leaveT.restart() }
    }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "rice-bar"

    // ---------- screen recording (rice-hotcorner record): the island under the bar ----------
    property bool recOn: false
    property real recStart: 0
    property bool micMuted: false
    property real nowS: Date.now() / 1000
    readonly property string recTime: {
        const t = Math.max(0, Math.floor(nowS - recStart))
        return two(Math.floor(t / 3600)) + ":" + two(Math.floor(t / 60) % 60) + ":" + two(t % 60)
    }
    Trigger {
        path: bar.home + "/.cache/rice/record.json"
        every: 2500
        onContent: function(t) {
            let j = null
            try { j = t.trim() !== "" ? JSON.parse(t) : null } catch (e) { j = null }
            bar.recOn = j !== null
            if (j) { bar.recStart = j.start || Date.now() / 1000; recCheck.running = true; micProc.running = true }
        }
    }
    Timer { interval: 1000; running: bar.recOn; repeat: true; onTriggered: bar.nowS = Date.now() / 1000 }
    // a recorder that quit on its own leaves its files behind: check now and then that it still runs
    Timer { interval: 5000; running: bar.recOn; repeat: true; onTriggered: { if (!recCheck.running) recCheck.running = true; if (!micProc.running) micProc.running = true } }
    Process {
        id: recCheck
        command: ["bash", "-c", "p=$(cat \"$HOME/.cache/rice/record.pid\" 2>/dev/null); [ -n \"$p\" ] && kill -0 \"$p\" 2>/dev/null && echo 1 || { rm -f \"$HOME/.cache/rice/record.pid\" \"$HOME/.cache/rice/record.json\"; echo 0; }"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() === "0") bar.recOn = false }
    }
    Process {
        id: micProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: bar.micMuted = text.indexOf("MUTED") >= 0 }
    }

    // ---------- the things the bar shows ----------
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    function occupied(id) {
        const l = Hyprland.workspaces.values
        for (let i = 0; i < l.length; i++) if (l[i].id === id && l[i].toplevels && l[i].toplevels.values.length > 0) return true
        return false
    }
    function maxWs() {
        const l = Hyprland.workspaces.values
        let m = bar.nws
        for (let i = 0; i < l.length; i++) if (l[i].id > m && l[i].id <= 20) m = l[i].id
        return m
    }
    // through ws-go: Hyprland with a Lua config wants hl.dsp.focus(...), the old "workspace N" does nothing there
    function goWs(id) { run("\"$HOME/.local/bin/ws-go\" " + id) }
    function run(cmd) { Quickshell.execDetached(["bash", "-c", cmd]) }

    function pickPlayer() {
        const l = Mpris.players.values
        for (let i = 0; i < l.length; i++) if (l[i].isPlaying) return l[i]
        return null
    }
    readonly property var player: pickPlayer()
    readonly property string track: player ? ((player.trackArtist ? player.trackArtist + " - " : "") + (player.trackTitle || "")) : ""

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [bar.sink] }
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property var batt: UPower.displayDevice
    readonly property bool hasBatt: batt && batt.isPresent && batt.isLaptopBattery
    readonly property real battPct: batt ? Math.round(batt.percentage * 100) : 0
    readonly property bool charging: batt && (batt.state === UPowerDeviceState.Charging || batt.state === UPowerDeviceState.FullyCharged)

    property var svc: ({})
    Process {
        id: svcProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-services\" state 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { bar.svc = JSON.parse(text) } catch (e) { } } }
    }
    Timer { interval: 8000; running: bar.on; repeat: true; triggeredOnStart: true; onTriggered: if (!svcProc.running) svcProc.running = true }
    Timer { id: svcAgain; interval: 700; onTriggered: if (!svcProc.running) svcProc.running = true }

    property var now: new Date()
    Timer { interval: bc.seconds === true ? 1000 : 15000; running: bar.on; repeat: true; triggeredOnStart: true; onTriggered: bar.now = new Date() }
    function two(n) { return n < 10 ? "0" + n : "" + n }
    readonly property string days: "SunMonTueWedThuFriSat"
    readonly property string months: "JanFebMarAprMayJunJulAugSepOctNovDec"
    // 24 or 12 hour clock: Settings > Sound & language > Language & region (rice-region)
    property bool h12: false
    Trigger {
        path: bar.home + "/.config/rice/region.json"
        every: 5000
        onContent: function(t) { bar.h12 = /"clock": *"12"/.test(t) }
    }
    readonly property string timeText: (h12 ? ((now.getHours() + 11) % 12 + 1) : two(now.getHours())) + ":" + two(now.getMinutes())
                                       + (bc.seconds === true ? ":" + two(now.getSeconds()) : "") + (h12 ? (now.getHours() < 12 ? " AM" : " PM") : "")
    readonly property string dateText: days.substr(now.getDay() * 3, 3) + " " + now.getDate() + " " + months.substr(now.getMonth() * 3, 3)

    // ---------- the modules ----------
    function compFor(n) {
        switch (n) {
        case "launcher": return mLauncher
        case "workspaces": return mWorkspaces
        case "title": return mTitle
        case "media": return mMedia
        case "clock": return mClock
        case "tray": return mTray
        case "volume": return mVolume
        case "network": return mNetwork
        case "bluetooth": return mBluetooth
        case "battery": return mBattery
        case "notifications": return mNotify
        case "power": return mPower
        case "island": return mIsland
        }
        return null
    }

    Component { id: mLauncher
        Item { property bool shown: true; width: bar.goo ? bar.barH - 8 : 22; height: bar.barH
            // Google: the launcher sits in a circle of your key color
            Rectangle { visible: bar.goo; anchors.centerIn: parent; width: parent.width; height: width; radius: lm.pressed ? width * 0.3 : width / 2
                color: gp.primary; scale: lm.containsMouse ? 1.06 : 1
                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } } }
            MIcon { visible: bar.logoKey === "apps"; anchors.centerIn: parent; name: "apps"; glyph: String.fromCodePoint(0xF003B); size: 18; color: bar.goo ? gp.inkPrimary : (lm.containsMouse ? bar.fg : bar.dim)
                scale: lm.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } } }
            Text { visible: bar.logoKey !== "apps"; anchors.centerIn: parent; anchors.horizontalCenterOffset: 1
                text: bar.logos[bar.logoKey] !== undefined ? String.fromCodePoint(bar.logos[bar.logoKey]) : ""
                font.family: Fonts.icons; font.pixelSize: bar.goo ? 17 : 18; color: bar.goo ? gp.inkPrimary : bar.fg
                scale: lm.containsMouse ? 1.15 : 1; Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } } }
            MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("click"); bar.run("\"$HOME/.local/bin/rice-launch\"") } }
        }
    }

    Component { id: mWorkspaces
        Item {
            id: wsm
            property bool shown: true
            readonly property string st: bar.wsStyle
            readonly property bool pac: st === "pacman"
            readonly property bool dots: st === "dots"
            // every workspace has the same width, so nothing in the row moves; what moves is one marker that slides.
            // The sliding and the popping run as Animators, on the render thread: they stay smooth even while the
            // shell is busy (the desktop widgets coming back when you switch to an empty workspace)
            readonly property real cw: dots ? 16 : (pac ? 20 : 18)
            readonly property int count: bar.maxWs()
            readonly property int fi: bar.focusedId - 1
            readonly property bool fiOk: fi >= 0 && fi < count
            width: wsRow.width; height: bar.barH

            Row {
                id: wsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: wsm.dots ? 7 : 0
                Repeater {
                    model: wsm.count
                    delegate: Item {
                        id: cell
                        readonly property int wid: index + 1
                        readonly property bool act: bar.focusedId === wid
                        readonly property bool occ: bar.occupied(wid)
                        width: wsm.dots && act ? 40 : wsm.cw; height: bar.barH
                        Behavior on width { enabled: wsm.dots; NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                        // dots: a dot, the active one stretched into a pill
                        Rectangle {
                            visible: wsm.dots
                            anchors.centerIn: parent
                            width: parent.width; height: bar.goo && act ? 22 : (bar.goo ? 10 : 14); radius: height / 2
                            Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                            color: bar.goo ? (act ? gp.primary : (occ ? gp.inkContainer : gp.track))
                                           : (act ? bar.fg : (occ ? Qt.rgba(0.965, 0.961, 0.957, 0.62) : Qt.rgba(0.965, 0.961, 0.957, 0.24)))
                            // Google: the active workspace shows its number
                            Text { anchors.centerIn: parent; visible: bar.goo; opacity: act ? 1 : 0; text: String(wid)
                                color: gp.inkPrimary; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Bold
                                Behavior on opacity { NumberAnimation { duration: 200 } } }
                            scale: wm.containsMouse && !act ? 1.18 : 1
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { ScaleAnimator { duration: 120 } }
                        }
                        // pacman: pac-dots; the one Pac-Man sits on is gone, the ones he has passed are eaten
                        Rectangle {
                            visible: wsm.pac
                            anchors.centerIn: parent
                            width: occ ? 10 : 7; height: width; radius: width / 2
                            color: Qt.rgba(0.965, 0.961, 0.957, occ ? 0.9 : 0.45)
                            opacity: act ? 0 : (wid < bar.focusedId ? 0.25 : 1)
                            scale: wm.containsMouse ? 1.35 : 1
                            Behavior on opacity { OpacityAnimator { duration: 260 } }
                            Behavior on scale { ScaleAnimator { duration: 120 } }
                        }
                        // letters (A B C) or numbers (1 2 3); Dynamic: the active one sits in a pill of your key color
                        Rectangle {
                            visible: bar.goo && !wsm.dots && !wsm.pac
                            anchors.centerIn: parent
                            width: 22; height: 22; radius: 11
                            color: gp.primary
                            opacity: act ? 1 : 0
                            scale: act ? 1 : 0.5
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                        }
                        Text {
                            visible: !wsm.dots && !wsm.pac
                            anchors.centerIn: parent
                            text: wsm.st === "numbers" ? String(wid) : String.fromCharCode(64 + wid)
                            font.family: Fonts.main; font.pixelSize: 14; font.weight: act ? Font.Bold : Font.Medium
                            color: bar.goo ? (act ? gp.inkPrimary : (occ ? gp.fg : gp.dim)) : (act ? bar.fg : (occ ? Qt.rgba(0.965, 0.961, 0.957, 0.9) : Qt.rgba(0.965, 0.961, 0.957, 0.32)))
                            scale: act ? (bar.goo ? 1 : 1.18) : (wm.containsMouse ? 1.12 : 1)
                            Behavior on scale { ScaleAnimator { duration: 220; easing.type: Easing.OutBack } }
                        }
                        MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bar.goWs(wid) }
                    }
                }
            }

            // Pac-Man: still and white; he only chomps while he runs to the workspace you switch to
            Item {
                id: pacBox
                visible: wsm.pac && wsm.fiOk
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter
                readonly property real tx: Math.max(0, wsm.fi) * wsm.cw + (wsm.cw - width) / 2
                property bool facingLeft: false
                x: tx
                Behavior on x { XAnimator { duration: 380; easing.type: Easing.InOutCubic } }
                onTxChanged: { facingLeft = tx < x; chomp.restart() }
                Canvas {
                    id: pac
                    anchors.fill: parent
                    property real mouth: 0.2
                    renderStrategy: Canvas.Threaded
                    SequentialAnimation {
                        id: chomp
                        SequentialAnimation {
                            loops: 3
                            NumberAnimation { target: pac; property: "mouth"; to: 0.02; duration: 65 }
                            NumberAnimation { target: pac; property: "mouth"; to: 0.26; duration: 65 }
                        }
                        NumberAnimation { target: pac; property: "mouth"; to: 0.2; duration: 80 }
                    }
                    transform: Scale { origin.x: 9; xScale: pacBox.facingLeft ? -1 : 1 }
                    onMouthChanged: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                    onPaint: {
                        const c = getContext("2d")
                        c.reset()
                        c.fillStyle = "#F6F5F4"
                        c.beginPath()
                        c.moveTo(width / 2, height / 2)
                        c.arc(width / 2, height / 2, width / 2, mouth * Math.PI, (2 - mouth) * Math.PI)
                        c.closePath()
                        c.fill()
                    }
                }
            }
            WheelHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) { bar.goWs(e.angleDelta.y > 0 ? "e-1" : "e+1") } }
        }
    }

    Component { id: mTitle
        Text { readonly property bool shown: text !== ""; height: bar.barH; verticalAlignment: Text.AlignVCenter
            width: Math.min(implicitWidth, Math.max(120, bar.width * 0.2)); elide: Text.ElideRight
            text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
            color: bar.dim; font.family: Fonts.main; font.pixelSize: 12 }
    }

    Component { id: mMedia
        Text { id: mt; readonly property bool shown: bar.track !== ""; height: bar.barH; verticalAlignment: Text.AlignVCenter
            width: Math.min(implicitWidth, 220); elide: Text.ElideRight
            // the last song stays written while the module folds away (paused, stopped)
            property string keep: ""
            Component.onCompleted: keep = bar.track
            Connections { target: bar; function onTrackChanged() { if (bar.track !== "") mt.keep = bar.track } }
            text: "\u266a  " + keep
            color: bar.dim; font.family: Fonts.main; font.pixelSize: 12 }
    }

    Component { id: mClock
        Item { property bool shown: true; height: bar.barH
            width: bar.goo ? gRow.width + 8 : Math.max(ct.implicitWidth, cd.implicitWidth) + 12
            // Google: the time, then the date, side by side
            Row { id: gRow; visible: bar.goo; anchors.centerIn: parent; spacing: 8
                Text { anchors.verticalCenter: parent.verticalCenter; text: bar.timeText; color: gp.inkContainer
                    font.family: Fonts.main; font.pixelSize: 15; font.weight: Font.DemiBold }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: gp.inkContainer; opacity: 0.5 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: bar.dateText; color: gp.inkContainer; opacity: 0.8
                    font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium } }
            Text { id: ct; visible: !bar.goo; anchors.centerIn: parent; text: bar.timeText; color: bar.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.Medium
                opacity: cm.containsMouse ? 0 : 1; scale: cm.containsMouse ? 0.9 : 1
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
            Text { id: cd; visible: !bar.goo; anchors.centerIn: parent; text: bar.dateText; color: bar.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.Medium
                opacity: cm.containsMouse ? 1 : 0; scale: cm.containsMouse ? 1 : 1.1
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { Sfx.play("click"); bar.run("\"$HOME/.local/bin/rice-dashboard\" open") } }
        }
    }

    Component { id: mTray
        Row { readonly property bool shown: SystemTray.items.values.length > 0; height: bar.barH; spacing: 10
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    id: ti
                    width: bar.traySize; height: bar.barH
                    IconImage { anchors.centerIn: parent; implicitSize: bar.traySize; source: modelData.icon
                        scale: tm.containsMouse ? 1.15 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } } }
                    MouseArea {
                        id: tm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(m) {
                            if (m.button === Qt.RightButton || modelData.onlyMenu) {
                                if (modelData.hasMenu) { const p = ti.mapToItem(null, 0, bar.barH + bar.gap); modelData.display(bar, p.x, p.y) }
                            } else if (m.button === Qt.MiddleButton) modelData.secondaryActivate()
                            else modelData.activate()
                        }
                    }
                }
            }
        }
    }

    Component { id: mVolume
        Item { property bool shown: true; width: 28; height: bar.barH
            MIcon { anchors.centerIn: parent; size: 23; color: bar.muted ? bar.dim : bar.fg
                name: bar.muted ? "volume_off" : (bar.vol < 0.34 ? "volume_mute" : (bar.vol < 0.67 ? "volume_down" : "volume_up"))
                glyph: String.fromCodePoint(bar.muted ? 0xF0581 : (bar.vol < 0.34 ? 0xF057F : (bar.vol < 0.67 ? 0xF0580 : 0xF057E))) }
            MouseArea { id: vm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) {
                    // left: the sound menu, right: mute
                    if (m.button === Qt.LeftButton) { const p = mapToItem(null, width / 2, 0); bar.run("\"$HOME/.local/bin/rice-volume\" menu " + Math.round(p.x)); return }
                    if (bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted
                }
                onWheel: function(e) { if (bar.sink && bar.sink.audio) bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (e.angleDelta.y > 0 ? 0.04 : -0.04))) } }
            Rectangle {   // a small level line under the icon
                anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + 14; height: 2; radius: 1
                width: 16 * Math.min(1, bar.vol); color: bar.fg; opacity: vm.containsMouse ? 0.9 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }
    }

    Component { id: mNetwork
        Item { property bool shown: true; width: 22; height: bar.barH
            MIcon { anchors.centerIn: parent; size: 18; color: bar.svc.network ? bar.fg : bar.dim
                name: bar.svc.network ? "wifi" : "wifi_off"
                glyph: String.fromCodePoint(bar.svc.network ? 0xF05A9 : 0xF05AA) }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) {
                    const p = mapToItem(null, width / 2, 0)
                    bar.run("\"$HOME/.local/bin/rice-wifi\" " + Math.round(p.x))
                } }
        }
    }

    Component { id: mBluetooth
        Item { property bool shown: true; width: 22; height: bar.barH
            MIcon { anchors.centerIn: parent; size: 18; color: bar.svc.bluetooth ? bar.fg : bar.dim
                name: bar.svc.bluetooth ? "bluetooth" : "bluetooth_disabled"
                glyph: String.fromCodePoint(bar.svc.bluetooth ? 0xF00AF : 0xF00B2) }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) {
                    const p = mapToItem(null, width / 2, 0)
                    bar.run("\"$HOME/.local/bin/rice-bluetooth\" " + Math.round(p.x))
                } }
        }
    }

    Component { id: mBattery
        Item { readonly property bool shown: bar.hasBatt; width: bt.implicitWidth + 4; height: bar.barH
            Row { id: bt; anchors.centerIn: parent; spacing: 5
                MIcon { size: 16; anchors.verticalCenter: parent.verticalCenter
                    color: !bar.charging && bar.battPct <= 15 ? "#ff6b6b" : bar.fg
                    name: bar.charging ? "battery_charging_full" : "battery_full"
                    glyph: String.fromCodePoint(bar.charging ? 0xF0084 : 0xF0079) }
                Text { anchors.verticalCenter: parent.verticalCenter; text: bar.battPct + "%"; color: bar.dim; font.family: Fonts.main; font.pixelSize: 12 }
            }
        }
    }

    Component { id: mNotify
        Item { property bool shown: true; width: 22; height: bar.barH
            MIcon { anchors.centerIn: parent; size: 18; color: bar.svc.dnd ? bar.dim : bar.fg
                name: bar.svc.dnd ? "notifications_off" : "notifications"
                glyph: String.fromCodePoint(bar.svc.dnd ? 0xF009B : 0xF009A) }
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                onClicked: function(m) { bar.run(m.button === Qt.RightButton ? "\"$HOME/.local/bin/rice-cc\" dnd toggle" : "\"$HOME/.local/bin/rice-cc\" toggle"); svcAgain.restart() } }
        }
    }

    // the island's place in its zone: as wide as the island at rest; the island itself floats on top (it grows
    // out of the bar), centred on this place
    Component { id: mIsland
        Item {
            id: ip
            property bool shown: true
            width: isl.restW; height: bar.barH
            Behavior on width { SpringAnimation { spring: 3.6; damping: 0.32; epsilon: 0.4 } }
            // where it is in the bar (follows the slot, the row and the zone as they move)
            readonly property real bx: parent && parent.parent && parent.parent.parent && parent.parent.parent.parent
                ? x + parent.x + parent.parent.x + parent.parent.parent.x + parent.parent.parent.parent.x : 0
            Component.onCompleted: bar.islSlot = ip
            Component.onDestruction: if (bar.islSlot === ip) bar.islSlot = null
        }
    }

    Component { id: mPower
        Item { property bool shown: true; width: 22; height: bar.barH
            MIcon { anchors.centerIn: parent; name: "power_settings_new"; glyph: String.fromCodePoint(0xF0425); size: 18; color: pm.containsMouse ? "#ff6b6b" : bar.dim
                Behavior on color { ColorAnimation { duration: 150 } } }
            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) {
                    const p = mapToItem(null, width / 2, 0)
                    bar.run("\"$HOME/.local/bin/rice-power\" " + Math.round(p.x))
                } }
        }
    }

    // ---------- one side of the bar: a row of modules ----------
    component Zone: Rectangle {
        id: zone
        property var mods: []
        property bool soft: false       // a pill of its own (islands), else no background
        readonly property bool any: row.width > 0
        visible: any
        height: bar.barH
        // Google: the zone with the clock gets a tinted pill of its own
        readonly property bool tint: bar.goo && mods.length === 1 && mods[0] === "clock"
        readonly property bool onlyIsland: mods.length === 1 && mods[0] === "island"
        // the gap between modules lives inside each module, so a module that comes or goes slides the others
        readonly property real sp: bar.sty === "pills" ? 8 : (bar.goo ? 2 : 14)
        width: Math.max(0, row.width - sp) + (soft && any && !onlyIsland ? (bar.goo ? 12 : 28) : 0)
        radius: height / 2
        color: soft && !onlyIsland ? (tint ? gp.container : bar.bg) : "transparent"
        Behavior on color { ColorAnimation { duration: 300 } }
        border.width: soft && !onlyIsland ? 1 : 0
        border.color: bar.line
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 0
            Repeater {
                model: zone.mods
                delegate: Item {
                    id: slot
                    readonly property bool shown: ld.status === Loader.Ready && ld.item && ld.item.shown !== false
                    readonly property bool pill: bar.sty === "pills"
                    // Google: every module has room around it and a soft state layer when you point at it
                    readonly property bool lay: bar.goo && modelData !== "launcher" && modelData !== "island" && !zone.tint
                    // it grows in when it appears (a new module, music that starts) and folds away when it goes
                    property bool born: false
                    Timer { running: true; interval: 40 + index * 45; onTriggered: slot.born = true }
                    property real k: born && shown ? 1 : 0
                    Behavior on k { NumberAnimation { duration: slot.k < 0.5 ? 420 : 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
                    readonly property real full: ld.width + (pill ? 24 : 0) + (lay ? 16 : (bar.goo ? 4 : 0))
                    visible: k > 0.01
                    width: (full + zone.sp) * k
                    height: bar.barH
                    opacity: Math.min(1, k * 1.4)
                    scale: 0.7 + 0.3 * k
                    HoverHandler { id: sh; enabled: slot.lay }
                    Rectangle { visible: slot.lay; anchors.centerIn: parent; width: slot.full; height: bar.barH - 8; radius: height / 2
                        color: bar.fg; opacity: sh.hovered ? 0.1 : 0
                        Behavior on opacity { NumberAnimation { duration: 160 } } }
                    Rectangle { visible: slot.pill; anchors.centerIn: parent; width: slot.full; height: bar.barH
                        radius: height / 2; color: bar.bg; border.width: 1; border.color: bar.line }
                    Loader { id: ld; anchors.centerIn: parent; sourceComponent: bar.compFor(modelData) }
                }
            }
        }
    }

    // ---------- the bar ----------
    Item {
        id: body
        x: bar.gap; y: bar.atBottom ? bar.height - bar.barH - bar.gap : bar.gap
        width: parent.width - 2 * bar.gap
        height: bar.barH
        opacity: (bar.on && bar.shownBar ? 1 : 0) * (1 - bar.swap)
        Behavior on opacity { enabled: !styAnim.running; NumberAnimation { duration: 240 } }
        transform: [Scale { origin.x: body.width / 2; origin.y: bar.atBottom ? body.height : 0; xScale: 1 - 0.035 * bar.swap; yScale: 1 - 0.2 * bar.swap },
                    Translate { y: (bar.atBottom ? 8 : -8) * bar.swap }, Translate {
            y: !bar.on ? (bar.atBottom ? 12 : -12) : (bar.shownBar ? 0 : (bar.atBottom ? 1 : -1) * (bar.barH + bar.gap * 2 + 4))
            Behavior on y { NumberAnimation { duration: 360; easing.type: bar.shownBar ? Easing.OutBack : Easing.InCubic; easing.overshoot: 0.8 } }
        }]

        // island / flat: one background behind everything
        Rectangle {
            anchors.fill: parent
            visible: bar.sty === "island" || bar.sty === "flat"
            radius: bar.sty === "island" ? height / 2 : 0
            color: bar.bg
            border.width: bar.sty === "island" ? 1 : 0
            border.color: bar.line
            Rectangle { visible: bar.sty === "flat"; width: parent.width; height: 1; color: bar.line
                anchors.bottom: bar.atBottom ? undefined : parent.bottom; anchors.top: bar.atBottom ? parent.top : undefined }
        }

        readonly property bool soft: bar.sty === "islands" || bar.goo
        readonly property real edge: bar.sty === "island" ? 16 : (bar.sty === "flat" ? 14 : 0)
        // notch: every zone sits inside one notch in the middle of the edge
        readonly property real ngap: 22
        readonly property real nW: (zl.any ? zl.width : 0) + (zc.any ? zc.width : 0) + (zr.any ? zr.width : 0)
                                   + ngap * Math.max(0, (zl.any ? 1 : 0) + (zc.any ? 1 : 0) + (zr.any ? 1 : 0) - 1)
        readonly property real nX: Math.round((width - nW) / 2)

        // a soft shadow under every background (the bar floats above the wallpaper)
        Repeater {
            model: bar.shadowOn ? (bar.sty === "island" ? [body] : (bar.sty === "islands" || bar.goo ? [zl, zc, zr] : [])) : []
            delegate: Item {
                readonly property var src: modelData
                visible: src.visible !== false && src.width > 0 && src.onlyIsland !== true
                x: src === body ? 0 : src.x; y: (src === body ? 0 : src.y) + 3
                width: src.width; height: bar.barH
                Rectangle { anchors.fill: parent; anchors.margins: -1; radius: height / 2; color: Qt.rgba(0, 0, 0, 0.18) }
                Rectangle { anchors.fill: parent; anchors.margins: -3; radius: height / 2; color: Qt.rgba(0, 0, 0, 0.08) }
            }
        }

        // ---------- notch background (and its shadow) ----------
        NotchShape {
            id: notchBg
            visible: bar.notch
            flip: bar.atBottom
            width: body.nW + 2 * ear + 40
            height: bar.barH + bar.gap
            x: body.nX - ear - 20
            y: bar.atBottom ? 0 : -bar.gap
            fill: Qt.rgba(0.02, 0.02, 0.025, Look.flat ? 1 : bar.alpha)
            shadow: bar.shadowOn
        }

        Zone { id: zl; mods: bar.lay.left || []; soft: body.soft
            x: bar.notch ? body.nX : body.edge; y: 0 }
        Zone { id: zc; mods: bar.lay.center || []; soft: body.soft
            x: bar.notch ? body.nX + (zl.any ? zl.width + body.ngap : 0) : (body.width - width) / 2; y: 0 }
        Zone { id: zr; mods: bar.lay.right || []; soft: body.soft
            x: bar.notch ? body.nX + body.nW - width : body.width - width - body.edge; y: 0 }

        // ---------- dynamic: the island in the middle ----------
        DynIsland {
            id: isl
            visible: bar.hasIsland && bar.islSlot !== null
            bar: bar
            pal: gp
            nf: bar.nf
            // in the notch it is the notch's own color, so at rest it is part of it
            areaW: body.width
            fill: bar.notch ? notchBg.fill : (bar.goo ? gp.surface : Qt.rgba(bar.bg.r, bar.bg.g, bar.bg.b, Math.min(1, bar.alpha + 0.14)))
            // at rest it only casts a shadow when it stands alone (not inside the notch or a pill with modules)
            flatRest: bar.notch || !bar.islAlone
            readonly property real cx: bar.islSlot ? bar.islSlot.bx + bar.islSlot.width / 2 : body.width / 2
            x: Math.round(Math.max(0, Math.min(body.width - width, cx - width / 2)))
            y: bar.atBottom ? bar.barH - height : 0
        }

        // ---------- the recording island: hangs under the bar while the screen is recorded ----------
        Item {
            id: recIsland
            readonly property bool on: bar.recOn && !bar.hasIsland
            width: recRow.width + 40 + (bar.notch ? 2 * 14 : 0)
            height: 46
            x: bar.notch ? body.nX + body.nW + 14 - width : body.width - width - body.edge
            y: bar.atBottom ? -height - (bar.notch ? 0 : 6) : bar.barH + (bar.notch ? bar.gap - 1 : 6)
            opacity: on ? 1 : 0
            scale: on ? 1 : 0.85
            visible: opacity > 0.01
            transformOrigin: bar.atBottom ? Item.Bottom : Item.Top
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
            NotchShape {
                anchors.fill: parent
                visible: bar.notch
                flip: bar.atBottom
                fill: notchBg.fill
                shadow: bar.shadowOn
            }
            Rectangle {
                anchors.fill: parent
                visible: !bar.notch
                radius: height / 2
                color: bar.bg
                border.width: 1; border.color: bar.line
            }
            Row {
                id: recRow
                anchors.centerIn: parent
                anchors.verticalCenterOffset: bar.notch ? (bar.atBottom ? 3 : -3) : 0
                spacing: 16
                // the red dot breathes while it records
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14; height: 14; radius: 7; color: "#ff4d4d"
                    SequentialAnimation on opacity { running: recIsland.on; loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: bar.recTime; color: bar.fg
                    font.family: Fonts.numbers; font.pixelSize: 17; font.weight: Font.Medium }
                Item { width: 2; height: 1 }
                Item {
                    width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter
                    MIcon { anchors.centerIn: parent; size: 19; name: bar.micMuted ? "mic_off" : "mic"
                        glyph: String.fromCodePoint(bar.micMuted ? 0xF036D : 0xF036C); color: bar.micMuted ? "#ff8a8a" : bar.fg }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: { bar.run("\"$HOME/.local/bin/rice-volume\" mic"); bar.micMuted = !bar.micMuted } }
                }
                Item {
                    width: 26; height: 26; anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.centerIn: parent; width: 15; height: 15; radius: 4; color: "transparent"; border.width: 2; border.color: "#ff8a8a" }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: { bar.recOn = false; bar.run("\"$HOME/.local/bin/rice-hotcorner\" record stop") } }
                }
            }
        }
    }
}
