import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl
    property var ns: ({})

    function v(k, d) { return ns[k] !== undefined ? ns[k] : d }
    readonly property bool deck: v("layout", "deck") === "deck"
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
        return k === "sans" ? Fonts.main : k === "rounded" ? "Rubik" : k === "mono" ? "JetBrainsMono Nerd Font" : ""
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
            visible: Prefs.previews
            width: parent.width
            height: 170
            radius: M3.rL
            clip: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: M3.stageTop }
                GradientStop { position: 1; color: M3.stageBottom }
            }
            border.width: 1
            border.color: M3.outlineVariant

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
                edge: page.v("border", "none")
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

        // ---------- clicking ----------
        SectionTitle { text: "Clicking a notification"; sub: "The sound for new notifications is in Sfx & sounds now." }
        ToggleRow {
            label: "Keep notifications when clicked"
            desc: "Clicking opens the app and the notification stays in the center (close it with its X or Clear all)"
            checked: page.v("keep_clicked", true)
            onToggled: function(x) { page.setv("keep_clicked", x ? "on" : "off") }
        }

        // ---------- position ----------
        SectionTitle { text: "Position"; sub: "Where popups appear. The Deck notification center has its own side below." }
        SegRow {
            label: "Horizontal"
            desc: "Side of the screen"
            options: [{ label: "Left", value: "left" }, { label: "Middle", value: "center" }, { label: "Right", value: "right" }]
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
        SectionTitle { text: "Notification center"; sub: "The panel that opens from the bell in Waybar. Deck: switches and power modes on top, volume and power buttons at the bottom." }
        NcMini {
            visible: page.deck
            width: Math.min(parent.width, 600)
            x: (parent.width - width) / 2
            ns: page.ns
        }
        SegRow {
            label: "Layout"
            desc: "Deck is the new one"
            options: [{ label: "Deck", value: "deck" }, { label: "Controls top", value: "controls-top" }, { label: "Controls bottom", value: "controls-bottom" }, { label: "Minimal", value: "minimal" }]
            current: page.v("layout", "deck")
            onChosen: function(x) { page.setv("layout", x) }
        }
        SegRow {
            visible: page.deck
            label: "Side"
            desc: "Which screen edge the notification center opens from. Top and bottom use the Height below"
            options: [{ label: "Left", value: "left" }, { label: "Right", value: "right" }, { label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
            current: page.v("cc_side", "right")
            onChosen: function(x) { page.setv("cc_side", x) }
        }
        ToggleRow {
            visible: page.deck
            label: "Floating"
            desc: "A gap all around and round corners. Off: flat against the screen edge, full height"
            checked: page.v("cc_float", true) === true
            onToggled: function(x) { page.setv("cc_float", x ? "on" : "off") }
        }
        SliderRow {
            label: "Width"
            from: 300; to: 700; step: 10; unit: " px"
            value: page.v("panel_width", 440)
            onCommitted: function(x) { page.setv("panel_width", Math.round(x)) }
        }
        ToggleRow {
            label: "Full height"
            desc: "From the top to the bottom of the screen (floating keeps the gap). Off: use the height below"
            checked: page.v("fit", true) === true
            onToggled: function(x) { page.setv("fit", x ? "on" : "off") }
        }
        SliderRow {
            label: "Height"
            desc: "Used when full height is off, and always at the top or bottom"
            from: 300; to: 1400; step: 20; unit: " px"
            value: page.v("panel_height", 820)
            onCommitted: function(x) { page.setv("panel_height", Math.round(x)) }
        }

        SectionTitle { text: "Widgets"; sub: "What the notification center shows." }
        ToggleRow { visible: page.deck; label: "Switches"; desc: "Wi-Fi, Bluetooth, Do Not Disturb, night light, keep awake"; checked: page.v("w_quick", true) === true; onToggled: function(x) { page.setv("w_quick", x ? "on" : "off") } }
        ToggleRow { visible: page.deck; label: "Brightness"; desc: page.v("have_backlight", false) ? "Screen brightness" : "Only on screens with a backlight (laptops)"; checked: page.v("w_brightness", true) === true; onToggled: function(x) { page.setv("w_brightness", x ? "on" : "off") } }
        ToggleRow { visible: page.deck; label: "Power buttons"; desc: "Lock, sleep, log out, restart, shut down (the last three ask first)"; checked: page.v("w_session", true) === true; onToggled: function(x) { page.setv("w_session", x ? "on" : "off") } }
        ToggleRow { label: "Title & Clear all"; desc: "Header with a button that clears everything"; checked: page.v("w_title", true) === true; onToggled: function(x) { page.setv("w_title", x ? "on" : "off") } }
        ToggleRow { visible: !page.deck; label: "Do Not Disturb"; desc: "Switch that silences popups"; checked: page.v("w_dnd", true) === true; onToggled: function(x) { page.setv("w_dnd", x ? "on" : "off") } }
        ToggleRow { label: "Media player"; desc: "Cover, title and controls of what is playing"; checked: page.v("w_media", true) === true; onToggled: function(x) { page.setv("w_media", x ? "on" : "off") } }
        ToggleRow { label: "Volume slider"; desc: "Output volume"; checked: page.v("w_volume", true) === true; onToggled: function(x) { page.setv("w_volume", x ? "on" : "off") } }
        ToggleRow { visible: !page.deck; label: "Quick buttons"; desc: "Power, Settings and your own buttons"; checked: page.v("w_buttons", true) === true; onToggled: function(x) { page.setv("w_buttons", x ? "on" : "off") } }

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
                    color: M3.surfaceC
                    border.width: on ? 2 : 1
                    border.color: on ? M3.primary : (sMouse.containsMouse ? M3.outline : M3.surfaceHighest)
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Rectangle {
                        x: 8; y: 8
                        width: parent.width - 16; height: 56
                        radius: 9
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: M3.stageTop }
                            GradientStop { position: 1; color: M3.stageBottom }
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
                            edge: page.v("border", "none")
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
            current: page.v("border", "none")
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

        SectionTitle { text: "Notification center style"; sub: "Look of the panel. Popups use it too when their style is Same as panel. Dark and Google switch the blur off. Notifications are never stacked on top of each other." }
        Flow {
            id: pstyles
            width: parent.width
            spacing: 10
            Repeater {
                model: [
                    { k: "glass", n: "DarkShadow Shell", d: "Frosted glass" },
                    { k: "solid", n: "Dark", d: "No blur, no transparency" },
                    { k: "google", n: "Google", d: "Tonal and round" }
                ]
                delegate: Rectangle {
                    readonly property bool on: page.v("style", "glass") === modelData.k
                    width: (pstyles.width - 20) / 3
                    height: 196
                    radius: 14
                    color: M3.surfaceC
                    border.width: on ? 2 : 1
                    border.color: on ? M3.primary : (pMouse.containsMouse ? M3.outline : M3.surfaceHighest)
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Rectangle {
                        x: 8; y: 8
                        width: parent.width - 16; height: 124
                        radius: 9
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: M3.stageTop }
                            GradientStop { position: 1; color: M3.stageBottom }
                        }
                        PanelMock {
                            anchors.centerIn: parent
                            width: parent.width - 28
                            height: parent.height - 16
                            look: modelData.k
                            acc: page.v("accent", true) ? page.v("accent_color", "#d4d4d4") : "#F6F5F4"
                            accFg: page.v("on_accent", "#0d0d0d")
                            surface: page.v("colors", "graphite")
                            baseRadius: page.v("radius", 18)
                        }
                    }
                    T {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 140
                        text: modelData.n
                        font.pixelSize: 13
                        font.bold: on
                    }
                    T {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 160
                        text: modelData.d
                        font.pixelSize: 11
                        color: M3.inkDim
                    }
                    MouseArea {
                        id: pMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.setv("style", modelData.k)
                    }
                }
            }
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
