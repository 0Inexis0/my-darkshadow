import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl
    property var ls: ({})
    property string wall: ""
    property date now: new Date()

    function v(k, d) { return ls[k] !== undefined ? ls[k] : d }
    function norm(value) { return value === "on" ? true : value === "off" ? false : value }
    function setv(key, value) {
        const n = Object.assign({}, ls)
        n[key] = page.norm(value)
        ls = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-lock\" set \"$1\" \"$2\"", "_", key, String(value)])
        page.ctl.status = "Applied"
        refresh.restart()
    }
    function mins(x) { return x <= 0 ? "Never" : (x + " min") }
    // lock screen clock fonts (rice-fonts downloads them)
    readonly property var clockFonts: [
        { k: "default", n: "Default", f: "" },
        { k: "bebas", n: "Bebas Neue", f: "Bebas Neue" },
        { k: "orbitron", n: "Orbitron", f: "Orbitron" },
        { k: "outfit", n: "Outfit", f: "Outfit" },
        { k: "grotesk", n: "Space Grotesk", f: "Space Grotesk" },
        { k: "unbounded", n: "Unbounded", f: "Unbounded" },
        { k: "shoulders", n: "Big Shoulders", f: "Big Shoulders Display" }
    ]
    readonly property var famList: Qt.fontFamilies()
    function hasFam(f) { return f === "" || famList.indexOf(f) >= 0 }
    function clockFam() {
        const k = v("clock_font", "default")
        for (let i = 0; i < clockFonts.length; i++) if (clockFonts[i].k === k && clockFonts[i].f !== "") return clockFonts[i].f
        return Fonts.family("number")
    }
    function greeting() {
        const h = now.getHours()
        return (h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + ", " + Quickshell.env("USER")
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-lock\" state; echo; cat \"$HOME/.cache/hyprquickpaper-current\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("\n")
                try { page.ls = JSON.parse(parts[0]) } catch (e) { }
                page.wall = parts.length > 1 ? parts[1].trim() : ""
            }
        }
    }
    Timer { id: refresh; interval: 800; onTriggered: stateProc.running = true }
    Timer { interval: 20000; running: true; repeat: true; onTriggered: page.now = new Date() }

    PageScroll {
        anchors.fill: parent

        // ---------- lock screen preview (scaled from a 1920x1080 screen) ----------
        Item {
            width: parent.width
            height: pv.height

            Rectangle {
                id: pv
                readonly property real s: height / 1080
                readonly property bool isLeft: page.v("layout", "center") === "left"
                readonly property string st: page.v("clock", "big")
                readonly property string acc: page.v("accent", "#d4d4d4")
                readonly property var ys: st === "stacked" ? ({ avatar: 400, date: 30, greet: -6, input: -96, power: -190 })
                                        : st === "minimal" ? ({ avatar: 150, date: 0, greet: 50, input: -40, power: -140 })
                                        : ({ avatar: 310, date: 66, greet: 30, input: -50, power: -146 })
                function px(w) { return isLeft ? 110 * s : (width - w) / 2 }
                function py(yoff, h) { return height / 2 - yoff * s - h / 2 }
                function hhmm() {
                    const d = page.now
                    let h = d.getHours()
                    if (!page.v("clock_24h", true)) h = h % 12 === 0 ? 12 : h % 12
                    return { h: String(h).padStart(2, "0"), m: String(d.getMinutes()).padStart(2, "0") }
                }

                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width, 560)
                height: Math.round(width * 9 / 16)
                radius: 14
                clip: true
                color: "#0c0c0e"
                border.width: 1
                border.color: "#262626"

                Image {
                    anchors.fill: parent
                    visible: page.v("background", "screenshot") === "wallpaper" && page.wall.length > 0
                    source: visible ? "file://" + page.wall : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 640
                    asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent
                    visible: page.v("background", "screenshot") === "screenshot"
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#2a2f3a" }
                        GradientStop { position: 1; color: "#14161c" }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: page.v("background", "screenshot") === "color" ? 0 : (1 - page.v("dim", 0.5)) * 0.9
                }

                // avatar
                Rectangle {
                    visible: page.v("avatar", true) && page.v("has_face", false)
                    width: 96 * pv.s; height: width; radius: width / 2
                    x: pv.px(width); y: pv.py(pv.ys.avatar, height)
                    color: "#2a2a2a"
                    border.width: 1
                    border.color: pv.acc
                    RoundImage { anchors.fill: parent; anchors.margins: 1; source: "file://" + Quickshell.env("HOME") + "/.face" }
                }
                // clock
                T {
                    visible: pv.st === "big"
                    kind: "number"
                    font.family: page.clockFam()
                    textFormat: Text.StyledText
                    // white hours, grey minutes
                    text: "<b>" + pv.hhmm().h + "</b><font color='" + (page.v("accent_clock", false) ? Qt.darker(pv.acc, 1.6) : "#8c8c8c") + "'>:" + pv.hhmm().m + "</font>"
                    font.pixelSize: 96 * 1.33 * pv.s
                    color: page.v("accent_clock", false) ? pv.acc : "#F6F5F4"
                    x: pv.px(implicitWidth); y: pv.py(160, implicitHeight)
                }
                T {
                    visible: pv.st === "stacked"
                    kind: "number"
                    font.family: page.clockFam()
                    text: pv.hhmm().h
                    font.pixelSize: 120 * 1.33 * pv.s; font.bold: true
                    color: page.v("accent_clock", false) ? pv.acc : "#F6F5F4"
                    x: pv.px(implicitWidth); y: pv.py(250, implicitHeight)
                }
                T {
                    visible: pv.st === "stacked"
                    kind: "number"
                    font.family: page.clockFam()
                    text: pv.hhmm().m
                    font.pixelSize: 120 * 1.33 * pv.s
                    color: page.v("accent_clock", false) ? pv.acc : "#F6F5F4"
                    opacity: 0.55
                    x: pv.px(implicitWidth); y: pv.py(118, implicitHeight)
                }
                T {
                    visible: pv.st === "minimal"
                    kind: "number"
                    font.family: page.clockFam()
                    text: pv.hhmm().h + ":" + pv.hhmm().m
                    font.pixelSize: 30 * 1.33 * pv.s
                    color: page.v("accent_clock", false) ? pv.acc : "#F6F5F4"
                    x: pv.px(implicitWidth); y: 48 * pv.s - implicitHeight / 2
                }
                T {
                    visible: page.v("date", true)
                    text: page.now.toLocaleDateString(Qt.locale("en_US"), "dddd, d MMMM")
                    font.pixelSize: (pv.st === "minimal" ? 14 : 18) * 1.33 * pv.s
                    color: "#F6F5F4"; opacity: 0.55
                    x: pv.px(implicitWidth)
                    y: pv.st === "minimal" ? 96 * pv.s - implicitHeight / 2 : pv.py(pv.ys.date, implicitHeight)
                }
                T {
                    visible: page.v("greeting", true)
                    text: page.greeting()
                    font.pixelSize: 15 * 1.33 * pv.s
                    color: "#F6F5F4"; opacity: 0.9
                    x: pv.px(implicitWidth)
                    y: pv.py((page.v("date", true) || pv.st === "minimal") ? pv.ys.greet : pv.ys.date, implicitHeight)
                }
                // password field
                Rectangle {
                    readonly property string kind: page.v("input", "pill")
                    width: 300 * pv.s; height: 52 * pv.s
                    x: pv.px(width); y: pv.py(pv.ys.input, height)
                    radius: kind === "pill" ? height / 2 : (kind === "box" ? 12 * pv.s : 0)
                    color: kind === "pill" ? Qt.rgba(1, 1, 1, 0.08) : (kind === "box" ? Qt.rgba(0, 0, 0, 0.35) : "transparent")
                    border.width: kind === "box" ? 1 : 0
                    border.color: pv.acc
                    T { anchors.centerIn: parent; text: "Enter password"; font.pixelSize: 15 * 1.33 * pv.s; color: "#F6F5F4"; opacity: 0.45 }
                    Rectangle { visible: parent.kind === "line"; anchors.bottom: parent.bottom; width: parent.width; height: 2; color: pv.acc }
                }
                // power buttons
                Row {
                    visible: page.v("power", true)
                    spacing: 90 * pv.s - 30 * 1.33 * pv.s
                    x: pv.isLeft ? 110 * pv.s : (pv.width - width) / 2
                    y: pv.py(pv.ys.power, height)
                    Repeater {
                        model: ["󰍃", "󰐥", "󰤄", "󰜉"]
                        delegate: T { kind: "icon"; text: modelData; font.pixelSize: 30 * 1.33 * pv.s; color: "#F6F5F4"; opacity: 0.6 }
                    }
                }
                // bottom lines
                Column {
                    x: pv.isLeft ? 110 * pv.s : (pv.width - width) / 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 24 * pv.s
                    spacing: 6 * pv.s
                    Repeater {
                        model: [
                            { k: "notifications", t: "󰂚  2 notifications" },
                            { k: "weather", t: "Partly cloudy  +7°C" },
                            { k: "resources", t: "CPU 8%  ·  RAM 17%  ·  GPU 16%" },
                            { k: "media", t: "󰎈  Artist - Song" }
                        ]
                        delegate: T {
                            visible: page.v(modelData.k, false)
                            anchors.horizontalCenter: pv.isLeft ? undefined : parent.horizontalCenter
                            text: modelData.t
                            font.pixelSize: 14 * 1.33 * pv.s
                            color: "#F6F5F4"; opacity: 0.75
                        }
                    }
                }
                T {
                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                    visible: page.v("managed", true) === false
                    text: "Using your own hyprlock.conf"
                    font.pixelSize: 10; color: "#e0a050"
                }
            }
        }

        Row {
            spacing: 10
            Btn { primary: true; icon: ""; text: "Lock now"; onClicked: Quickshell.execDetached(["bash", "-c", "loginctl lock-session || hyprlock"]) }
            Btn { text: "Reset"; onClicked: { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-lock\" reset"]); page.ctl.status = "Lock screen reset"; refresh.restart() } }
        }

        // ---------- idle ----------
        SectionTitle { text: "Idle"; sub: "What happens when you leave the computer. Slide to 0 for Never." }
        SliderRow {
            label: "Lock after"
            desc: "Currently: " + page.mins(page.v("lock_after", 5))
            from: 0; to: 60; step: 1; unit: " min"
            value: page.v("lock_after", 5)
            onCommitted: function(x) { page.setv("lock_after", Math.round(x)) }
        }
        SliderRow {
            label: "Turn screen off after"
            desc: "Currently: " + page.mins(page.v("screen_off_after", 0))
            from: 0; to: 60; step: 1; unit: " min"
            value: page.v("screen_off_after", 0)
            onCommitted: function(x) { page.setv("screen_off_after", Math.round(x)) }
        }
        SliderRow {
            label: "Sleep after"
            desc: "Currently: " + page.mins(page.v("suspend_after", 15))
            from: 0; to: 120; step: 5; unit: " min"
            value: page.v("suspend_after", 15)
            onCommitted: function(x) { page.setv("suspend_after", Math.round(x)) }
        }
        ToggleRow { label: "Lock before sleep"; desc: "Always lock the screen before the computer sleeps"; checked: page.v("lock_before_sleep", true) === true; onToggled: function(x) { page.setv("lock_before_sleep", x ? "on" : "off") } }

        // ---------- lock screen ----------
        SectionTitle { text: "Lock screen"; sub: "Changes show up the next time you lock." }
        ToggleRow { label: "Manage lock screen"; desc: "Off keeps your own hyprlock.conf untouched"; checked: page.v("managed", true) === true; onToggled: function(x) { page.setv("managed", x ? "on" : "off") } }
        SegRow {
            label: "Layout"
            desc: "Everything centered, or on the left side"
            options: [{ label: "Center", value: "center" }, { label: "Left", value: "left" }]
            current: page.v("layout", "center")
            onChosen: function(x) { page.setv("layout", x) }
        }
        SegRow {
            label: "Clock style"
            desc: "Big, stacked hours over minutes, or small at the top"
            options: [{ label: "Big", value: "big" }, { label: "Stacked", value: "stacked" }, { label: "Minimal", value: "minimal" }]
            current: page.v("clock", "big")
            onChosen: function(x) { page.setv("clock", x) }
        }
        // ---------- clock font ----------
        Column {
            width: parent.width
            spacing: 8
            topPadding: 4
            T { text: "Clock font"; font.pixelSize: 14 }
            T { kind: "reading"; text: "The clock stays white and grey. Fonts that are not here yet download when you pick them."; color: "#8a8a8a"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
            Grid {
                id: cfGrid
                width: parent.width
                columns: 4
                spacing: 10
                Repeater {
                    model: page.clockFonts
                    delegate: Rectangle {
                        id: ft
                        readonly property bool on: page.v("clock_font", "default") === modelData.k
                        readonly property bool here: page.hasFam(modelData.f)
                        width: (cfGrid.width - 30) / 4
                        height: 92
                        radius: 14
                        color: fm.containsMouse ? "#1c1c1c" : "#141414"
                        border.width: on ? 2 : 1
                        border.color: on ? "#F6F5F4" : "#1f1f1f"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }
                        scale: fm.pressed ? 0.97 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 12
                            textFormat: Text.StyledText
                            text: "<b>18</b><font color='#8c8c8c'>:36</font>"
                            font.family: modelData.f !== "" ? modelData.f : Fonts.family("number")
                            font.pixelSize: 34
                            color: "#F6F5F4"
                            opacity: ft.here ? 1 : 0.4
                        }
                        T {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height - 26
                            text: ft.here ? modelData.n : modelData.n + "  \u2193"
                            font.pixelSize: 11
                            color: ft.on ? "#F6F5F4" : "#9a9aa4"
                        }
                        MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { page.setv("clock_font", modelData.k); if (!ft.here) page.ctl.status = "Downloading " + modelData.n + "..." } }
                    }
                }
            }
        }
        ToggleRow { label: "24-hour clock"; checked: page.v("clock_24h", true) === true; onToggled: function(x) { page.setv("clock_24h", x ? "on" : "off") } }
        ToggleRow { label: "Accent clock"; desc: "Color the clock with your Theme"; checked: page.v("accent_clock", false) === true; onToggled: function(x) { page.setv("accent_clock", x ? "on" : "off") } }
        ToggleRow { label: "Date"; checked: page.v("date", true) === true; onToggled: function(x) { page.setv("date", x ? "on" : "off") } }
        ToggleRow { label: "Greeting"; desc: "Good morning / evening with your name"; checked: page.v("greeting", true) === true; onToggled: function(x) { page.setv("greeting", x ? "on" : "off") } }
        ToggleRow { label: "Profile picture"; desc: "Your avatar from Home"; checked: page.v("avatar", true) === true; onToggled: function(x) { page.setv("avatar", x ? "on" : "off") } }
        SegRow {
            label: "Password field"
            options: [{ label: "Pill", value: "pill" }, { label: "Box", value: "box" }, { label: "Line", value: "line" }]
            current: page.v("input", "pill")
            onChosen: function(x) { page.setv("input", x) }
        }
        ToggleRow { label: "Power buttons"; desc: "Log out, shut down, sleep and restart"; checked: page.v("power", true) === true; onToggled: function(x) { page.setv("power", x ? "on" : "off") } }

        SectionTitle { text: "Background" }
        SegRow {
            label: "Source"
            desc: "Blurred screenshot, your wallpaper, or a plain color"
            options: [{ label: "Screenshot", value: "screenshot" }, { label: "Wallpaper", value: "wallpaper" }, { label: "Color", value: "color" }]
            current: page.v("background", "screenshot")
            onChosen: function(x) { page.setv("background", x) }
        }
        SliderRow {
            label: "Blur"
            from: 0; to: 4; step: 1
            value: page.v("blur", 3)
            onCommitted: function(x) { page.setv("blur", Math.round(x)) }
        }
        SliderRow {
            label: "Brightness"
            desc: "Lower makes the background darker"
            from: 0.2; to: 1.0; step: 0.05; decimals: 2
            value: page.v("dim", 0.5)
            onCommitted: function(x) { page.setv("dim", x.toFixed(2)) }
        }

        SectionTitle { text: "Widgets"; sub: "Small lines at the bottom of the lock screen." }
        ToggleRow { label: "Media"; desc: "What is playing right now"; checked: page.v("media", true) === true; onToggled: function(x) { page.setv("media", x ? "on" : "off") } }
        ToggleRow { label: "Resources"; desc: "CPU, RAM and GPU usage"; checked: page.v("resources", false) === true; onToggled: function(x) { page.setv("resources", x ? "on" : "off") } }
        ToggleRow { label: "Notifications"; desc: "How many notifications are waiting"; checked: page.v("notifications", true) === true; onToggled: function(x) { page.setv("notifications", x ? "on" : "off") } }
        ToggleRow { label: "Weather"; desc: "Current weather from wttr.in"; checked: page.v("weather", false) === true; onToggled: function(x) { page.setv("weather", x ? "on" : "off") } }

        Row {
            topPadding: 8
            Btn { text: "Restore my original files"; onClicked: { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-lock\" restore"]); page.ctl.status = "Original hyprlock/hypridle restored"; refresh.restart() } }
        }
    }
}
