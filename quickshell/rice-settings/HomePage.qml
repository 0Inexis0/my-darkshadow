import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
    id: page
    property var ctl
    // the "Make it yours" cards (the Settings tour points at them)
    property alias quickArea: quick

    readonly property string home: Quickshell.env("HOME")
    readonly property string user: Quickshell.env("USER")
    readonly property string faceUrl: "file://" + home + "/.face"
    property date now: new Date()
    property string uptime: ""
    property int tip: 0
    readonly property var tips: [
        "Press SUPER + U anywhere to open these settings.",
        "SUPER + W opens the wallpaper menu. The Auto theme follows your new wallpaper.",
        "Drag the desktop widgets anywhere, their position is saved.",
        "Pick a scheme in Theme to recolor the bar, borders, notifications and lock screen.",
        "Try the One island bar style in Waybar for a floating look.",
        "Idle & Lockscreen decides when the screen locks and when the computer sleeps.",
        "Click your picture in the sidebar to change it. It is also shown on the lock screen.",
        "Touch the bottom-right corner of the screen for quick toggles, apps and wallpapers.",
        "Type right away in the hot corner's Apps search and press Enter to launch.",
        "Keep Awake in the hot corner stops the screen from locking during a movie.",
        "Gaming mode turns off animations, blur and gaps. Click it again to bring them back.",
        "Notifications has nine popup styles. Try Island or Accent bar.",
        "Theme has 21 color schemes, from pure Mono to Ocean and Rose.",
        "Rofi can open as a full-width bar at the bottom of the screen.",
        "Lock screen clocks come in Big, Stacked and Minimal. Preview them in Idle & Lockscreen.",
        "Run rice-notify test in a terminal to see a sample notification.",
        "Everything here is also a command: waybar-set, rice-hotcorner, rice-lock, rice-notify."
    ]
    function greeting() {
        const h = now.getHours()
        return h < 5 ? "Good night" : (h < 12 ? "Good morning" : (h < 18 ? "Good afternoon" : "Good evening"))
    }
    function themeName() {
        const l = page.ctl.schemes || []
        for (let i = 0; i < l.length; i++) if (l[i].key === page.ctl.colorMode) return l[i].name
        return page.ctl.colorMode
    }

    // Light mode (rice-effects lite): for slower computers
    property bool lite: false
    function setLite(on) {
        lite = on
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-effects\" lite \"$1\"", "_", on ? "on" : "off"])
        page.ctl.status = "Light mode " + (on ? "on" : "off")
    }
    Process {
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-effects\" state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.lite = JSON.parse(text).lite === true } catch (e) { } } }
    }

    // Profiles: the power mode of this computer (power-profiles-daemon). Only the modes this computer has are shown.
    property string profile: ""
    property var profiles: []
    function readProfile() { if (!profProc.running) profProc.running = true }
    function setProfile(k) {
        profile = k
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-services\" profile \"$1\"", "_", k])
        profSoon.restart()
        page.ctl.status = "Profile: " + k.replace("power-saver", "Power saver").replace("balanced", "Balanced").replace("performance", "Performance")
    }
    Timer { id: profSoon; interval: 900; onTriggered: page.readProfile() }
    Process {
        id: profProc
        command: ["bash", "-c", "command -v powerprofilesctl >/dev/null || exit 0; powerprofilesctl list 2>/dev/null | grep -oE '^[* ] *(power-saver|balanced|performance):' | tr -d '*: '; echo CUR; powerprofilesctl get 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("CUR")
                page.profiles = parts[0].split("\n").map(function(x) { return x.trim() }).filter(function(x) { return x.length > 0 })
                page.profile = parts.length > 1 ? parts[1].trim() : ""
            }
        }
    }

    Timer { interval: 15000; running: true; repeat: true; onTriggered: page.now = new Date() }
    Timer { interval: 7000; running: true; repeat: true; onTriggered: tipFade.restart() }
    Process {
        id: upProc
        command: ["bash", "-c", "cut -d. -f1 /proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text.trim())
                if (isNaN(t)) return
                const d = Math.floor(t / 86400), h = Math.floor(t % 86400 / 3600), m = Math.floor(t % 3600 / 60)
                page.uptime = (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m"
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: upProc.running = true }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Behavior on contentY {
            enabled: !flick.dragging && !flick.flicking
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(e) {
                const max = Math.max(0, flick.contentHeight - flick.height)
                flick.contentY = Math.max(0, Math.min(max, flick.contentY - e.angleDelta.y * Prefs.wheel))
            }
        }

        Column {
            id: col
            x: 24
            y: 28
            width: flick.width - 48
            spacing: 12

            // the logo, moving: the moon floats and sways, the stars twinkle (your picture is in the sidebar)
            MoonLogo {
                id: homeLogo
                objectName: "homeLogo"
                anchors.horizontalCenter: parent.horizontalCenter
                size: 136
                running: page.visible
            }

            T {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.greeting() + ", " + page.user
                font.pixelSize: 26
                font.bold: true
            }
            T {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.now.toLocaleDateString(Qt.locale("en_US"), "dddd, d MMMM") + "  \u00b7  " + page.now.toLocaleTimeString(Qt.locale("en_US"), "HH:mm")
                color: "#8a8a8a"
                font.pixelSize: 13
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                topPadding: 2
                bottomPadding: 6
                Repeater {
                    model: [
                        { i: "\udb80\udfd8", t: "Theme \u00b7 " + page.themeName() },
                        { i: "\uf017", t: "Up " + page.uptime },
                        { i: page.ctl.osGlyph(), t: page.ctl.osName }
                    ]
                    delegate: Rectangle {
                        visible: modelData.t.length > 3
                        height: 30
                        width: chip.implicitWidth + 26
                        radius: 15
                        color: "#141414"
                        border.width: 1
                        border.color: "#222222"
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 7
                            T { kind: "icon"; text: modelData.i; font.pixelSize: 12; color: "#c8c8cc"; anchors.verticalCenter: parent.verticalCenter }
                            T { text: modelData.t; font.pixelSize: 12; color: "#c8c8cc"; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 84
                radius: 16
                border.width: 1
                border.color: "#222222"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#1a1922" }
                    GradientStop { position: 1; color: "#121214" }
                }
                Rectangle {
                    id: bulb
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46; height: 46; radius: 14
                    color: Qt.rgba(1, 1, 1, 0.06)
                    T { kind: "icon"; anchors.centerIn: parent; text: "\uf0eb"; font.pixelSize: 20 }
                }
                Column {
                    id: tipCol
                    anchors.left: bulb.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    T { text: "Make yourself at home"; font.pixelSize: 14; font.bold: true }
                    T { kind: "reading"; width: parent.width; text: page.tips[page.tip]; color: "#9a9aa4"; font.pixelSize: 12; wrapMode: Text.WordWrap }
                }
                SequentialAnimation {
                    id: tipFade
                    NumberAnimation { target: tipCol; property: "opacity"; to: 0; duration: 220 }
                    ScriptAction { script: page.tip = (page.tip + 1) % page.tips.length }
                    NumberAnimation { target: tipCol; property: "opacity"; to: 1; duration: 320 }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tipFade.restart() }
            }

            // Light mode: one switch for slower computers, right on Home
            Rectangle {
                // found by the search in the sidebar
                property string label: "Light mode"
                property string desc: "Running slow? Turn off blur, transparency and shadows, animations stay; performance"
                property real reserved: 80
                width: parent.width
                height: 76
                radius: 14
                color: "#141414"
                border.width: 1
                border.color: page.lite ? "#4a4a4f" : "#1f1f1f"
                Behavior on border.color { ColorAnimation { duration: 160 } }
                Rectangle {
                    id: litei
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 12
                    color: Qt.rgba(1, 1, 1, page.lite ? 0.14 : 0.06)
                    T { kind: "icon"; anchors.centerIn: parent; text: "\uf0e7"; font.pixelSize: 17 }
                }
                Column {
                    anchors.left: litei.right
                    anchors.leftMargin: 12
                    anchors.right: litetog.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    T { text: "Light mode"; font.pixelSize: 13; font.bold: true }
                    T { kind: "reading"; text: "Running slow? No blur or shadows, widgets rest when a window covers them. Animations stay"; color: "#8a8a8a"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                }
                Tog {
                    id: litetog
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    checked: page.lite
                    onToggled: function(v) { page.setLite(v) }
                }
            }

            // Auto-hide widgets: the desktop widgets rest while a window covers the screen
            Rectangle {
                property string label: "Auto-hide widgets"
                property string desc: "Hide the desktop widgets while a window covers the screen; floating windows leave them alone"
                property real reserved: 80
                readonly property bool on: page.ctl.dst.autoHide === true || page.lite
                width: parent.width
                height: 76
                radius: 14
                color: "#141414"
                border.width: 1
                border.color: on ? "#4a4a4f" : "#1f1f1f"
                Behavior on border.color { ColorAnimation { duration: 160 } }
                Rectangle {
                    id: ahi
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 12
                    color: Qt.rgba(1, 1, 1, parent.on ? 0.14 : 0.06)
                    T { kind: "icon"; anchors.centerIn: parent; text: parent.parent.on ? "\uf070" : "\uf06e"; font.pixelSize: 17 }
                }
                Column {
                    anchors.left: ahi.right
                    anchors.leftMargin: 12
                    anchors.right: ahtog.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    T { text: "Auto-hide widgets"; font.pixelSize: 13; font.bold: true }
                    T { kind: "reading"; text: page.lite ? "On while Light mode is on" : "Widgets hide while a window covers the screen, and come back on an empty desktop"; color: "#8a8a8a"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                }
                Tog {
                    id: ahtog
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    checked: parent.on
                    onToggled: function(v) { page.ctl.setAutoHide(v) }
                }
            }

            // the falling stars across this window
            Rectangle {
                property string label: "Falling stars"
                property string desc: "Comets falling across this window; turn them off for a calm look"
                property real reserved: 80
                width: parent.width
                height: 64
                radius: 14
                color: "#141414"
                border.width: 1
                border.color: "#1f1f1f"
                Rectangle {
                    id: starsi
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36; height: 36; radius: 11
                    color: Qt.rgba(1, 1, 1, page.ctl.stars ? 0.12 : 0.06)
                    T { kind: "icon"; anchors.centerIn: parent; text: "\uf005"; font.pixelSize: 15 }
                }
                Column {
                    anchors.left: starsi.right
                    anchors.leftMargin: 12
                    anchors.right: starstog.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    T { text: "Falling stars"; font.pixelSize: 13; font.bold: true }
                    T { kind: "reading"; text: "Comets falling across this window"; color: "#8a8a8a"; font.pixelSize: 11; width: parent.width; elide: Text.ElideRight }
                }
                Tog {
                    id: starstog
                    anchors.right: parent.right; anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    checked: page.ctl.stars
                    onToggled: function(v) { page.ctl.setStars(v) }
                }
            }

            T { kind: "title"; text: "Make it yours"; font.pixelSize: 16; font.bold: true; topPadding: 10 }

            Flow {
                id: quick
                width: parent.width
                spacing: 10
                Repeater {
                    model: [
                        { i: "\udb80\udfd8", t: "Theme", d: "Colors & schemes", p: 8 },
                        { i: "\uf03e", t: "Wallpaper", d: "Pick a new one", p: -1 },
                        { i: "\uf0f3", t: "Notifications", d: "Popups & panel", p: 10 },
                        { i: "\uf023", t: "Lock screen", d: "Idle & lock", p: 11 },
                        { i: "\uf0c9", t: "Waybar", d: "Bar layout & style", p: 2 },
                        { i: "\uf002", t: "Rofi", d: "App launcher", p: 7 }
                    ]
                    delegate: Rectangle {
                        width: (quick.width - 20) / 3
                        height: 76
                        radius: 14
                        color: qMouse.containsMouse ? "#1b1b1d" : "#141414"
                        border.width: 1
                        border.color: qMouse.containsMouse ? "#333333" : "#1f1f1f"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle {
                            id: qi
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 40; radius: 12
                            color: Qt.rgba(1, 1, 1, 0.06)
                            T { kind: "icon"; anchors.centerIn: parent; text: modelData.i; font.pixelSize: 17 }
                        }
                        Column {
                            anchors.left: qi.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            T { text: modelData.t; font.pixelSize: 13; font.bold: true; width: parent.width; elide: Text.ElideRight }
                            T { kind: "reading"; text: modelData.d; font.pixelSize: 11; color: "#8a8a8a"; width: parent.width; elide: Text.ElideRight }
                        }
                        MouseArea {
                            id: qMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.p >= 0) page.ctl.page = modelData.p
                                else Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-wallpaper\""])
                            }
                        }
                    }
                }
            }

            SectionTitle { text: "Settings"; sub: "The things you change most. They apply right away." }

            // Profiles: Performance, Balanced, Power saver
            Item {
                id: profBox
                width: parent.width
                height: page.profiles.length > 0 ? 120 : 64
                Row {
                    id: profHead
                    spacing: 8
                    T { text: "Profiles"; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    T { kind: "reading"; text: page.profiles.length > 0 ? "How fast this computer runs, and how much power it uses" : ""; color: "#8a8a8a"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    visible: page.profiles.length > 0
                    y: 28
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: [
                            { k: "performance", i: "\udb81\udcc5", t: "Performance", d: "Fastest, uses more power" },
                            { k: "balanced", i: "\udb81\uddd1", t: "Balanced", d: "Good for everyday use" },
                            { k: "power-saver", i: "\udb80\udf2a", t: "Power saver", d: "Quiet, longest battery" }
                        ].filter(function(m) { return page.profiles.indexOf(m.k) >= 0 })
                        delegate: Rectangle {
                            id: pc
                            readonly property bool on: page.profile === modelData.k
                            width: (profBox.width - 10 * (page.profiles.length - 1)) / Math.max(1, page.profiles.length)
                            height: 84
                            radius: 14
                            color: on ? "#F6F5F4" : (pMouse.containsMouse ? "#1b1b1d" : "#141414")
                            border.width: 1
                            border.color: on ? "#F6F5F4" : (pMouse.containsMouse ? "#333333" : "#1f1f1f")
                            Behavior on color { ColorAnimation { duration: 160 } }
                            Rectangle {
                                id: pi
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42; height: 42; radius: 13
                                color: pc.on ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.06)
                                T { kind: "icon"; anchors.centerIn: parent; text: modelData.i; font.pixelSize: 19; color: pc.on ? "#0d0d0d" : "#F6F5F4" }
                            }
                            Column {
                                anchors.left: pi.right
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                T { text: modelData.t; font.pixelSize: 14; font.bold: true; color: pc.on ? "#0d0d0d" : "#F6F5F4"; width: parent.width; elide: Text.ElideRight }
                                T { kind: "reading"; text: modelData.d; font.pixelSize: 11; color: pc.on ? "#3a3a3e" : "#8a8a8a"; width: parent.width; elide: Text.ElideRight }
                            }
                            MouseArea {
                                id: pMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.setProfile(modelData.k)
                            }
                        }
                    }
                }
                T {
                    visible: page.profiles.length === 0
                    y: 26
                    width: parent.width
                    wrapMode: Text.WordWrap
                    kind: "reading"
                    font.pixelSize: 12
                    color: "#8a8a8a"
                    text: "Power modes need power-profiles-daemon, and it is not running on this computer. Install it and turn it on: sudo systemctl enable --now power-profiles-daemon (on NixOS: services.power-profiles-daemon.enable = true)."
                }
            }

            SliderRow {
                id: sizeRow
                label: "Window size"
                desc: "Make this Settings window smaller or bigger"
                from: 75; to: 150; step: 5; unit: " %"
                value: Math.round(Prefs.size * 100)
                onCommitted: function(v) { Prefs.setSize(v / 100) }
            }

            // preview: the screen, and this Settings window on it, as big as the slider says (moves while you drag)
            Rectangle {
                id: szPrev
                width: parent.width
                height: 168
                radius: 12
                color: "#141414"
                border.width: 1
                border.color: "#1f1f1f"
                readonly property var scr: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
                readonly property real sw: scr ? scr.width : 1920
                readonly property real sh: scr ? scr.height : 1080
                readonly property real k: sizeRow.shown / 100
                readonly property real ww: Prefs.winW(sw, k)
                readonly property real wh: Prefs.winH(sh, k)

                Rectangle {
                    id: mon
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 136
                    width: Math.min(260, Math.round(height * szPrev.sw / szPrev.sh))
                    radius: 6
                    color: "#0b0b0d"
                    border.width: 2
                    border.color: "#3a3a40"
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1b1b24" }
                        GradientStop { position: 1.0; color: "#0e0e12" }
                    }
                    // the bar
                    Rectangle { x: 0; y: 0; width: parent.width; height: 5; color: "#26262c" }
                    // the Settings window
                    Rectangle {
                        id: miniWin
                        width: Math.round(mon.width * szPrev.ww / szPrev.sw)
                        height: Math.round(mon.height * szPrev.wh / szPrev.sh)
                        x: Math.round((mon.width - width) / 2)
                        y: Math.round((mon.height - height) / 2)
                        radius: 4
                        color: "#141414"
                        border.width: 1
                        border.color: "#8a8a92"
                        Rectangle { x: 0; y: 0; width: Math.round(parent.width * 0.26); height: parent.height; color: "#1c1c1f"; radius: 4 }
                        Repeater {
                            model: 5
                            Rectangle {
                                x: 4; y: 8 + index * 9
                                width: Math.round(miniWin.width * 0.26) - 8
                                height: 4; radius: 2
                                color: index === 0 ? "#F6F5F4" : "#3a3a40"
                            }
                        }
                        Repeater {
                            model: 4
                            Rectangle {
                                x: Math.round(miniWin.width * 0.26) + 6
                                y: 8 + index * Math.round(miniWin.height * 0.2)
                                width: Math.round(miniWin.width * 0.74) - 12
                                height: Math.max(6, Math.round(miniWin.height * 0.14)); radius: 3
                                color: "#202024"
                            }
                        }
                        Behavior on width { enabled: !sizeRow.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on height { enabled: !sizeRow.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                }
                Column {
                    anchors.left: mon.right
                    anchors.leftMargin: 20
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    T { text: Math.round(szPrev.ww) + " \u00d7 " + Math.round(szPrev.wh) + " px"; font.pixelSize: 20; font.bold: true }
                    T { kind: "reading"; text: Math.round(szPrev.ww * 100 / szPrev.sw) + " % of the screen width, " + Math.round(szPrev.wh * 100 / szPrev.sh) + " % of its height"; color: "#8a8a8a"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                    T { kind: "reading"; text: "Preview: the small window follows the slider. It is applied when you let go."; color: "#6a6a72"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                }
            }

            ToggleRow {
                label: "Bar transparency"
                desc: "Translucent bar with blur; off makes it solid"
                checked: page.ctl.st.transparent === true
                onToggled: function(v) {
                    page.ctl.setSt("transparent", v)
                    page.ctl.run(["transparency", v ? "on" : "off"])
                }
            }
            ToggleRow {
                label: "Window blur"
                desc: "Blur behind the bar, notifications and see-through windows"
                checked: page.ctl.hv["decoration.blur.enabled"] !== false
                onToggled: function(v) { page.ctl.hset("decoration.blur.enabled", v) }
            }
            ToggleRow {
                label: "Animations"
                desc: "Windows and workspaces move smoothly. Off is the lightest"
                checked: page.ctl.ha.enabled !== false
                onToggled: function(v) { page.ctl.setAnim("enabled", v) }
            }

            SectionTitle { text: "Previews"; sub: "The live pictures at the top of some pages." }
            ToggleRow {
                label: "Show previews"
                desc: "Bar, Launcher, Notifications, Dashboard and Cursors show a small live picture of your choices"
                checked: Prefs.previews
                onToggled: function(v) { Prefs.setPreviews(v) }
            }

            SectionTitle { text: "Scrolling"; sub: "How fast pages move. Try it in the box." }

            SliderRow {
                label: "Settings scroll speed"
                desc: "Wheel and touchpad scrolling in this window"
                from: 0.3; to: 3; step: 0.05; decimals: 2; unit: "x"
                value: Prefs.scroll
                onCommitted: function(v) { Prefs.setScroll(v) }
            }
            // a small place to feel the speed
            Rectangle {
                width: parent.width
                height: 128
                radius: 12
                color: "#141414"
                border.width: 1
                border.color: "#1f1f1f"
                Column {
                    x: 16; y: 14
                    width: 190
                    spacing: 4
                    T { text: "Try it"; font.pixelSize: 14 }
                    T { kind: "reading"; text: "Scroll in the box. The speed above changes how far one notch goes."; color: "#8a8a8a"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                }
                Rectangle {
                    x: 226; y: 12
                    width: parent.width - 226 - 14
                    height: parent.height - 24
                    radius: 9
                    color: "#0e0e0f"
                    border.width: 1
                    border.color: "#1c1c1e"
                    clip: true
                    Flickable {
                        id: tryFlick
                        anchors.fill: parent
                        anchors.margins: 1
                        contentWidth: width
                        contentHeight: tryCol.height + 12
                        boundsBehavior: Flickable.StopAtBounds
                        Behavior on contentY { enabled: !tryFlick.dragging && !tryFlick.flicking; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(e) {
                                const max = Math.max(0, tryFlick.contentHeight - tryFlick.height)
                                tryFlick.contentY = Math.max(0, Math.min(max, tryFlick.contentY - e.angleDelta.y * Prefs.wheel))
                            }
                        }
                        Column {
                            id: tryCol
                            x: 10; y: 6
                            width: parent.width - 28
                            Repeater {
                                model: 40
                                delegate: Rectangle {
                                    width: tryCol.width; height: 26; radius: 6
                                    color: index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.035) : "transparent"
                                    T { x: 8; anchors.verticalCenter: parent.verticalCenter; text: "Line " + (index + 1); font.pixelSize: 12; color: "#9a9aa2" }
                                }
                            }
                        }
                    }
                    // where you are
                    Rectangle {
                        x: parent.width - 6; width: 3; radius: 1.5
                        y: 4 + (parent.height - 8 - height) * (tryFlick.contentHeight > tryFlick.height ? tryFlick.contentY / (tryFlick.contentHeight - tryFlick.height) : 0)
                        height: Math.max(16, (parent.height - 8) * tryFlick.height / Math.max(1, tryFlick.contentHeight))
                        color: "#5a5a60"
                    }
                }
            }

            SectionTitle { text: "Mouse & touchpad"; sub: "System-wide, for every app." }

            SliderRow {
                label: "Mouse wheel speed"
                desc: "How far one notch scrolls, everywhere"
                from: 0.2; to: 3; step: 0.1; decimals: 1; unit: "x"
                value: page.ctl.hv["input.scroll_factor"] !== undefined ? page.ctl.hv["input.scroll_factor"] : 1
                onCommitted: function(v) { page.ctl.hset("input.scroll_factor", Math.round(v * 10) / 10) }
            }
            SliderRow {
                label: "Touchpad scroll speed"
                desc: "Two-finger scrolling, everywhere"
                from: 0.2; to: 3; step: 0.1; decimals: 1; unit: "x"
                value: page.ctl.hv["input.touchpad.scroll_factor"] !== undefined ? page.ctl.hv["input.touchpad.scroll_factor"] : 1
                onCommitted: function(v) { page.ctl.hset("input.touchpad.scroll_factor", Math.round(v * 10) / 10) }
            }
            ToggleRow {
                label: "Natural scrolling"
                desc: "Touchpad: content follows your fingers, like a phone"
                checked: page.ctl.hv["input.touchpad.natural_scroll"] === true
                onToggled: function(v) { page.ctl.hset("input.touchpad.natural_scroll", v) }
            }
            ToggleRow {
                label: "Tap to click"
                desc: "Touchpad: a light tap is a click"
                checked: page.ctl.hv["input.touchpad.tap-to-click"] !== false
                onToggled: function(v) { page.ctl.hset("input.touchpad.tap-to-click", v) }
            }
            SliderRow {
                label: "Pointer speed"
                desc: "How fast the cursor moves"
                from: -1; to: 1; step: 0.05; decimals: 2
                value: page.ctl.hv["input.sensitivity"] !== undefined ? page.ctl.hv["input.sensitivity"] : 0
                onCommitted: function(v) { page.ctl.hset("input.sensitivity", Math.round(v * 20) / 20) }
            }
        }
    }
}