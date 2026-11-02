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
// Styles: flat, island (one pill), islands (a pill for each side), pills (a pill for each module).
// What sits where comes from ~/.config/rice/bar.json (layout: left, center, right).
PanelWindow {
    id: bar

    // ---------- settings (~/.config/rice/bar.json) ----------
    property var bc: ({})
    readonly property bool on: bc.enabled === true
    readonly property string sty: bc.style === "flat" || bc.style === "islands" || bc.style === "pills" ? bc.style : "island"
    readonly property bool island: sty === "island"
    readonly property bool floating: sty !== "flat"
    readonly property var lay: bc.layout ? bc.layout : ({ left: ["launcher", "workspaces", "title"], center: ["clock"], right: ["media", "tray", "volume", "network", "battery", "notifications", "power"] })
    readonly property bool atBottom: bc.position === "bottom"
    readonly property int barH: bc.height ? bc.height : 38
    readonly property int nws: bc.workspaces ? bc.workspaces : 5
    readonly property string wsStyle: bc.ws_style === "pacman" || bc.ws_style === "letters" ? bc.ws_style : "dots"
    readonly property color fg: "#F6F5F4"
    readonly property color dim: Qt.rgba(0.965, 0.961, 0.957, 0.66)
    readonly property color line: Qt.rgba(1, 1, 1, 0.09)
    readonly property real alpha: Look.flat ? 1 : (bc.opacity !== undefined ? bc.opacity : 0.72)
    readonly property color bg: Qt.rgba(0.05, 0.05, 0.05, alpha)
    readonly property real gap: floating ? 8 : 0
    property string cfgText: ""
    readonly property string home: Quickshell.env("HOME")

    Process {
        id: cfgProc
        command: ["bash", "-c", "cat \"$HOME/.config/rice/bar.json\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t === bar.cfgText) return
                bar.cfgText = t
                try { bar.bc = t === "" ? ({}) : JSON.parse(t) } catch (e) { }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!cfgProc.running) cfgProc.running = true }

    // ---------- the window ----------
    visible: on
    color: "transparent"
    anchors { top: !atBottom; bottom: atBottom; left: true; right: true }
    implicitHeight: barH + gap * 2
    exclusionMode: ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "rice-bar"

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
    function goWs(id) { Hyprland.dispatch("workspace " + id) }
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

    property var now: new Date()
    Timer { interval: bc.seconds === true ? 1000 : 15000; running: bar.on; repeat: true; triggeredOnStart: true; onTriggered: bar.now = new Date() }
    function two(n) { return n < 10 ? "0" + n : "" + n }
    readonly property string days: "SunMonTueWedThuFriSat"
    readonly property string months: "JanFebMarAprMayJunJulAugSepOctNovDec"
    readonly property string timeText: two(now.getHours()) + ":" + two(now.getMinutes()) + (bc.seconds === true ? ":" + two(now.getSeconds()) : "")
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
        }
        return null
    }

    Component { id: mLauncher
        Item { property bool shown: true; width: 22; height: bar.barH
            MIcon { anchors.centerIn: parent; name: "apps"; glyph: String.fromCodePoint(0xF003B); size: 18; color: lm.containsMouse ? bar.fg : bar.dim
                scale: lm.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } } }
            MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("click"); bar.run("\"$HOME/.local/bin/rice-launch\"") } }
        }
    }

    Component { id: mWorkspaces
        Row { property bool shown: true; height: bar.barH; spacing: bar.wsStyle === "dots" ? 7 : 4
            Repeater {
                model: bar.maxWs()
                delegate: Item {
                    id: cell
                    readonly property int wid: index + 1
                    readonly property bool act: bar.focusedId === wid
                    readonly property bool occ: bar.occupied(wid)
                    readonly property bool dots: bar.wsStyle === "dots"
                    readonly property bool pac: bar.wsStyle === "pacman"
                    width: dots ? (act ? 26 : 10) : (pac ? 16 : 14); height: bar.barH
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                    // dots: a small dot, the active one stretched into a pill
                    Rectangle {
                        visible: cell.dots
                        anchors.centerIn: parent
                        width: parent.width; height: act ? 8 : (wm.containsMouse ? 10 : 8); radius: height / 2
                        color: act ? Look.accent : (occ ? Qt.rgba(0.965, 0.961, 0.957, 0.7) : Qt.rgba(0.965, 0.961, 0.957, 0.2))
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on height { NumberAnimation { duration: 120 } }
                    }

                    // pacman: the active workspace is Pac-Man, the ones he has passed are eaten
                    Rectangle {
                        visible: cell.pac && !act
                        anchors.centerIn: parent
                        width: occ ? 7 : 5; height: width; radius: width / 2
                        color: Qt.rgba(0.965, 0.961, 0.957, wid < bar.focusedId ? 0.1 : (occ ? 0.85 : 0.4))
                        scale: wm.containsMouse ? 1.4 : 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 120 } }
                    }
                    Canvas {
                        id: pc
                        visible: cell.pac && act
                        anchors.centerIn: parent
                        width: 16; height: 16
                        property real mouth: 0.05
                        onMouthChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()
                        SequentialAnimation on mouth {
                            running: pc.visible; loops: Animation.Infinite
                            NumberAnimation { to: 0.27; duration: 220; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.03; duration: 220; easing.type: Easing.InOutSine }
                        }
                        onPaint: {
                            const c = getContext("2d")
                            c.reset()
                            c.fillStyle = "#ffd23f"
                            c.beginPath()
                            c.moveTo(width / 2, height / 2)
                            c.arc(width / 2, height / 2, width / 2, mouth * Math.PI, (2 - mouth) * Math.PI)
                            c.closePath()
                            c.fill()
                        }
                    }

                    // letters: A B C ...
                    Text {
                        visible: !cell.dots && !cell.pac
                        anchors.centerIn: parent
                        text: String.fromCharCode(65 + index)
                        font.family: Fonts.main; font.pixelSize: act ? 14 : 12; font.weight: act ? Font.Bold : Font.Normal
                        color: act ? Look.accent : (occ ? Qt.rgba(0.965, 0.961, 0.957, 0.85) : Qt.rgba(0.965, 0.961, 0.957, 0.3))
                        scale: wm.containsMouse ? 1.2 : 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on font.pixelSize { NumberAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 120 } }
                    }
                    MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Sfx.play("select"); bar.goWs(wid) } }
                }
            }
            WheelHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) { Hyprland.dispatch("workspace " + (e.angleDelta.y > 0 ? "e-1" : "e+1")) } }
        }
    }

    Component { id: mTitle
        Text { readonly property bool shown: text !== ""; height: bar.barH; verticalAlignment: Text.AlignVCenter
            width: Math.min(implicitWidth, Math.max(120, bar.width * 0.2)); elide: Text.ElideRight
            text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
            color: bar.dim; font.family: Fonts.main; font.pixelSize: 12 }
    }

    Component { id: mMedia
        Text { readonly property bool shown: bar.track !== ""; height: bar.barH; verticalAlignment: Text.AlignVCenter
            width: Math.min(implicitWidth, 220); elide: Text.ElideRight
            text: "\u266a  " + bar.track
            color: bar.dim; font.family: Fonts.main; font.pixelSize: 12 }
    }

    Component { id: mClock
        Item { property bool shown: true; height: bar.barH
            width: Math.max(ct.implicitWidth, cd.implicitWidth) + 12
            Text { id: ct; anchors.centerIn: parent; text: bar.timeText; color: bar.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.Medium
                opacity: cm.containsMouse ? 0 : 1; scale: cm.containsMouse ? 0.9 : 1
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } }
            Text { id: cd; anchors.centerIn: parent; text: bar.dateText; color: bar.fg; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.Medium
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
                    width: 16; height: bar.barH
                    IconImage { anchors.centerIn: parent; implicitSize: 16; source: modelData.icon
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
            MouseArea { id: vm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted
                onWheel: function(e) { if (bar.sink && bar.sink.audio) bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (e.angleDelta.y > 0 ? 0.04 : -0.04))) } }
            Rectangle {   // a small level line under the icon
                anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + 14; height: 2; radius: 1
                width: 16 * Math.min(1, bar.vol); color: Look.accent; opacity: vm.containsMouse ? 0.9 : 0
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
                    if (m.button === Qt.RightButton) { bar.run("\"$HOME/.local/bin/wifi-menu\""); return }
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
                    if (m.button === Qt.RightButton) { bar.run("overskride || blueman-manager"); return }
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
                onClicked: function(m) { bar.run(m.button === Qt.RightButton ? "swaync-client -d -sw" : "swaync-client -t -sw") } }
        }
    }

    Component { id: mPower
        Item { property bool shown: true; width: 22; height: bar.barH
            MIcon { anchors.centerIn: parent; name: "power_settings_new"; glyph: String.fromCodePoint(0xF0425); size: 18; color: pm.containsMouse ? "#ff6b6b" : bar.dim
                Behavior on color { ColorAnimation { duration: 150 } } }
            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) { bar.run(m.button === Qt.RightButton ? "\"$HOME/.local/bin/logout\"" : "\"$HOME/.local/bin/rice-services\" session lock") } }
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
        width: row.width + (soft ? 28 : 0)
        radius: height / 2
        color: soft ? bar.bg : "transparent"
        border.width: soft ? 1 : 0
        border.color: bar.line
        Row {
            id: row
            anchors.centerIn: parent
            spacing: bar.sty === "pills" ? 8 : 14
            Repeater {
                model: zone.mods
                delegate: Item {
                    id: slot
                    readonly property bool shown: ld.status === Loader.Ready && ld.item && ld.item.shown !== false
                    readonly property bool pill: bar.sty === "pills"
                    visible: shown
                    width: shown ? ld.width + (pill ? 24 : 0) : 0
                    height: bar.barH
                    Rectangle { visible: slot.pill; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: bar.barH
                        radius: height / 2; color: bar.bg; border.width: 1; border.color: bar.line }
                    Loader { id: ld; anchors.centerIn: parent; sourceComponent: bar.compFor(modelData) }
                }
            }
        }
    }

    // ---------- the bar ----------
    Item {
        id: body
        x: bar.gap; y: bar.gap
        width: parent.width - 2 * bar.gap
        height: bar.barH
        opacity: bar.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 240 } }
        transform: Translate { y: bar.on ? 0 : (bar.atBottom ? 12 : -12); Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } } }

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

        readonly property bool soft: bar.sty === "islands"
        readonly property real edge: bar.sty === "island" ? 16 : (bar.sty === "flat" ? 14 : 0)
        Zone { id: zl; mods: bar.lay.left || []; soft: body.soft
            x: body.edge; y: 0 }
        Zone { id: zc; mods: bar.lay.center || []; soft: body.soft
            x: (body.width - width) / 2; y: 0 }
        Zone { id: zr; mods: bar.lay.right || []; soft: body.soft
            x: body.width - width - body.edge; y: 0 }
    }
}
