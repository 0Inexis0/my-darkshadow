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
        page.ctl.status = I18n.t("Applied")
        refresh.restart()
    }
    readonly property bool classic: v("style", "cards") === "classic"
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
    // the fonts on this computer: Qt's list from the start, plus fc-list again after a clock font is downloaded
    property var famList: Qt.fontFamilies()
    function hasFam(f) { return f === "" || famList.indexOf(f) >= 0 }
    Process {
        id: famProc
        command: ["bash", "-c", "fc-list : family 2>/dev/null | tr ',' '\\n' | sort -u"]
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n").map(function(x) { return x.trim() }).filter(function(x) { return x !== "" })
            if (l.length > 0) page.famList = Qt.fontFamilies().concat(l)
        } }
    }
    // a font that is downloading: look again every 3 s for half a minute
    property int famTries: 0
    Timer { id: famT; interval: 3000; repeat: true; onTriggered: { famProc.running = true; if (++page.famTries >= 10) stop() } }
    function watchFont() { famTries = 0; famT.restart() }
    function two(n) { return n < 10 ? "0" + n : "" + n }
    function hh() { const h = now.getHours(); return v("clock_24h", true) ? two(h) : String((h + 11) % 12 + 1) }
    function mm() { return two(now.getMinutes()) }
    function clockFam() {
        const k = v("clock_font", "default")
        for (let i = 0; i < clockFonts.length; i++) if (clockFonts[i].k === k && clockFonts[i].f !== "") return clockFonts[i].f
        return Fonts.family("number")
    }
    function greeting() {
        const h = now.getHours()
        return (h < 5 ? I18n.t("Good night") : h < 12 ? I18n.t("Good morning") : h < 18 ? I18n.t("Good afternoon") : I18n.t("Good evening")) + ", " + Quickshell.env("USER")
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
    Timer { interval: 20000; running: Prefs.shown; repeat: true; onTriggered: page.now = new Date() }

    PageScroll {
        anchors.fill: parent

        // ---------- the lock screen in small (Preview and Test show the real one) ----------
        Item {
            width: parent.width
            height: frame.height

            Rectangle {
                id: frame
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width, 620)
                height: Math.round(width * 9 / 16)
                radius: M3.rL; clip: true
                color: "#0c0c0e"
                border.width: 1; border.color: M3.surfaceHighest
                readonly property real s: height / 1080
                readonly property color acc: M3.primary
                readonly property bool cards: page.v("style", "cards") !== "classic"
                readonly property string bg: page.v("background", "screenshot")

                // the background: your wallpaper, the screen (a stand-in here) or a plain color; blurred and dimmed
                Image {
                    id: wallImg
                    anchors.fill: parent
                    visible: frame.bg === "wallpaper" && page.wall.length > 0
                    source: visible ? "file://" + page.wall : ""
                    fillMode: Image.PreserveAspectCrop; sourceSize.width: 640; asynchronous: true
                }
                Rectangle {
                    anchors.fill: parent
                    visible: frame.bg !== "wallpaper" || page.wall.length === 0
                    gradient: Gradient { GradientStop { position: 0; color: frame.bg === "color" ? M3.surface : M3.stageTop } GradientStop { position: 1; color: frame.bg === "color" ? M3.surface : M3.stageBottom } }
                }
                Rectangle { anchors.fill: parent; color: "black"; opacity: frame.bg === "color" ? 0 : Math.max(0, Math.min(0.85, 1 - page.v("dim", 0.5))) * 0.9 }

                // ---- Cards: the month, the time, the music, and the bar at the bottom
                Row {
                    visible: frame.cards
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round((frame.height - 540 * frame.s) / 2 - frame.height * 0.04)
                    spacing: 19 * frame.s
                    // the month
                    Rectangle {
                        width: 270 * frame.s; height: 540 * frame.s; radius: 32 * frame.s; clip: true
                        gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(frame.acc.r * 0.45, frame.acc.g * 0.45, frame.acc.b * 0.45, 0.85) } GradientStop { position: 1; color: Qt.rgba(0.06, 0.06, 0.07, 0.8) } }
                        Text { x: 24 * frame.s; y: 10 * frame.s; text: page.now.toLocaleDateString(I18n.loc, "MMM").replace(".", "").toUpperCase(); color: frame.acc
                            font.family: page.clockFam(); font.pixelSize: 104 * frame.s; font.weight: Font.Black }
                        Text { x: 26 * frame.s; y: 140 * frame.s; text: page.now.toLocaleDateString(I18n.loc, "dddd d"); color: "#F6F5F4"
                            font.family: Fonts.family("main"); font.pixelSize: 22 * frame.s; font.weight: Font.DemiBold; font.capitalization: Font.Capitalize }
                        Grid {
                            x: 18 * frame.s; anchors.bottom: parent.bottom; anchors.bottomMargin: 20 * frame.s
                            columns: 7; rowSpacing: 10 * frame.s
                            Repeater { model: 35
                                delegate: Item { width: (270 - 36) / 7 * frame.s; height: 18 * frame.s
                                    readonly property bool today: index === page.now.getDate() + 2
                                    Blob { anchors.centerIn: parent; visible: parent.today; width: 24 * frame.s; height: width; kind: "cookie"; color: frame.acc }
                                    Rectangle { anchors.centerIn: parent; visible: !parent.today && index > 2 && index < 33; width: 8 * frame.s; height: 3 * frame.s; radius: height / 2; color: "#F6F5F4"; opacity: 0.5 } } }
                        }
                    }
                    // the time
                    Rectangle {
                        width: 270 * frame.s; height: 540 * frame.s; radius: 32 * frame.s; clip: true
                        gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(frame.acc.r * 0.45, frame.acc.g * 0.45, frame.acc.b * 0.45, 0.85) } GradientStop { position: 1; color: Qt.rgba(0.06, 0.06, 0.07, 0.8) } }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter; y: 40 * frame.s; spacing: -66 * frame.s
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: page.hh(); color: "#F6F5F4"
                                font.family: page.clockFam(); font.pixelSize: 162 * frame.s; font.weight: Font.Bold }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: page.mm(); color: frame.acc
                                font.family: page.clockFam(); font.pixelSize: 162 * frame.s; font.weight: Font.Bold }
                        }
                        Blob { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 30 * frame.s
                            width: 130 * frame.s; height: width; kind: Prefs.accentShape; color: Qt.rgba(frame.acc.r, frame.acc.g, frame.acc.b, 0.18) }
                    }
                    // the music
                    Rectangle {
                        visible: page.v("media", true) === true
                        width: 270 * frame.s; height: 540 * frame.s; radius: 32 * frame.s; clip: true
                        gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(frame.acc.r * 0.45, frame.acc.g * 0.45, frame.acc.b * 0.45, 0.85) } GradientStop { position: 1; color: Qt.rgba(0.06, 0.06, 0.07, 0.8) } }
                        Text { x: 24 * frame.s; y: 18 * frame.s; text: I18n.t("Song"); color: "#F6F5F4"; font.family: Fonts.family("main"); font.pixelSize: 32 * frame.s; font.weight: Font.Black }
                        Rectangle { x: 22 * frame.s; y: 150 * frame.s; width: 110 * frame.s; height: 28 * frame.s; radius: height / 2; color: frame.acc }
                        Rectangle { x: 11 * frame.s; y: 195 * frame.s; width: parent.width - 22 * frame.s; height: parent.height - 195 * frame.s - 90 * frame.s; radius: 20 * frame.s; color: Qt.rgba(1, 1, 1, 0.08) }
                        Row { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 16 * frame.s; spacing: 9 * frame.s
                            Repeater { model: [58, 76, 58]
                                delegate: Rectangle { width: modelData * frame.s; height: 50 * frame.s; radius: height / 2; color: index === 1 ? frame.acc : Qt.rgba(frame.acc.r, frame.acc.g, frame.acc.b, 0.28) } } }
                    }
                }
                Row {
                    visible: frame.cards
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 36 * frame.s
                    spacing: 11 * frame.s
                    Rectangle { width: 120 * frame.s; height: 56 * frame.s; radius: height / 2; color: M3.surfaceC }
                    Rectangle { width: 430 * frame.s; height: 56 * frame.s; radius: height / 2; color: M3.surfaceC; border.width: 2; border.color: frame.acc
                        Blob { x: 8 * frame.s; anchors.verticalCenter: parent.verticalCenter; width: 40 * frame.s; height: width; kind: Prefs.accentShape; color: frame.acc } }
                    Rectangle { visible: page.v("power", true) === true; width: 150 * frame.s; height: 56 * frame.s; radius: height / 2; color: M3.surfaceC
                        Rectangle { anchors.right: parent.right; anchors.rightMargin: 9 * frame.s; anchors.verticalCenter: parent.verticalCenter; width: 40 * frame.s; height: width; radius: width / 2; color: Qt.rgba(1, 0.42, 0.42, 0.3) } }
                }

                // ---- Classic: one column (the clock in your style, the greeting, the password)
                Column {
                    visible: !frame.cards
                    readonly property bool isLeft: page.v("layout", "center") === "left"
                    readonly property string st: page.v("clock", "big")
                    x: isLeft ? frame.width * 0.08 : (frame.width - width) / 2
                    y: frame.height * 0.12
                    width: frame.width * 0.5
                    spacing: 10 * frame.s
                    T { anchors.horizontalCenter: parent.isLeft ? undefined : parent.horizontalCenter; visible: page.v("date", true) === true
                        text: page.now.toLocaleDateString(I18n.loc, "dddd, d MMMM"); font.pixelSize: 26 * frame.s; color: "#F6F5F4" }
                    Item {
                        width: parent.width; height: parent.st === "minimal" ? 96 * frame.s : (parent.st === "big" ? 190 * frame.s : 300 * frame.s)
                        T { visible: parent.parent.st === "big" || parent.parent.st === "minimal"; anchors.horizontalCenter: parent.parent.isLeft ? undefined : parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter; text: page.hh() + ":" + page.mm(); font.family: page.clockFam()
                            font.pixelSize: (parent.parent.st === "minimal" ? 80 : 168) * frame.s; font.bold: parent.parent.st !== "minimal"; color: page.v("accent_clock", false) ? frame.acc : "#F6F5F4" }
                        Column { visible: parent.parent.st === "stacked"; anchors.horizontalCenter: parent.parent.isLeft ? undefined : parent.horizontalCenter; spacing: -36 * frame.s
                            T { text: page.hh(); font.family: page.clockFam(); font.pixelSize: 160 * frame.s; font.bold: true; color: "#F6F5F4" }
                            T { text: page.mm(); font.family: page.clockFam(); font.pixelSize: 160 * frame.s; font.bold: true; color: page.v("accent_clock", false) ? frame.acc : "#9a9a9a" } }
                        Item { visible: parent.parent.st === "shape"; width: 300 * frame.s; height: width; anchors.horizontalCenter: parent.parent.isLeft ? undefined : parent.horizontalCenter
                            Blob { anchors.fill: parent; kind: Prefs.accentShape; color: frame.acc }
                            Column { anchors.centerIn: parent; spacing: -22 * frame.s
                                T { anchors.horizontalCenter: parent.horizontalCenter; text: page.hh(); font.family: page.clockFam(); font.pixelSize: 104 * frame.s; font.bold: true; color: M3.inkPrimary }
                                T { anchors.horizontalCenter: parent.horizontalCenter; text: page.mm(); font.family: page.clockFam(); font.pixelSize: 104 * frame.s; font.bold: true; color: M3.inkPrimary } } }
                    }
                    Row { anchors.horizontalCenter: parent.isLeft ? undefined : parent.horizontalCenter; spacing: 12 * frame.s
                        Blob { visible: page.v("avatar", true) === true; width: 52 * frame.s; height: width; kind: Prefs.accentShape; color: M3.primaryContainer; anchors.verticalCenter: parent.verticalCenter }
                        T { visible: page.v("greeting", true) === true; text: page.greeting(); font.pixelSize: 20 * frame.s; color: "#F6F5F4"; anchors.verticalCenter: parent.verticalCenter } }
                }
                Rectangle {
                    visible: !frame.cards
                    readonly property string kind: page.v("input", "pill")
                    readonly property bool isLeft: page.v("layout", "center") === "left"
                    width: 380 * frame.s; height: 56 * frame.s
                    x: isLeft ? frame.width * 0.08 : (frame.width - width) / 2
                    y: frame.height * 0.66
                    radius: kind === "pill" ? height / 2 : (kind === "box" ? 18 * frame.s : 0)
                    color: kind === "line" ? "transparent" : M3.surfaceHigh
                    border.width: kind === "line" ? 0 : 2; border.color: frame.acc
                    Rectangle { visible: parent.kind === "line"; anchors.bottom: parent.bottom; width: parent.width; height: 2; color: frame.acc }
                    Blob { x: 8 * frame.s; anchors.verticalCenter: parent.verticalCenter; width: 40 * frame.s; height: width; kind: Prefs.accentShape; color: frame.acc }
                }
            }
        }

        Row {
            spacing: 10
            Btn { primary: true; icon: ""; text: I18n.t("Lock now"); onClicked: Quickshell.execDetached(["bash", "-c", "setsid -f \"$HOME/.local/bin/rice-lock\" now >/dev/null 2>&1"]) }
            // the real lock screen in a window: try it without locking (Esc closes it)
            Btn { sym: "visibility"; text: I18n.t("Preview")
                onClicked: Quickshell.execDetached(["bash", "-c", "setsid -f \"$HOME/.local/bin/rice-lock\" preview >/dev/null 2>&1"]) }
            // a real lock that unlocks itself after 30 seconds: try the keyboard without risk
            Btn { sym: "timer"; text: I18n.t("Test (30 s)")
                onClicked: Quickshell.execDetached(["bash", "-c", "setsid -f \"$HOME/.local/bin/rice-lock\" test >/dev/null 2>&1"]) }
            Btn { text: I18n.t("Reset"); onClicked: { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-lock\" reset"]); page.ctl.status = I18n.t("Lock screen reset"); refresh.restart() } }
        }

        // ---------- idle ----------
        SectionTitle { text: I18n.t("Idle"); sub: I18n.t("What happens when you leave the computer. Slide to 0 for Never.") }
        SliderRow {
            label: I18n.t("Lock after")
            desc: I18n.t("Currently: ") + page.mins(page.v("lock_after", 5))
            from: 0; to: 60; step: 1; unit: " min"
            value: page.v("lock_after", 5)
            onCommitted: function(x) { page.setv("lock_after", Math.round(x)) }
        }
        SliderRow {
            label: I18n.t("Turn screen off after")
            desc: I18n.t("Currently: ") + page.mins(page.v("screen_off_after", 0))
            from: 0; to: 60; step: 1; unit: " min"
            value: page.v("screen_off_after", 0)
            onCommitted: function(x) { page.setv("screen_off_after", Math.round(x)) }
        }
        SliderRow {
            label: I18n.t("Sleep after")
            desc: I18n.t("Currently: ") + page.mins(page.v("suspend_after", 15))
            from: 0; to: 120; step: 5; unit: " min"
            value: page.v("suspend_after", 15)
            onCommitted: function(x) { page.setv("suspend_after", Math.round(x)) }
        }
        ToggleRow { label: I18n.t("Lock before sleep"); desc: I18n.t("Always lock the screen before the computer sleeps"); checked: page.v("lock_before_sleep", true) === true; onToggled: function(x) { page.setv("lock_before_sleep", x ? "on" : "off") } }

        // ---------- lock screen ----------
        SectionTitle { text: I18n.t("Lock screen"); sub: I18n.t("Changes show up the next time you lock. Preview shows it without locking.") }
        SegRow {
            label: I18n.t("Style")
            desc: I18n.t("Cards: the month, the time and your music on tall cards. Classic: one column")
            options: [{ label: I18n.t("Cards"), value: "cards" }, { label: I18n.t("Classic"), value: "classic" }]
            current: page.v("style", "cards")
            onChosen: function(x) { page.setv("style", x) }
        }
        SegRow {
            visible: page.v("style", "cards") === "classic"
            label: I18n.t("Layout")
            desc: I18n.t("Everything centered, or on the left side")
            options: [{ label: I18n.t("Center"), value: "center" }, { label: I18n.t("Left"), value: "left" }]
            current: page.v("layout", "center")
            onChosen: function(x) { page.setv("layout", x) }
        }
        SegRow {
            visible: page.v("style", "cards") === "classic"
            label: I18n.t("Clock style")
            desc: I18n.t("Big, stacked hours over minutes, small, or inside your shape")
            options: [{ label: I18n.t("Big"), value: "big" }, { label: I18n.t("Stacked"), value: "stacked" }, { label: I18n.t("Minimal"), value: "minimal" }, { label: I18n.t("Shape"), value: "shape" }]
            current: page.v("clock", "big")
            onChosen: function(x) { page.setv("clock", x) }
        }
        // ---------- clock font ----------
        Column {
            width: parent.width
            spacing: 8
            topPadding: 4
            T { text: I18n.t("Clock font"); font.pixelSize: 14 }
            T { kind: "reading"; text: I18n.t("For the month and the time (Cards) or the clock (Classic). Fonts that are not here yet download when you pick them."); color: M3.inkDim; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
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
                        color: fm.containsMouse ? M3.surfaceHigh : M3.surfaceC
                        border.width: on ? 2 : 1
                        border.color: on ? M3.primary : M3.outlineVariant
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }
                        scale: fm.pressed ? 0.97 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 12
                            textFormat: Text.StyledText
                            text: I18n.t("<b>18</b><font color='#8c8c8c'>:36</font>")
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
                            color: ft.on ? M3.primary : M3.inkDim
                        }
                        MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { page.setv("clock_font", modelData.k); if (!ft.here) { page.ctl.status = I18n.t("Downloading ") + modelData.n + "..."; page.watchFont() } } }
                    }
                }
            }
        }
        ToggleRow { label: I18n.t("24-hour clock"); checked: page.v("clock_24h", true) === true; onToggled: function(x) { page.setv("clock_24h", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Accent clock"); desc: I18n.t("Color the clock with your Theme"); checked: page.v("accent_clock", false) === true; onToggled: function(x) { page.setv("accent_clock", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Date"); checked: page.v("date", true) === true; onToggled: function(x) { page.setv("date", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Greeting"); desc: I18n.t("Good morning / evening with your name"); checked: page.v("greeting", true) === true; onToggled: function(x) { page.setv("greeting", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Profile picture"); desc: I18n.t("Your avatar from Home"); checked: page.v("avatar", true) === true; onToggled: function(x) { page.setv("avatar", x ? "on" : "off") } }
        SegRow {
            visible: page.classic
            label: I18n.t("Password field")
            options: [{ label: I18n.t("Pill"), value: "pill" }, { label: I18n.t("Box"), value: "box" }, { label: I18n.t("Line"), value: "line" }]
            current: page.v("input", "pill")
            onChosen: function(x) { page.setv("input", x) }
        }
        ToggleRow { label: I18n.t("Power buttons"); desc: I18n.t("Sleep, restart and shut down (in red); restart and shut down ask for a second click"); checked: page.v("power", true) === true; onToggled: function(x) { page.setv("power", x ? "on" : "off") } }

        SectionTitle { text: I18n.t("Background") }
        SegRow {
            label: I18n.t("Source")
            desc: I18n.t("Blurred screenshot, your wallpaper, or a plain color")
            options: [{ label: I18n.t("Screenshot"), value: "screenshot" }, { label: I18n.t("Wallpaper"), value: "wallpaper" }, { label: I18n.t("Color"), value: "color" }]
            current: page.v("background", "screenshot")
            onChosen: function(x) { page.setv("background", x) }
        }
        SliderRow {
            label: I18n.t("Blur")
            from: 0; to: 4; step: 1
            value: page.v("blur", 3)
            onCommitted: function(x) { page.setv("blur", Math.round(x)) }
        }
        SliderRow {
            label: I18n.t("Brightness")
            desc: I18n.t("Lower makes the background darker")
            from: 0.2; to: 1.0; step: 0.05; decimals: 2
            value: page.v("dim", 0.5)
            onCommitted: function(x) { page.setv("dim", x.toFixed(2)) }
        }

        SectionTitle { text: I18n.t("Widgets"); sub: page.classic ? I18n.t("Small lines at the bottom of the lock screen.") : I18n.t("Cards shows your music on its own card.") }
        ToggleRow { label: I18n.t("Media"); desc: I18n.t("What is playing right now"); checked: page.v("media", true) === true; onToggled: function(x) { page.setv("media", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Resources"); desc: I18n.t("CPU, RAM and GPU usage"); checked: page.v("resources", false) === true; onToggled: function(x) { page.setv("resources", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Notifications"); desc: I18n.t("How many notifications are waiting"); checked: page.v("notifications", true) === true; onToggled: function(x) { page.setv("notifications", x ? "on" : "off") } }
        ToggleRow { visible: page.classic; label: I18n.t("Weather"); desc: I18n.t("Current weather from wttr.in"); checked: page.v("weather", false) === true; onToggled: function(x) { page.setv("weather", x ? "on" : "off") } }

        LoginScreenCard { ctl: page.ctl }

        Row {
            topPadding: 8
            Btn { text: I18n.t("Restore my original files"); onClicked: { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-lock\" restore"]); page.ctl.status = I18n.t("Original hyprlock/hypridle restored"); refresh.restart() } }
        }
    }
}
