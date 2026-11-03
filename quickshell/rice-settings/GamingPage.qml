import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Gaming hub: gaming mode and what stays on while you play, performance, your game launchers and the
// gaming tools this computer has. Gaming mode used to live in Services.
Item {
    id: page
    property var ctl

    // ---------- rice-effects: gaming mode, light mode and the "keep" options ----------
    property var fx: ({ lite: false, gaming: false, flat: false, opts: {} })
    function fxOpt(k) { return !!(fx.opts && fx.opts[k] === true) }
    function fxRun(args, msg) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-effects\" \"$@\"", "_"].concat(args))
        page.ctl.status = msg
        fxRefresh.restart()
    }
    function setGaming(on) { const n = JSON.parse(JSON.stringify(fx)); n.gaming = on; fx = n; fxRun(["gaming", on ? "on" : "off"], "Gaming mode " + (on ? "on" : "off")) }
    function setLite(on) { const n = JSON.parse(JSON.stringify(fx)); n.lite = on; fx = n; fxRun(["lite", on ? "on" : "off"], on ? "Light mode on" : "Light mode off") }
    function setOpt(k, on) { const n = JSON.parse(JSON.stringify(fx)); if (!n.opts) n.opts = {}; n.opts[k] = on; fx = n; fxRun(["set", k, on ? "on" : "off"], "Gaming mode: saved") }
    Process {
        id: fxProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-effects\" state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.fx = JSON.parse(text) } catch (e) { } } }
    }
    Timer { id: fxRefresh; interval: 1500; onTriggered: if (!fxProc.running) fxProc.running = true }
    Timer { interval: 5000; running: page.visible; repeat: true; onTriggered: if (!fxProc.running) fxProc.running = true }

    // ---------- power mode (power-profiles-daemon) ----------
    property string profile: ""
    property bool havePP: false
    Process {
        id: ppProc
        command: ["bash", "-c", "command -v powerprofilesctl >/dev/null && powerprofilesctl get 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { const t = text.trim(); page.havePP = t.length > 0; page.profile = t } }
    }
    function setProfile(p) {
        profile = p
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-services\" profile \"$1\"", "_", p])
        page.ctl.status = "Power mode: " + p
    }

    // ---------- your launchers and tools ----------
    readonly property var launchers: [
        { id: "steam", n: "Steam" }, { id: "com.heroicgameslauncher.hgl", n: "Heroic" }, { id: "heroic", n: "Heroic" },
        { id: "net.lutris.Lutris", n: "Lutris" }, { id: "lutris", n: "Lutris" }, { id: "org.prismlauncher.PrismLauncher", n: "Prism" },
        { id: "com.usebottles.bottles", n: "Bottles" }, { id: "retroarch", n: "RetroArch" }, { id: "org.libretro.RetroArch", n: "RetroArch" },
        { id: "io.itch.itch", n: "itch" }, { id: "minecraft-launcher", n: "Minecraft" }, { id: "com.valvesoftware.Steam", n: "Steam" },
        { id: "net.davidotek.pupgui2", n: "ProtonUp-Qt" }, { id: "discord", n: "Discord" }
    ]
    readonly property var found: {
        const out = [], seen = {}
        for (let i = 0; i < launchers.length; i++) {
            const e = DesktopEntries.heuristicLookup(launchers[i].id)
            if (!e || seen[e.name]) continue
            seen[e.name] = true
            out.push({ e: e, n: e.name })
        }
        return out
    }
    property var tools: ({})
    Process {
        id: toolProc
        command: ["bash", "-c", "for t in gamemoded mangohud gamescope steam wine; do command -v $t >/dev/null 2>&1 && echo \"$t 1\" || echo \"$t 0\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                text.trim().split("\n").forEach(function(l) { const p = l.split(" "); o[p[0]] = p[1] === "1" })
                page.tools = o
            }
        }
    }

    PageScroll {
        anchors.fill: parent

        // ---------- the big switch ----------
        Rectangle {
            id: hero
            width: parent.width
            height: 156
            radius: M3.rXL
            color: page.fx.gaming ? M3.primaryContainer : M3.surfaceC
            Behavior on color { ColorAnimation { duration: 300 } }
            clip: true
            // a soft shape in the corner that turns when gaming mode switches
            Rectangle {
                width: 200; height: 200; radius: 64
                x: parent.width - 270; y: -70
                rotation: page.fx.gaming ? 45 : 20
                color: page.fx.gaming ? M3.alpha(M3.primary, 0.22) : M3.alpha(M3.ink, 0.04)
                Behavior on rotation { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Rectangle {
                x: 24; anchors.verticalCenter: parent.verticalCenter
                width: 72; height: 72; radius: page.fx.gaming ? 24 : 36
                color: page.fx.gaming ? M3.primary : M3.surfaceHighest
                Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 300 } }
                T { kind: "icon"; anchors.centerIn: parent; text: ""; font.pixelSize: 30; color: page.fx.gaming ? M3.inkPrimary : M3.ink }
            }
            Column {
                x: 116; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 116 - 100
                spacing: 4
                T { kind: "title"; text: page.fx.gaming ? "Game on" : "Gaming mode"; font.pixelSize: 24; font.weight: Font.Medium
                    color: page.fx.gaming ? M3.inkPrimaryC : M3.ink }
                T { kind: "reading"; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 12
                    color: page.fx.gaming ? M3.inkPrimaryC : M3.inkDim
                    text: page.fx.gaming ? "Effects you did not keep below are off, so games get the speed." : "One switch turns off animations, blur, transparency, shadows and gaps. Pick below what stays." }
            }
            Tog { anchors.right: parent.right; anchors.rightMargin: 26; anchors.verticalCenter: parent.verticalCenter
                checked: page.fx.gaming === true; onToggled: function(v) { page.setGaming(v) } }
        }

        // the game bar
        Rectangle {
            width: parent.width; height: 84; radius: M3.rL; color: M3.surfaceC
            Rectangle { x: 18; anchors.verticalCenter: parent.verticalCenter; width: 48; height: 48; radius: 16; color: M3.secondaryContainer
                Icon { anchors.centerIn: parent; name: "space_dashboard"; glyph: "\uf009"; size: 22; color: M3.inkSecondaryC } }
            Column {
                x: 80; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80 - 170; spacing: 3
                T { text: "Game bar  ·  SUPER + G"; font.pixelSize: 14; font.weight: Font.Medium }
                T { kind: "reading"; width: parent.width; elide: Text.ElideRight; font.pixelSize: 12; color: M3.inkDim
                    text: "CPU, GPU, RAM, ping, screenshot, record, mic, power mode, volume and brightness over your game" }
            }
            Btn { anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter
                text: "Open"; sym: "open_in_new"; icon: ""; primary: true
                onClicked: Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-gamebar\" open"]) }
        }

        SectionTitle { text: "While you play"; sub: "What stays on in gaming mode." }
        ToggleRow { label: "Keep blur & transparency"; desc: "Off: everything is solid while you play (faster)"; checked: page.fxOpt("keep_blur"); onToggled: function(v) { page.setOpt("keep_blur", v) } }
        ToggleRow { label: "Keep animations"; desc: "Windows and workspaces still animate"; checked: page.fxOpt("keep_anim"); onToggled: function(v) { page.setOpt("keep_anim", v) } }
        ToggleRow { label: "Keep shadows"; desc: "Shadows under windows"; checked: page.fxOpt("keep_shadows"); onToggled: function(v) { page.setOpt("keep_shadows", v) } }
        ToggleRow { label: "Keep gaps"; desc: "Space between windows and around the screen"; checked: page.fxOpt("keep_gaps"); onToggled: function(v) { page.setOpt("keep_gaps", v) } }
        ToggleRow { label: "Do Not Disturb"; desc: "No notification popups while gaming mode is on"; checked: page.fxOpt("dnd"); onToggled: function(v) { page.setOpt("dnd", v) } }
        ToggleRow { label: "Dashboard at the bottom edge"; desc: "Off: the pointer at the bottom of the screen does not open the dashboard while you play"; checked: page.fxOpt("edge"); onToggled: function(v) { page.setOpt("edge", v) } }

        SectionTitle { text: "Performance"; sub: "For laptops and older computers, also when you are not playing." }
        ToggleRow { label: "Light mode"; desc: "The visualizer stops and widgets rest while a window covers them"; checked: page.fx.lite === true; onToggled: function(v) { page.setLite(v) } }
        SegRow {
            visible: page.havePP
            label: "Power mode"
            desc: "power-profiles-daemon: battery life or speed"
            options: [{ label: "Saver", value: "power-saver" }, { label: "Balanced", value: "balanced" }, { label: "Performance", value: "performance" }]
            current: page.profile
            onChosen: function(x) { page.setProfile(x) }
        }

        SectionTitle { text: "Your launchers"; sub: page.found.length ? "Open them from here." : "No game launcher found (Steam, Heroic, Lutris, Prism, Bottles ...)." }
        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: page.found
                delegate: Rectangle {
                    width: 128; height: 112; radius: M3.rL
                    color: lm.containsMouse ? M3.surfaceHigh : M3.surfaceC
                    scale: lm.pressed ? 0.95 : 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 18
                        width: 44; height: 44; sourceSize.width: 88; sourceSize.height: 88
                        source: Quickshell.iconPath(modelData.e.icon || "applications-games", true)
                        scale: lm.containsMouse ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    }
                    T { anchors.horizontalCenter: parent.horizontalCenter; y: 74; width: parent.width - 16; horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight; text: modelData.n; font.pixelSize: 13; font.weight: Font.Medium }
                    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { modelData.e.execute(); page.ctl.status = "Opening " + modelData.n } }
                }
            }
        }

        SectionTitle { text: "Tools"; sub: "Gaming helpers on this computer." }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: [
                    { k: "gamemoded", n: "GameMode", d: "CPU and GPU boost while a game runs" },
                    { k: "mangohud", n: "MangoHud", d: "FPS and temperatures in games" },
                    { k: "gamescope", n: "Gamescope", d: "Game window with its own resolution" },
                    { k: "steam", n: "Steam", d: "Proton for Windows games" },
                    { k: "wine", n: "Wine", d: "Windows programs" }
                ]
                delegate: Rectangle {
                    readonly property bool ok: page.tools[modelData.k] === true
                    width: tr.implicitWidth + 30; height: 40; radius: 20
                    color: ok ? M3.secondaryContainer : "transparent"
                    border.width: ok ? 0 : 1
                    border.color: M3.outlineVariant
                    Row {
                        id: tr
                        anchors.centerIn: parent
                        spacing: 8
                        T { kind: "icon"; text: parent.parent.ok ? "" : ""; font.pixelSize: 11; color: parent.parent.ok ? M3.primary : M3.inkDim; anchors.verticalCenter: parent.verticalCenter }
                        T { text: modelData.n; font.pixelSize: 13; color: parent.parent.ok ? M3.inkSecondaryC : M3.inkDim; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
        T { kind: "reading"; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 11; color: M3.inkDim; topPadding: 4
            text: "Missing ones can be installed with your package manager (gamemode, mangohud, gamescope)." }
    }
}
