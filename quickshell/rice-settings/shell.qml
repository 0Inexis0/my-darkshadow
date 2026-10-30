import Quickshell
import Quickshell.Io
import QtQuick

FloatingWindow {
    id: win
    title: "Rice Settings"
    implicitWidth: 980
    implicitHeight: 740
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
    readonly property string userName: Quickshell.env("USER")

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
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; echo \"${NAME:-Linux}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { const t = text.trim(); if (t.length > 0) win.osName = t }
        }
    }

    readonly property var pages: [
        { name: "Home", icon: "\uf015" },
        { name: "Waybar", icon: "\uf0c9" },
        { name: "Hyprland", icon: "\uf108" },
        { name: "Rofi", icon: "\uf002" },
        { name: "Theme", icon: "\uf53f" },
        { name: "Notifications", icon: "\uf0f3" },
        { name: "Idle & Lockscreen", icon: "\uf023" },
        { name: "Desktop", icon: "\uf26c" },
        { name: "Interface", icon: "\uf2d0" },
        { name: "Services", icon: "" },
        { name: "About", icon: "" }
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
        color: Qt.rgba(0.05, 0.05, 0.05, 0.72)
        focus: true
        Keys.onEscapePressed: Qt.quit()
        NumberAnimation on opacity { from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }

        Item {
            x: 16
            y: 10
            width: 206
            height: 48

            RoundImage {
                id: hAvatar
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                source: "file://" + win.home + "/.face"
            }
            Column {
                anchors.left: hAvatar.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                T { text: win.userName; font.pixelSize: 14; font.bold: true; width: parent.width; elide: Text.ElideRight }
                T { text: win.osName; font.pixelSize: 11; color: "#8a8a8a"; width: parent.width; elide: Text.ElideRight }
            }
        }
        Rectangle { x: 16; y: 62; width: parent.width - 32; height: 1; color: "#222222" }

        Rectangle {
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

        Rectangle {
            x: 16
            y: 72 + win.page * 56
            width: 206
            height: 46
            radius: 14
            color: "#2a2a2a"
            Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }

        Column {
            x: 16
            y: 72
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
                    T { kind: "icon"; x: 18; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; font.pixelSize: 18 }
                    T { x: 50; width: parent.width - 58; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; font.pixelSize: 14; font.bold: win.page === index }
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

        Rectangle { x: 232; y: 64; width: 1; height: parent.height - 96; color: "#222222" }

        Item {
            x: 238
            y: 60
            width: parent.width - 238
            height: parent.height - 60
            clip: true

            PageSlot { idx: 0; cur: win.page; HomePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 1; cur: win.page; WaybarPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 2; cur: win.page; HyprlandPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 3; cur: win.page; RofiPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 4; cur: win.page; ThemePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 5; cur: win.page; NotificationsPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 6; cur: win.page; IdlePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 7; cur: win.page; DesktopPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 8; cur: win.page; InterfacePage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 9; cur: win.page; ServicesPage { anchors.fill: parent; ctl: win } }
            PageSlot { idx: 10; cur: win.page; AboutPage { anchors.fill: parent; ctl: win } }
        }

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