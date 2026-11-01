import Quickshell
import Quickshell.Io
import QtQuick

FloatingWindow {
    id: win
    title: "Rice Settings"
    implicitWidth: 980
    implicitHeight: 790
    color: "transparent"
    visible: true
    onVisibleChanged: if (!visible) Qt.quit()

    readonly property string home: Quickshell.env("HOME")
    readonly property string presetTool: home + "/.local/bin/waybar-preset"
    property int page: 0
    property var presets: []
    property var st: ({})
    property string status: ""
    property string colorMode: "auto"
    property alias stateTimer: stateTimer
    property var dst: ({ widgets: {}, clock: {}, dock: {}, lock: {} })
    property string osName: "Linux"
    property var osIds: ["linux"]
    // distro logo from the Nerd Font "font logos" set (NixOS logo on NixOS, Arch logo on Arch, ...)
    readonly property var osGlyphs: ({
        nixos: "\uf313", arch: "\uf303", archarm: "\uf303", cachyos: "\uf385", endeavouros: "\uf322", manjaro: "\uf312",
        garuda: "\uf303", ubuntu: "\uf31b", fedora: "\uf30a", nobara: "\uf380", bazzite: "\uf30a", ultramarine: "\uf30a", debian: "\uf306", opensuse: "\uf314", gentoo: "\uf30d",
        void: "\uf32e", alpine: "\uf300", linuxmint: "\uf30e", pop: "\uf32a"
    })
    function osGlyph() {
        for (let i = 0; i < osIds.length; i++) if (osGlyphs[osIds[i]] !== undefined) return osGlyphs[osIds[i]]
        return "\uf17c"
    }
    readonly property string userName: Quickshell.env("USER")
    // rice-effects: blur and transparency are off right now
    property bool flat: false
    Process {
        id: flatProc
        command: ["bash", "-c", "[ -e \"$HOME/.cache/rice/flat\" ] && echo 1 || echo 0"]
        running: true
        stdout: StdioCollector { onStreamFinished: win.flat = text.trim() === "1" }
    }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: if (!flatProc.running) flatProc.running = true }

    function dset(group, key, value) {
        const d = JSON.parse(JSON.stringify(dst))
        if (group === "widget") {
            if (!d.widgets[key]) d.widgets[key] = {}
            d.widgets[key].enabled = (value === "on")
        } else {
            if (!d[group]) d[group] = {}
            d[group][key] = (value === "on" || value === "off") ? (value === "on") : value
        }
        dst = d
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" \"$@\"", "_", group, key, String(value)])
        status = "Applied"
        drefresh.restart()
    }

    function dreset() {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" reset-pos"])
        status = "Widget positions reset"
        drefresh.restart()
    }

    Process {
        id: dstate
        command: ["bash", "-c", "\"$HOME/.local/bin/desktop-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { win.dst = JSON.parse(text) } catch (e) { } }
        }
    }
    Timer { id: drefresh; interval: 900; onTriggered: dstate.running = true }

    Process {
        id: osProc
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; printf '%s\\n%s\\n%s\\n' \"${NAME:-Linux}\" \"${ID:-linux}\" \"${ID_LIKE:-}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("\n")
                if (p[0] && p[0].trim().length > 0) win.osName = p[0].trim()
                win.osIds = ((p[1] || "") + " " + (p[2] || "")).trim().toLowerCase().split(/\s+/)
            }
        }
    }

    readonly property var pages: [
        { name: "Home", icon: "\uf015" },
        { name: "Waybar", icon: "\uf0c9" },
        { name: "Bar layout", icon: "\uf0db" },
        { name: "Hyprland", icon: "\uf108" },
        { name: "Dashboard", icon: "\uf009" },
        { name: "Rofi", icon: "\uf002" },
        { name: "Theme", icon: "\udb80\udfd8" },
        { name: "Cursors", icon: "\uf245" },
        { name: "Notifications", icon: "\uf0f3" },
        { name: "Idle & Lockscreen", icon: "\uf023" },
        { name: "Desktop", icon: "\uf26c" },
        { name: "Hot corners", icon: "\udb82\ude0b" },
        { name: "Interface", icon: "\uf2d0" },
        { name: "Services", icon: "" }
    ]

    readonly property string hyprTool: home + "/.local/bin/hypr-set"
    property var hv: ({})
    property var hb: ({ mode: "wallpaper", active: "#F6F5F4", inactive: "#444444" })
    property var ha: ({ enabled: true, speed: 100 })

    function hrun(args, msg) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/hypr-set\" \"$@\"", "_"].concat(args.map(a => String(a))))
        if (msg) status = msg
        hrefresh.restart()
    }

    function hset(key, value) {
        const v = Object.assign({}, hv)
        v[key] = value
        hv = v
        hrun(["set", key, String(value)], "Applied")
    }

    function setBorderMode(m) {
        const b = Object.assign({}, hb)
        b.mode = m
        hb = b
        hrun(["border-mode", m], "Borders: " + m)
    }

    function setBorderColor(which, hex) {
        const b = Object.assign({}, hb)
        b[which] = hex
        hb = b
        hrun(["border-color", which, hex], "Border color set")
    }

    function setAnim(k, v) {
        const a = Object.assign({}, ha)
        a[k] = v
        ha = a
        hrun([k === "enabled" ? "anim-enabled" : "anim-speed", k === "enabled" ? (v ? "on" : "off") : v], "Applied")
    }

    function setSt(key, value) {
        const s = Object.assign({}, st)
        s[key] = value
        st = s
    }

    function run(args) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/waybar-set\" \"$@\" && \"$HOME/.local/bin/waybar-reload\"", "_"].concat(args.map(a => String(a))))
        status = "Applied"
        stateTimer.restart()
    }

    function toggleModule(name, on) {
        setSt(name, on)
        run(["toggle", name, on ? "on" : "off"])
    }

    function setColorMode(m) {
        colorMode = m
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-colors\" mode \"$1\"", "_", m])
        let nm = m
        for (let i = 0; i < schemes.length; i++) if (schemes[i].key === m) nm = schemes[i].name
        status = "Colors: " + nm + " (applying...)"
    }

    Process {
        id: lister
        command: ["bash", "-c", "ls -1 \"$HOME/.config/waybar-presets\" 2>/dev/null | grep -v '^_'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: win.presets = text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
        }
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/waybar-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { win.st = JSON.parse(text) } catch (e) { } }
        }
    }

    property var schemes: []
    Process {
        id: schemeProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-colors\" list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { win.schemes = JSON.parse(text) } catch (e) { } }
        }
    }

    Process {
        id: modeProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-colors\" get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { const m = text.trim(); if (m.length > 0) win.colorMode = m }
        }
    }

    Process {
        id: hstate
        command: ["bash", "-c", "\"$HOME/.local/bin/hypr-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j.opts) win.hv = j.opts
                    if (j.borders) win.hb = j.borders
                    if (j.anim) win.ha = j.anim
                } catch (e) { }
            }
        }
    }

    Timer { id: hrefresh; interval: 800; onTriggered: hstate.running = true }

    Timer {
        id: stateTimer
        interval: 900
        onTriggered: { lister.running = true; stateProc.running = true }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        // solid while blur and transparency are off (Settings > Services, or gaming mode); the stars stay
        color: Qt.rgba(0.05, 0.05, 0.05, win.flat ? 1 : 0.72)
        Behavior on color { ColorAnimation { duration: 300 } }
        focus: true
        Keys.onEscapePressed: Qt.quit()
        NumberAnimation on opacity { from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }

        // ---------- you: a bigger profile card on top of the sidebar ----------
        Rectangle {
            id: profile
            x: 16
            y: 12
            width: 206
            height: 74
            radius: 18
            color: pfm.containsMouse ? "#181818" : "#131313"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
            Behavior on color { ColorAnimation { duration: 160 } }
            // soft light in the corner
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.045) }
                    GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
            // avatar with a ring (your initial when there is no ~/.face)
            Item {
                id: av
                z: 2            // above the card's click area, so the picture can be clicked on its own
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 52
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#F6F5F4" }
                        GradientStop { position: 1; color: "#5a5a60" }
                    }
                    rotation: pfm.containsMouse ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: width / 2
                    color: "#1c1c1c"
                    T { anchors.centerIn: parent; text: win.userName.length ? win.userName[0].toUpperCase() : "?"; font.pixelSize: 20; font.bold: true }
                }
                RoundImage {
                    id: avImg
                    anchors.fill: parent
                    anchors.margins: 3
                    source: "file://" + win.home + "/.face"
                }
                // click the picture: choose a new one (it is also on the lock screen)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    opacity: avm.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    T { anchors.centerIn: parent; kind: "icon"; text: "\uf030"; font.pixelSize: 15 }
                }
                MouseArea {
                    id: avm
                    anchors.fill: parent
                    z: 5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: facePicker.running = true
                }
                scale: pfm.containsMouse || avm.containsMouse ? 1.05 : 1
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
            }
            Process {
                id: facePicker
                command: ["zenity", "--file-selection", "--title=Choose a profile picture", "--file-filter=Images | *.png *.jpg *.jpeg *.webp"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const p = text.trim()
                        if (p.length === 0) return
                        Quickshell.execDetached(["bash", "-c", "cp -f \"$1\" \"$HOME/.face\"", "_", p])
                        faceReload.restart()
                    }
                }
            }
            Timer { id: faceReload; interval: 400; onTriggered: { avImg.source = ""; avImg.source = "file://" + win.home + "/.face" } }
            Column {
                anchors.left: av.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                T { kind: "title"; text: win.userName; font.pixelSize: 17; font.bold: true; width: parent.width; elide: Text.ElideRight }
                // distro chip
                Rectangle {
                    width: Math.min(parent.width, osRow.implicitWidth + 16)
                    height: 22
                    radius: 11
                    color: "#222224"
                    Row {
                        id: osRow
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        T { kind: "icon"; text: win.osGlyph(); font.pixelSize: 12; color: "#d8d8dc"; anchors.verticalCenter: parent.verticalCenter }
                        T { text: win.osName; font.pixelSize: 11; color: "#b8b8c0"; anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, profile.width - 110); elide: Text.ElideRight }
                    }
                }
            }
            MouseArea { id: pfm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.page = 0 }
        }
        Rectangle { x: 238; y: 58; width: parent.width - 254; height: 1; color: "#222222" }

        Rectangle {
            id: closeBtn
            width: 30
            height: 30
            radius: 15
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 14
            color: closeMouse.containsMouse ? "#2a2a2a" : "transparent"
            Behavior on color { ColorAnimation { duration: 140 } }
            T { anchors.centerIn: parent; text: "\u00d7"; font.pixelSize: 20 }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.quit()
            }
        }

        // sidebar scrolls when the categories do not fit
        Flickable {
            id: navFlick
            x: 16
            y: 98
            width: 206
            height: parent.height - 98 - 34
            contentWidth: width
            contentHeight: navCol.height + 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Behavior on contentY {
                enabled: !navFlick.dragging && !navFlick.flicking
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    const max = Math.max(0, navFlick.contentHeight - navFlick.height)
                    navFlick.contentY = Math.max(0, Math.min(max, navFlick.contentY - e.angleDelta.y * 0.9))
                }
            }
            // keep the selected category visible
            function reveal() {
                const top = win.page * 56, bottom = top + 46
                if (top < contentY) contentY = top
                else if (bottom > contentY + height) contentY = Math.min(Math.max(0, contentHeight - height), bottom + 8 - height)
            }
            Connections { target: win; function onPageChanged() { navFlick.reveal() } }

            // the selection glides to the new category and stretches a little on the way (Material 3)
            Rectangle {
                id: navSel
                property real target: win.page * 56
                y: target
                width: 206
                height: 46
                radius: 14
                color: "#262626"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)
                Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] } }
                Rectangle {
                    x: 0; anchors.verticalCenter: parent.verticalCenter
                    width: 3; height: 18; radius: 1.5
                    color: "#F6F5F4"
                }
            }

            Column {
                id: navCol
                width: 206
                spacing: 10

                Repeater {
                    model: win.pages
                    delegate: Rectangle {
                        width: parent.width
                        height: 46
                        radius: 14
                        color: win.page !== index && navMouse.containsMouse ? "#1a1a1a" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        T { kind: "icon"; x: 18; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; font.pixelSize: 18
                            color: win.page === index ? "#F6F5F4" : "#a8a8b0"
                            scale: win.page === index ? 1.1 : 1
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 200 } } }
                        T { x: 50; width: parent.width - 58; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; font.pixelSize: 14
                            font.weight: win.page === index ? Font.DemiBold : Font.Normal
                            color: win.page === index ? "#F6F5F4" : "#b8b8c0"
                            Behavior on color { ColorAnimation { duration: 200 } } }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.page = index
                        }
                    }
                }
            }
        }

        Rectangle { x: 232; y: 64; width: 1; height: parent.height - 96; color: "#222222" }

        Item {
            x: 238
            y: 60
            width: parent.width - 238
            height: parent.height - 60
            clip: true

            // falling stars behind every page (they stay put while the pages change)
            StarField { anchors.fill: parent; running: win.visible; opacity: win.page === 0 ? 1 : 0.6; Behavior on opacity { NumberAnimation { duration: 400 } } }

            PageSlot { idx: 0; cur: win.page; HomePage { id: homePage; anchors.fill: parent; ctl: win } }
            PageSlot { idx: 1; cur: win.page; WaybarPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 2; cur: win.page; BarLayoutPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 3; cur: win.page; HyprlandPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 4; cur: win.page; DashboardPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 5; cur: win.page; RofiPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 6; cur: win.page; ThemePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 7; cur: win.page; CursorsPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 8; cur: win.page; NotificationsPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 9; cur: win.page; IdlePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 10; cur: win.page; DesktopPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 11; cur: win.page; HotCornersPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 12; cur: win.page; InterfacePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 13; cur: win.page; ServicesPage { anchors.fill: parent; ctl: win } }
        }

        // ---------- the tour (after the welcome intro, or rice-welcome tour) ----------
        Tour {
            id: tour
            objectName: "tour"
            onFinished: card.forceActiveFocus()
            steps: [
                { title: "You can find anything here!", r: 18,
                  body: "Every part of your desktop has its own page: the bar, the theme, notifications, the lock screen, the dashboard and more.",
                  rect: function() { return { x: navFlick.x - 6, y: navFlick.y - 6, w: navFlick.width + 12, h: Math.min(navFlick.height, navCol.height) + 12 } } },
                { title: "Make it yours", r: 16,
                  body: "Start with the things people change first. Most changes show up right away, and every page has a live preview.",
                  rect: function() {
                      const q = homePage.quickArea, p = q.mapToItem(card, 0, 0)
                      return { x: p.x - 10, y: p.y - 44, w: q.width + 20, h: q.height + 54 }
                  } },
                { title: "This is you", r: 22,
                  body: "Click your picture to change it, it shows on the lock screen too. Click the card to come back here, to Home.",
                  rect: function() { return { x: profile.x - 5, y: profile.y - 5, w: profile.width + 10, h: profile.height + 10 } } },
                { title: "That's it!", r: 20,
                  body: "Close Settings here and open it again any time with SUPER + U. Have fun with your desktop.",
                  rect: function() { return { x: closeBtn.x - 6, y: closeBtn.y - 6, w: closeBtn.width + 12, h: closeBtn.height + 12 } } }
            ]
        }
        Process {
            // the welcome intro leaves this file behind when it opens Settings
            id: tourCheck
            running: true
            command: ["bash", "-c", "f=\"$HOME/.cache/rice/settings-tour\"; [ -e \"$f\" ] && rm -f \"$f\" && echo 1 || echo 0"]
            stdout: StdioCollector { onStreamFinished: if (text.trim() === "1") tourDelay.start() }
        }
        Timer { id: tourDelay; interval: 650; onTriggered: { win.page = 0; tour.start() } }

        T {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 24
            text: win.status
            color: "#8a8a8a"
            font.pixelSize: 12
        }
    }
}