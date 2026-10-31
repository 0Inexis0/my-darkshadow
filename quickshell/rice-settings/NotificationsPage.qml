import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl
    property var ns: ({})

    function v(k, d) { return ns[k] !== undefined ? ns[k] : d }
    function norm(value) { return value === "on" ? true : value === "off" ? false : value }
    function setv(key, value) {
        const n = Object.assign({}, ns)
        n[key] = page.norm(value)
        ns = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-notify\" set \"$1\" \"$2\"", "_", key, String(value)])
        page.ctl.status = "Applied"
        refresh.restart()
    }
    function famFor(k) {
        return k === "sans" ? "Inter" : k === "rounded" ? "Rubik" : k === "mono" ? "JetBrainsMono Nerd Font" : ""
    }
    function preview(name, vol) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-sound\" play \"$1\" \"$2\"", "_", name, String(vol)])
    }
    function tool(arg) { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-notify\" \"$1\"", "_", arg]) }

    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-notify\" state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.ns = JSON.parse(text) } catch (e) { } } }
    }
    Timer { id: refresh; interval: 800; onTriggered: stateProc.running = true }

    PageScroll {
        anchors.fill: parent

        // ---------- live preview ----------
        Rectangle {
            id: stage
            width: parent.width
            height: 170
            radius: 16
            clip: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#1b1a22" }
                GradientStop { position: 1; color: "#0e0f12" }
            }
            border.width: 1
            border.color: "#1f1f1f"

            T {
                anchors.centerIn: parent
                text: "Preview"
                color: Qt.rgba(1, 1, 1, 0.06)
                font.pixelSize: 44
                font.bold: true
            }

            PopupMock {
                id: mock
                readonly property string ps: page.v("popup_style", "match")
                look: ps === "match" ? page.v("style", "glass") : ps
                acc: page.v("accent", true) ? page.v("accent_color", "#d4d4d4") : "#F6F5F4"
                accFg: page.v("accent", true) ? page.v("on_accent", "#0d0d0d") : "#0d0d0d"
                baseRadius: page.v("radius", 18) * 0.85
                op: page.v("opacity", 0.8)
                pop: page.v("popup_opacity", 0.85)
                surface: page.v("colors", "graphite")
                edge: page.v("border", "subtle")
                shadowOn: page.v("shadow", false) === true
                fam: page.famFor(page.v("font", "sans"))
                fs: page.v("font_size", 13) / 13
                iconSize: Math.max(26, Math.min(46, page.v("icon_size", 40)))
                width: Math.min(stage.width - 28, page.v("popup_width", 360) * 0.85)
                height: (look === "pill" || look === "minimal") ? 56 : (page.v("compact", false) ? 66 : 78)
                x: page.v("pos_x", "right") === "left" ? 14 : (page.v("pos_x", "right") === "center" ? (stage.width - width) / 2 : stage.width - width - 14)
                y: page.v("pos_y", "top") === "top" ? 14 : stage.height - height - 14
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 180 } }
            }
        }

        Row {
            spacing: 10
            Btn { primary: true; icon: ""; text: "Send test notification"; onClicked: page.tool("test") }
            Btn { icon: ""; text: "Open panel"; onClicked: page.tool("panel") }
        }

        // ---------- sound ----------
        SectionTitle { text: "Sound"; sub: "Plays when a notification arrives (Discord, updates, ...). Silent during Do Not Disturb. Click one to hear it." }
        Flow {
            id: sounds
            width: parent.width
            spacing: 10
            Repeater {
                model: [
                    { k: "glass", n: "Glass", b: [0.45, 1, 0.75, 0.5, 0.3] },
                    { k: "droplet", n: "Droplet", b: [0.3, 0.9, 0.4, 0.7, 0.2] },
                    { k: "chime", n: "Chime", b: [0.4, 0.6, 0.85, 1, 0.6] },
                    { k: "bubble", n: "Bubble", b: [0.9, 0.3, 0.8, 0.25, 0.15] },
                    { k: "marimba", n: "Marimba", b: [1, 0.45, 0.85, 0.4, 0.2] },
                    { k: "aurora", n: "Aurora", b: [0.3, 0.55, 0.8, 0.95, 0.75] },
                    { k: "off", n: "Off", b: [0.13, 0.13, 0.13, 0.13, 0.13] }
                ]
                delegate: SoundTile {
                    width: (sounds.width - 30) / 4
                    name: modelData.k
                    label: modelData.n
                    bars: modelData.b
                    selected: page.v("sound", "glass") === modelData.k
                    onPicked: {
                        if (modelData.k !== "off")
                            page.preview(modelData.k, page.v("sound_volume", 70))
                        if (!selected) page.setv("sound", modelData.k)
                    }
                }
            }
        }
        SliderRow {
            label: "Sound volume"
            desc: "How loud the sound is, on top of your system volume"
            from: 0; to: 100; step: 5; unit: " %"
            value: page.v("sound_volume", 70)
            onCommitted: function(x) {
                page.setv("sound_volume", Math.round(x))
                if (page.v("sound", "glass") !== "off") page.preview(page.v("sound", "glass"), Math.round(x))
            }
        }

        // ---------- position ----------
        SectionTitle { text: "Position"; sub: "Where popups and the notification center appear." }
        SegRow {
            label: "Horizontal"
            desc: "Side of the screen"
            options: [{ label: "Left", value: "left" }, { label: "Center", value: "center" }, { label: "Right", value: "right" }]
            current: page.v("pos_x", "right")
            onChosen: function(x) { page.setv("pos_x", x) }
        }
        SegRow {
            label: "Vertical"
            desc: "Top or bottom edge"
            options: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
            current: page.v("pos_y", "top")
            onChosen: function(x) { page.setv("pos_y", x) }
        }
        SliderRow {
            label: "Gap from edge"
            desc: "Space between the panel and the screen edge"
            from: 0; to: 60; step: 1; unit: " px"
            value: page.v("margin", 10)
            onCommitted: function(x) { page.setv("margin", Math.round(x)) }
        }

        // ---------- panel ----------
        SectionTitle { text: "Notification center"; sub: "The panel that opens from the bell in Waybar." }
        SegRow {
            label: "Layout"
            desc: "Order of the controls"
            options: [{ label: "Controls top", value: "controls-top" }, { label: "Controls bottom", value: "controls-bottom" }, { label: "Minimal", value: "minimal" }]
            current: page.v("layout", "controls-top")
            onChosen: function(x) { page.setv("layout", x) }
        }
        SliderRow {
            label: "Width"
            from: 300; to: 700; step: 10; unit: " px"
            value: page.v("panel_width", 400)
            onCommitted: function(x) { page.setv("panel_width", Math.round(x)) }
        }
        ToggleRow {
            label: "Full height"
            desc: "Stretch the panel from the top to the bottom of the screen"
            checked: page.v("fit", false) === true
            onToggled: function(x) { page.setv("fit", x ? "on" : "off") }
        }
        SliderRow {
            label: "Height"
            desc: "Used when full height is off"
            from: 300; to: 1400; step: 20; unit: " px"
            value: page.v("panel_height", 780)
            onCommitted: function(x) { page.setv("panel_height", Math.round(x)) }
        }

        SectionTitle { text: "Widgets"; sub: "What the notification center shows." }
        ToggleRow { label: "Title & Clear all"; desc: "Header with a button that clears everything"; checked: page.v("w_title", true) === true; onToggled: function(x) { page.setv("w_title", x ? "on" : "off") } }
        ToggleRow { label: "Do Not Disturb"; desc: "Switch that silences popups"; checked: page.v("w_dnd", true) === true; onToggled: function(x) { page.setv("w_dnd", x ? "on" : "off") } }
        ToggleRow { label: "Media player"; desc: "Cover, title and controls of what is playing"; checked: page.v("w_media", true) === true; onToggled: function(x) { page.setv("w_media", x ? "on" : "off") } }
        ToggleRow { label: "Volume slider"; desc: "Output volume"; checked: page.v("w_volume", false) === true; onToggled: function(x) { page.setv("w_volume", x ? "on" : "off") } }
        ToggleRow { label: "Quick buttons"; desc: "Power, Settings and your own buttons"; checked: page.v("w_buttons", true) === true; onToggled: function(x) { page.setv("w_buttons", x ? "on" : "off") } }

        // ---------- popups ----------
        SectionTitle { text: "Popups"; sub: "The small cards that appear when something arrives." }
        Flow {
            id: styles
            width: parent.width
            spacing: 10
            Repeater {
                model: [
                    { k: "match", n: "Same as panel" }, { k: "glass", n: "Glass" }, { k: "solid", n: "Solid" },
                    { k: "minimal", n: "Minimal" }, { k: "pill", n: "Pill" }, { k: "accent", n: "Accent bar" },
                    { k: "glow", n: "Glow" }, { k: "island", n: "Island" }, { k: "light", n: "Light" }
                ]
                delegate: Rectangle {
                    readonly property bool on: page.v("popup_style", "match") === modelData.k
                    width: (styles.width - 20) / 3
                    height: 96
                    radius: 14
                    color: "#141414"
                    border.width: on ? 2 : 1
                    border.color: on ? "#F6F5F4" : (sMouse.containsMouse ? "#3a3a3a" : "#2a2a2a")
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Rectangle {
                        x: 8; y: 8
                        width: parent.width - 16; height: 56
                        radius: 9
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#2a2836" }
                            GradientStop { position: 1; color: "#15161a" }
                        }
                        PopupMock {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: (look === "pill" || look === "minimal") ? 30 : 38
                            look: modelData.k === "match" ? page.v("style", "glass") : modelData.k
                            acc: page.v("accent", true) ? page.v("accent_color", "#d4d4d4") : "#F6F5F4"
                            accFg: page.v("on_accent", "#0d0d0d")
                            baseRadius: Math.min(12, page.v("radius", 18) * 0.6)
                            op: page.v("opacity", 0.8)
                            pop: page.v("popup_opacity", 0.85)
                            surface: page.v("colors", "graphite")
                            edge: page.v("border", "subtle")
                            shadowOn: false
                            fam: page.famFor(page.v("font", "sans"))
                            iconSize: 22
                            showBody: false
                            fs: 0.8
                        }
                    }
                    T {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 70
                        text: modelData.n
                        font.pixelSize: 12
                        font.bold: on
                    }
                    MouseArea {
                        id: sMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.setv("popup_style", modelData.k)
                    }
                }
            }
        }
        SliderRow {
            label: "Width"
            from: 260; to: 600; step: 10; unit: " px"
            value: page.v("popup_width", 360)
            onCommitted: function(x) { page.setv("popup_width", Math.round(x)) }
        }
        SliderRow {
            label: "Time on screen"
            desc: "Seconds before a popup hides"
            from: 2; to: 30; step: 1; unit: " s"
            value: page.v("timeout", 6)
            onCommitted: function(x) { page.setv("timeout", Math.round(x)) }
        }
        ToggleRow { label: "Keep urgent ones"; desc: "Critical notifications stay until you close them"; checked: page.v("critical_sticky", true) === true; onToggled: function(x) { page.setv("critical_sticky", x ? "on" : "off") } }
        SliderRow {
            label: "Icon size"
            from: 20; to: 72; step: 2; unit: " px"
            value: page.v("icon_size", 40)
            onCommitted: function(x) { page.setv("icon_size", Math.round(x)) }
        }
        ToggleRow { label: "Show images"; desc: "Album covers, screenshots and avatars"; checked: page.v("images", true) === true; onToggled: function(x) { page.setv("images", x ? "on" : "off") } }

        // ---------- style ----------
        SectionTitle { text: "Colors"; sub: "Base color of popups and the panel. Popup styles Island and Light keep their own." }
        SegRow {
            label: "Surface"
            options: [{ label: "Black", value: "black" }, { label: "Graphite", value: "graphite" }, { label: "Slate", value: "slate" },
                      { label: "White", value: "white" }, { label: "Tinted", value: "tinted" }]
            current: page.v("colors", "graphite")
            onChosen: function(x) { page.setv("colors", x) }
        }
        ToggleRow { label: "Accent color"; desc: "Buttons, switches and icons follow your Theme"; checked: page.v("accent", true) === true; onToggled: function(x) { page.setv("accent", x ? "on" : "off") } }
        SegRow {
            label: "Border"
            desc: "Edge around popups and the panel"
            options: [{ label: "Subtle", value: "subtle" }, { label: "Accent", value: "accent" }, { label: "None", value: "none" }]
            current: page.v("border", "subtle")
            onChosen: function(x) { page.setv("border", x) }
        }
        ToggleRow { label: "Shadow"; desc: "Small shadow under popups (off looks cleaner)"; checked: page.v("shadow", false) === true; onToggled: function(x) { page.setv("shadow", x ? "on" : "off") } }

        SectionTitle { text: "Text" }
        SegRow {
            label: "Font"
            desc: "Sans uses Inter, Rounded uses Rubik (they fall back if missing)"
            options: [{ label: "Sans", value: "sans" }, { label: "Rounded", value: "rounded" }, { label: "Mono", value: "mono" }, { label: "System", value: "system" }]
            current: page.v("font", "sans")
            onChosen: function(x) { page.setv("font", x) }
        }
        SliderRow {
            label: "Text size"
            from: 10; to: 18; step: 1; unit: " px"
            value: page.v("font_size", 13)
            onCommitted: function(x) { page.setv("font_size", Math.round(x)) }
        }

        SectionTitle { text: "Transparency & blur"; sub: "Blur only shows where the surface is transparent." }
        SliderRow {
            label: "Popup opacity"
            desc: "Lower is more see-through"
            from: 0.3; to: 1.0; step: 0.02; decimals: 2
            value: page.v("popup_opacity", 0.85)
            onCommitted: function(x) { page.setv("popup_opacity", x.toFixed(2)) }
        }
        SliderRow {
            label: "Panel opacity"
            desc: "The notification center"
            from: 0.3; to: 1.0; step: 0.02; decimals: 2
            value: page.v("opacity", 0.8)
            onCommitted: function(x) { page.setv("opacity", x.toFixed(2)) }
        }
        ToggleRow { label: "Blur popups"; desc: "Blur the desktop behind popups"; checked: page.v("blur_popups", true) === true; onToggled: function(x) { page.setv("blur_popups", x ? "on" : "off") } }
        ToggleRow { label: "Blur panel"; desc: "Blur the desktop behind the notification center"; checked: page.v("blur", true) === true; onToggled: function(x) { page.setv("blur", x ? "on" : "off") } }

        SectionTitle { text: "Notification center style"; sub: "Look of the panel. Popups use it too when their style is Same as panel." }
        SegRow {
            label: "Look"
            desc: "Glass is translucent, Solid is opaque, Outline uses the accent"
            options: [{ label: "Glass", value: "glass" }, { label: "Solid", value: "solid" }, { label: "Outline", value: "outline" }]
            current: page.v("style", "glass")
            onChosen: function(x) { page.setv("style", x) }
        }
        SliderRow {
            label: "Corner radius"
            from: 0; to: 32; step: 1; unit: " px"
            value: page.v("radius", 18)
            onCommitted: function(x) { page.setv("radius", Math.round(x)) }
        }
        ToggleRow { label: "Compact"; desc: "Less padding, more notifications on screen"; checked: page.v("compact", false) === true; onToggled: function(x) { page.setv("compact", x ? "on" : "off") } }

        Row {
            spacing: 10
            topPadding: 8
            Btn { text: "Reset"; onClicked: { page.tool("reset"); page.ctl.status = "Notifications reset"; refresh.restart() } }
            Btn { text: "Restore my original files"; onClicked: { page.tool("restore"); page.ctl.status = "Original swaync files restored" } }
        }
        T {
            visible: page.ns.installed === false
            width: parent.width
            text: "swaync was not found. Install SwayNotificationCenter to use these settings."
            color: "#e0a050"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}
