import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl

    readonly property var widgets: [
        { key: "weather", label: "Weather", icon: "", desc: "Temperature and sky" },
        { key: "media", label: "Media player", icon: "", desc: "Now playing + controls" },
        { key: "resources", label: "Resources", icon: "", desc: "CPU, RAM and GPU" },
        { key: "usercard", label: "User card", icon: "", desc: "Greeting and date" },
        { key: "calendar", label: "Calendar", icon: "", desc: "Month view" },
        { key: "visualizer", label: "Visualizer", icon: "\uf001", desc: "See-through, at the bottom" },
        { key: "battery", label: "Battery", icon: "\uf240", desc: "Charge and time left" },
        { key: "todo", label: "To-do", icon: "\uf14a", desc: "Tasks to tick off" },
        { key: "focus", label: "Focus timer", icon: "\uf017", desc: "Work and break timer" },
        { key: "notes", label: "Note", icon: "\uf249", desc: "A note on the desktop" },
        { key: "gauge", label: "Gauge", icon: "\uf4bc", desc: "CPU, RAM, GPU or heat in a soft shape" },
        { key: "date", label: "Date", icon: "\uf073", desc: "Today in a flower or cookie shape" }
    ]

    // widget styles (Settings > Widgets > Theme)
    readonly property var themes: [
        { k: "shadow", n: "DarkShadow", d: "Frosted glass, black and white" },
        { k: "google", n: "Google", d: "Soft cards in your theme color" },
        { k: "outline", n: "Outline", d: "No fill, just a thin line" }
    ]
    function wv(id, key, d) { const w = page.ctl.dst.widgets; return w && w[id] && w[id][key] !== undefined ? w[id][key] : d }
    property color accent: "#9ec9bd"
    Process {
        command: ["bash", "-c", "sed -n 's/^@define-color accent *\\(#[0-9a-fA-F]\\{6\\}\\).*/\\1/p' \"$HOME/.config/waybar/colors.css\" 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector { onStreamFinished: { const t = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(t)) page.accent = t } }
    }

    // the lock screen clock fonts (rice-fonts downloads them)
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

    // the to-do list (also on the desktop widget)
    property var todos: []
    Process {
        id: todoProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-todo\" list"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.todos = JSON.parse(text) } catch (e) { } } }
    }
    function todoDo(args) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-todo\" \"$@\"", "_"].concat(args.map(a => String(a))))
        todoDelay.restart()
    }
    Timer { id: todoDelay; interval: 450; onTriggered: todoProc.running = true }

    function wOn(k) {
        const w = page.ctl.dst.widgets
        return w && w[k] ? w[k].enabled === true : false
    }
    function cv(k, d) {
        const c = page.ctl.dst.clock
        return c && c[k] !== undefined ? c[k] : d
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 6
        contentWidth: width
        contentHeight: col.implicitHeight + 24
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
            width: flick.width
            spacing: 10

            T { kind: "title"; text: "Widgets"; font.pixelSize: 16; font.bold: true }
            // the widget editor on the desktop (Settings closes so you can see it)
            Rectangle {
                width: parent.width
                height: 72
                radius: 14
                color: edMouse.containsMouse ? M3.surfaceHigh : M3.surfaceC
                border.width: 1
                border.color: M3.surfaceHighest
                Behavior on color { ColorAnimation { duration: 140 } }
                Rectangle {
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 42; radius: 12
                    color: "#F6F5F4"
                    T { kind: "icon"; anchors.centerIn: parent; text: "\uf044"; font.pixelSize: 17; color: "#0d0d0d" }
                }
                Column {
                    x: 72; anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    T { text: "Edit widgets"; font.pixelSize: 15; font.bold: true }
                    T { kind: "reading"; text: "Add, move, resize and style widgets right on your desktop"; font.pixelSize: 12; color: M3.inkDim }
                }
                T { kind: "icon"; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: "\uf054"; color: M3.inkDim }
                MouseArea {
                    id: edMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" edit on"])
                        Qt.quit()
                    }
                }
            }
            T {
                width: parent.width
                text: "Switch a widget on to put it on the desktop. Edit widgets opens the editor on your desktop: add widgets, drag them, pull a corner to resize, change style and opacity. Shortcut: SUPER + ALT + W."
                color: M3.inkDim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Flickable {
                id: rowFlick
                width: parent.width
                height: 150
                contentWidth: wrow.width
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Behavior on contentX {
                    enabled: !rowFlick.dragging && !rowFlick.flicking
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(e) {
                        const max = Math.max(0, rowFlick.contentWidth - rowFlick.width)
                        rowFlick.contentX = Math.max(0, Math.min(max, rowFlick.contentX - (e.angleDelta.y + e.angleDelta.x) * Prefs.wheel * 1.15))
                    }
                }

                Row {
                    id: wrow
                    spacing: 10
                    Repeater {
                        model: page.widgets
                        delegate: Rectangle {
                            id: card
                            width: 172
                            height: 146
                            radius: 14
                            readonly property bool on: page.wOn(modelData.key)
                            color: cardMouse.containsMouse ? M3.surfaceHigh : M3.surfaceC
                            border.width: 1
                            border.color: card.on ? M3.primary : M3.outlineVariant
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.ctl.dset("widget", modelData.key, card.on ? "off" : "on")
                            }
                            Rectangle {
                                x: 14
                                y: 14
                                width: 40
                                height: 40
                                radius: 12
                                color: card.on ? M3.primary : M3.surfaceHighest
                                Behavior on color { ColorAnimation { duration: 200 } }
                                T { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 18; color: card.on ? M3.inkPrimary : "#F6F5F4" }
                            }
                            Column {
                                x: 14
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 14
                                spacing: 3
                                T { text: modelData.label; font.pixelSize: 14; font.bold: true }
                                T { text: modelData.desc; font.pixelSize: 10; color: M3.inkDim }
                            }
                            Tog {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                y: 22
                                checked: card.on
                                onToggled: function(v) { page.ctl.dset("widget", modelData.key, v ? "on" : "off") }
                            }
                        }
                    }
                }
            }

            ToggleRow {
                label: "Auto-hide widgets"
                desc: "Hide them while a tiled window is open on the screen; floating windows (Settings, pop-ups) leave them alone. Lighter on the computer"
                checked: page.ctl.dst.autoHide === true
                onToggled: function(v) { page.ctl.setAutoHide(v) }
            }
            ToggleRow {
                label: "Blur behind widgets"
                desc: "Frosted glass: the widgets take the colors of your wallpaper. Off: plain dark cards"
                checked: page.ctl.dst.widgetBlur !== false
                onToggled: function(v) {
                    const d = JSON.parse(JSON.stringify(page.ctl.dst)); d.widgetBlur = v; page.ctl.dst = d
                    Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" widgets-blur \"$1\"", "_", v ? "on" : "off"])
                    page.ctl.status = "Widget blur " + (v ? "on" : "off")
                }
            }
            Row {
                spacing: 8
                Pill { label: "Reset widget positions"; onClicked: page.ctl.dreset() }
            }

            // ---------- theme ----------
            T { kind: "title"; text: "Theme"; font.pixelSize: 16; font.bold: true; topPadding: 14 }
            T { width: parent.width; text: "How the widget cards look. Google takes the color of your Theme."; color: M3.inkDim; font.pixelSize: 12; wrapMode: Text.WordWrap }
            Row {
                id: themeRow
                width: parent.width
                spacing: 10
                Repeater {
                    model: page.themes
                    delegate: Rectangle {
                        id: tt
                        readonly property bool on: (page.ctl.dst.widgetTheme || "shadow") === modelData.k
                        width: (themeRow.width - 20) / 3
                        height: 150
                        radius: 14
                        color: tm.containsMouse ? M3.surfaceHigh : M3.surfaceC
                        border.width: on ? 2 : 1
                        border.color: on ? M3.primary : M3.outlineVariant
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }
                        scale: tm.pressed ? 0.98 : 1
                        Behavior on scale { NumberAnimation { duration: 90 } }
                        // a tiny desktop with one widget in this style
                        Rectangle {
                            id: mini
                            x: 10; y: 10
                            width: parent.width - 20; height: 92
                            radius: 9
                            clip: true
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#2d2350" }
                                GradientStop { position: 1; color: "#6a3a7e" }
                            }
                            Rectangle {
                                id: mw
                                anchors.centerIn: parent
                                width: parent.width - 36; height: 60
                                radius: modelData.k === "google" ? 18 : (modelData.k === "outline" ? 12 : 15)
                                color: modelData.k === "google" ? Qt.hsla(page.accent.hslHue < 0 ? 0 : page.accent.hslHue, page.accent.hslSaturation * 0.34, 0.15, 0.85)
                                     : modelData.k === "outline" ? "transparent" : Qt.rgba(0.10, 0.10, 0.115, 0.62)
                                border.width: modelData.k === "outline" ? 1.5 : (modelData.k === "shadow" ? 1 : 0)
                                border.color: modelData.k === "outline" ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.12)
                                Rectangle {
                                    x: 12; anchors.verticalCenter: parent.verticalCenter
                                    width: 32; height: 32; radius: 16
                                    color: modelData.k === "google" ? Qt.hsla(page.accent.hslHue < 0 ? 0 : page.accent.hslHue, Math.max(0.45, page.accent.hslSaturation), 0.78, 1) : "#F6F5F4"
                                    T { anchors.centerIn: parent; kind: "icon"; text: "\uf017"; font.pixelSize: 13; color: modelData.k === "google" ? "#1c1b2a" : "#0d0d0d" }
                                }
                                Column {
                                    x: 54; anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5
                                    Rectangle { width: 54; height: 7; radius: 3.5; color: "#F6F5F4"; opacity: 0.9 }
                                    Rectangle { width: 38; height: 6; radius: 3; color: "#F6F5F4"; opacity: 0.4 }
                                }
                            }
                        }
                        T { x: 12; y: 110; text: modelData.n; font.pixelSize: 13; font.bold: true }
                        T { x: 12; y: 130 - 4; width: parent.width - 24; text: modelData.d; font.pixelSize: 10; color: M3.inkDim; elide: Text.ElideRight }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.ctl.setWidgetTheme(modelData.k) }
                    }
                }
            }
            ToggleRow {
                label: "Adapt to the wallpaper"
                desc: "Dark text and light cards on a light wallpaper, light text on a dark one; every widget decides by what is behind it"
                checked: page.ctl.dst.widgetAdapt !== false
                onToggled: function(v) { page.ctl.setWidgetAdapt(v) }
            }

            // ---------- visualizer ----------
            T { kind: "title"; text: "Visualizer"; font.pixelSize: 16; font.bold: true; topPadding: 14 }
            SegRow {
                label: "Style"
                desc: "Round bars, a mirror, a wave or dots"
                options: [{ label: "Bars", value: "bars" }, { label: "Mirror", value: "mirror" }, { label: "Wave", value: "wave" }, { label: "Dots", value: "dots" }]
                current: page.wv("visualizer", "style", "bars")
                onChosen: function(v) { page.ctl.dwset("visualizer", "style", v) }
            }
            SegRow {
                label: "Color"
                desc: "Your Theme color, a gradient from it, rainbow, or white (black on a light wallpaper)"
                options: [{ label: "Theme", value: "accent" }, { label: "Gradient", value: "gradient" }, { label: "Rainbow", value: "rainbow" }, { label: "White / black", value: "mono" }]
                current: page.wv("visualizer", "color", "accent")
                onChosen: function(v) { page.ctl.dwset("visualizer", "color", v) }
            }
            SegRow {
                label: "Direction"
                desc: "Grow up from the bottom, or hang down from the top"
                options: [{ label: "Up", value: "off" }, { label: "Down", value: "on" }]
                current: (page.wv("visualizer", "flip", false) === true || page.wv("visualizer", "flip", false) === "on") ? "on" : "off"
                onChosen: function(v) { page.ctl.dwset("visualizer", "flip", v) }
            }

            // ---------- to-do ----------
            T { kind: "title"; text: "To-do list"; font.pixelSize: 16; font.bold: true; topPadding: 14 }
            T { width: parent.width; text: "The tasks of the To-do widget. On the desktop, click the widget once to type in it. In a terminal: rice-todo add \"buy milk\"."; color: M3.inkDim; font.pixelSize: 12; wrapMode: Text.WordWrap }
            Field {
                id: todoField
                width: parent.width
                placeholder: "Add a task and press Enter"
                onAccepted: { if (text.trim().length > 0) { page.todoDo(["add", text.trim()]); text = "" } }
            }
            Repeater {
                model: page.todos
                delegate: Rectangle {
                    width: col.width
                    height: 44
                    radius: 12
                    color: M3.surfaceC
                    border.width: 1
                    border.color: M3.outlineVariant
                    Rectangle {
                        id: tbx
                        x: 14; anchors.verticalCenter: parent.verticalCenter
                        width: 20; height: 20; radius: 10
                        color: modelData.done ? M3.primary : "transparent"
                        border.width: modelData.done ? 0 : 2
                        border.color: "#6a6a70"
                        T { visible: modelData.done; anchors.centerIn: parent; kind: "icon"; text: "\uf00c"; font.pixelSize: 10; color: "#0d0d0d" }
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: page.todoDo(["toggle", index]) }
                    }
                    T {
                        anchors.left: tbx.right; anchors.leftMargin: 12
                        anchors.right: dl.left; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.t
                        font.pixelSize: 13
                        font.strikeout: modelData.done
                        color: modelData.done ? "#6a6a70" : "#F6F5F4"
                        elide: Text.ElideRight
                    }
                    T {
                        id: dl
                        anchors.right: parent.right; anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        kind: "icon"; text: "\uf00d"; font.pixelSize: 13; color: M3.inkDim
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: page.todoDo(["remove", index]) }
                    }
                }
            }
            Row {
                visible: page.todos.some(t => t.done)
                Pill { label: "Clear ticked tasks"; onClicked: page.todoDo(["clear"]) }
            }

            T { kind: "title"; text: "Clock"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            ToggleRow {
                label: "Enable"
                desc: "Show a clock on the desktop"
                checked: page.cv("enabled", false) === true
                onToggled: function(v) { page.ctl.dset("clock", "enabled", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Show only when locked"
                desc: "Hide it on the desktop"
                checked: page.cv("onlyLocked", false) === true
                onToggled: function(v) { page.ctl.dset("clock", "onlyLocked", v ? "on" : "off") }
            }
            SegRow {
                label: "Placement strategy"
                desc: "Move it in the widget editor, or auto-pick a spot"
                options: [
                    { label: "Draggable", value: "draggable" },
                    { label: "Least busy", value: "leastBusy" },
                    { label: "Most busy", value: "mostBusy" }
                ]
                current: page.cv("placement", "draggable")
                onChosen: function(v) { page.ctl.dset("clock", "placement", v) }
            }
            SegRow {
                label: "Clock style"
                desc: "Look of the desktop clock"
                options: [
                    { label: "Digital", value: "digital" },
                    { label: "Line", value: "line" },
                    { label: "Cookie", value: "cookie" },
                    { label: "Pixel", value: "pixel" }
                ]
                current: page.cv("style", "digital")
                onChosen: function(v) { page.ctl.dset("clock", "style", v) }
            }

            Column {
                width: parent.width
                spacing: 8
                topPadding: 4
                T { text: "Clock font"; font.pixelSize: 14 }
                T { kind: "reading"; text: "The same fonts as the lock screen clock. They show on the Digital and Line styles. Fonts that are not here yet download when you pick them."; color: M3.inkDim; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                Grid {
                    id: cfGrid
                    width: parent.width
                    columns: 4
                    spacing: 10
                    Repeater {
                        model: page.clockFonts
                        delegate: Rectangle {
                            id: ft
                            readonly property bool on: page.cv("font", "default") === modelData.k
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
                                color: ft.on ? M3.primary : M3.inkDim
                            }
                            MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { page.ctl.dwset("clock", "font", modelData.k); if (!ft.here) page.ctl.status = "Downloading " + modelData.n + "..." } }
                        }
                    }
                }
            }
        }
    }
}
