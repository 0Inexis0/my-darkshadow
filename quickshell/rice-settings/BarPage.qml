import Quickshell
import Quickshell.Io
import QtQuick

// Settings > DarkShadow bar: the style, position and size of the bar (rice-bar). What sits where: Bar layout.
Item {
    id: page
    property var ctl
    property var qb: ({})

    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/rice-bar"
    function v(k, d) { return qb[k] !== undefined ? qb[k] : d }
    function setv(key, value) {
        const n = Object.assign({}, qb)
        n[key] = value === "on" ? true : value === "off" ? false : value
        qb = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-bar\" set \"$1\" \"$2\"", "_", key, String(value)])
        page.ctl.status = "Applied"
        refresh.restart()
    }
    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-bar\" state 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.qb = JSON.parse(text) } catch (e) { } } }
    }
    Timer { id: refresh; interval: 800; onTriggered: stateProc.running = true }
    onVisibleChanged: if (visible) stateProc.running = true

    readonly property var glyph: ({
        "launcher": "󰀻", "workspaces": "󰇘", "title": "󰖲", "media": "󰝚",
        "clock": "12:34", "tray": "󰕰", "volume": "󰕾", "network": "󰖩",
        "bluetooth": "󰂯", "battery": "󰁹 82%", "notifications": "󰂚", "power": "󰐥"
    })
    readonly property string wsText: page.v("ws_style", "dots") === "pacman" ? "\u25d6 \u2022 \u2022 \u2022" : (page.v("ws_style", "dots") === "letters" ? "A  B  C  D" : page.v("ws_style", "dots") === "numbers" ? "1  2  3  4" : "\u25cf  \u2022  \u2022  \u2022")
    readonly property var logos: [
        ["auto", "Auto", 0], ["apps", "Apps", 0xF003B], ["tux", "Linux", 0xF17C], ["arch", "Arch", 0xF303],
        ["gentoo", "Gentoo", 0xF30D], ["fedora", "Fedora", 0xF30A], ["debian", "Debian", 0xF306], ["ubuntu", "Ubuntu", 0xF31B],
        ["nixos", "NixOS", 0xF313], ["cachyos", "CachyOS", 0xF385], ["endeavouros", "Endeavour", 0xF322], ["manjaro", "Manjaro", 0xF312],
        ["linuxmint", "Mint", 0xF30E], ["opensuse", "openSUSE", 0xF314], ["void", "Void", 0xF32E], ["alpine", "Alpine", 0xF300],
        ["pop", "Pop!_OS", 0xF32A], ["kali", "Kali", 0xF327], ["centos", "CentOS", 0xF304], ["raspbian", "Raspberry", 0xF315],
        ["elementary", "elementary", 0xF309], ["zorin", "Zorin", 0xF32F], ["nobara", "Nobara", 0xF380], ["artix", "Artix", 0xF31F],
        ["slackware", "Slackware", 0xF318], ["mageia", "Mageia", 0xF310], ["rocky", "Rocky", 0xF32B]
    ]
    readonly property string logoGlyph: {
        const k = page.v("logo", "auto")
        for (let i = 0; i < logos.length; i++) if (logos[i][0] === k && logos[i][2] !== 0) return String.fromCodePoint(logos[i][2])
        return page.ctl && page.ctl.osGlyph ? page.ctl.osGlyph() : "\uf17c"
    }
    readonly property var lay: qb.layout ? qb.layout : ({ left: [], center: [], right: [] })

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

            // ---------- live preview ----------
            Rectangle {
                id: prev
                width: parent.width
                height: 128
                radius: 16
                clip: true
                border.width: 1
                border.color: "#1f1f1f"
                gradient: Gradient {
                    GradientStop { position: 0; color: "#2a2740" }
                    GradientStop { position: 1; color: "#12131a" }
                }
                readonly property string sty: page.v("style", "islands")
                readonly property bool atTop: page.v("position", "top") === "top"
                readonly property real alpha: page.v("opacity", 0.72)
                readonly property real h: 30 + (page.v("height", 38) - 38) * 0.5
                readonly property color pill: Qt.rgba(0.05, 0.05, 0.05, Math.min(1, alpha + 0.12))

                Rectangle { x: 60; y: prev.atTop ? 60 : 18; width: prev.width - 120; height: 50; radius: 10; color: Qt.rgba(1, 1, 1, 0.05) }

                // a zone: chips in a row, with or without a pill behind
                component PZone: Rectangle {
                    id: pz
                    property var mods: []
                    property bool soft: false
                    visible: mods.length > 0
                    height: prev.h
                    width: pr.width + (soft ? 18 : 0)
                    radius: height / 2
                    color: soft ? prev.pill : "transparent"
                    border.width: soft ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    Row {
                        id: pr
                        anchors.centerIn: parent
                        spacing: prev.sty === "pills" ? 6 : 10
                        Repeater {
                            model: pz.mods
                            delegate: Rectangle {
                                readonly property bool pl: prev.sty === "pills"
                                height: prev.h; width: pg.implicitWidth + (pl ? 18 : 0); radius: height / 2
                                color: pl ? prev.pill : "transparent"
                                border.width: pl ? 1 : 0; border.color: Qt.rgba(1, 1, 1, 0.1)
                                T { id: pg; anchors.centerIn: parent; kind: modelData === "clock" || modelData === "battery" || modelData === "workspaces" ? "" : "icon"
                                    text: modelData === "workspaces" ? page.wsText : modelData === "launcher" ? page.logoGlyph : (page.glyph[modelData] !== undefined ? page.glyph[modelData] : "•")
                                    font.pixelSize: 12; color: "#e8e8ec" }
                            }
                        }
                    }
                }

                Item {
                    id: pbar
                    readonly property bool flat: prev.sty === "flat"
                    x: flat ? 0 : 12; width: parent.width - (flat ? 0 : 24)
                    height: prev.h
                    y: prev.atTop ? (flat ? 0 : 10) : parent.height - height - (flat ? 0 : 10)
                    Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.fill: parent
                        visible: prev.sty === "flat" || prev.sty === "island"
                        radius: prev.sty === "island" ? height / 2 : 0
                        color: prev.pill
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)
                    }
                    readonly property real edge: prev.sty === "island" ? 14 : (prev.sty === "flat" ? 12 : 0)
                    PZone { x: pbar.edge; mods: page.lay.left || []; soft: prev.sty === "islands" }
                    PZone { x: (pbar.width - width) / 2; mods: page.lay.center || []; soft: prev.sty === "islands" }
                    PZone { x: pbar.width - width - pbar.edge; mods: page.lay.right || []; soft: prev.sty === "islands" }
                }
                T { text: "Preview"; font.pixelSize: 10; color: "#7a7a84"; anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 8 }
            }

            // ---------- bar layout shortcut ----------
            Rectangle {
                width: parent.width; height: 62; radius: 14
                color: blMouse.containsMouse ? "#1c1c1c" : "#161616"
                border.width: 1; border.color: "#1f1f1f"
                Behavior on color { ColorAnimation { duration: 120 } }
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 18; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                    T { text: "Bar layout"; font.pixelSize: 14; font.bold: true }
                    T { kind: "reading"; text: "Drag modules around: left, center, right, order"; color: "#8a8a8a"; font.pixelSize: 12 }
                }
                T { kind: "icon"; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: ""; color: "#8a8a8a" }
                MouseArea { id: blMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.ctl.page = 3 }
            }

            T { kind: "title"; text: "Style"; font.pixelSize: 16; font.bold: true; topPadding: 10 }
            SegRow {
                label: "Bar style"
                desc: "Flat bar, one floating pill, an island for each side, or a pill for every module"
                options: [ { label: "Flat", value: "flat" }, { label: "Island", value: "island" }, { label: "Islands", value: "islands" }, { label: "Pills", value: "pills" } ]
                current: page.v("style", "islands")
                onChosen: function(x) { page.setv("style", x) }
            }
            SegRow {
                label: "Position"
                desc: "Top or bottom edge of the screen"
                options: [ { label: "Top", value: "top" }, { label: "Bottom", value: "bottom" } ]
                current: page.v("position", "top")
                onChosen: function(x) { page.setv("position", x) }
            }
            SegRow {
                label: "Size"
                desc: "How tall the bar is"
                options: [ { label: "Compact", value: "32" }, { label: "Normal", value: "38" }, { label: "Large", value: "46" } ]
                current: String(page.v("height", 38))
                onChosen: function(x) { page.setv("height", x) }
            }
            SliderRow {
                label: "Transparency"
                desc: "Lower is more see-through. Blur sits behind it when blur is on"
                from: 0.3; to: 1; step: 0.02; decimals: 2
                value: page.v("opacity", 0.72)
                onCommitted: function(x) { page.setv("opacity", x.toFixed(2)) }
            }

            // ---------- launcher icon ----------
            T { kind: "title"; text: "Launcher icon"; font.pixelSize: 16; font.bold: true; topPadding: 10 }
            T { kind: "reading"; text: "The button that opens the launcher. Auto picks the logo of the system you run."; color: "#8a8a8a"; font.pixelSize: 12 }
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: page.logos
                    delegate: Rectangle {
                        readonly property bool sel: page.v("logo", "auto") === modelData[0]
                        width: 78; height: 72; radius: 14
                        color: sel ? "#F6F5F4" : (lgm.containsMouse ? "#1c1c1c" : "#141414")
                        border.width: 1; border.color: sel ? "#F6F5F4" : "#1f1f1f"
                        scale: lgm.pressed ? 0.94 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        T { kind: modelData[2] === 0 ? "" : "icon"; anchors.horizontalCenter: parent.horizontalCenter; y: 12
                            text: modelData[2] === 0 ? "AUTO" : String.fromCodePoint(modelData[2])
                            font.pixelSize: modelData[2] === 0 ? 13 : 24; font.bold: modelData[2] === 0
                            color: parent.sel ? "#0d0d0d" : "#F6F5F4" }
                        T { anchors.horizontalCenter: parent.horizontalCenter; y: 48; text: modelData[1]; font.pixelSize: 10
                            color: parent.sel ? "#0d0d0d" : "#8a8a8a"; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                        MouseArea { id: lgm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.setv("logo", modelData[0]) }
                    }
                }
            }

            T { kind: "title"; text: "Content"; font.pixelSize: 16; font.bold: true; topPadding: 10 }
            SegRow {
                label: "Workspaces"
                desc: "How many dots are always shown (more appear when you use them)"
                options: [ { label: "4", value: "4" }, { label: "5", value: "5" }, { label: "6", value: "6" }, { label: "8", value: "8" } ]
                current: String(page.v("workspaces", 5))
                onChosen: function(x) { page.setv("workspaces", x) }
            }
            SegRow {
                label: "Workspace style"
                desc: "Dots, Pac-Man running to the workspace you open, letters or numbers"
                options: [ { label: "Dots", value: "dots" }, { label: "Pac-Man", value: "pacman" }, { label: "Letters", value: "letters" }, { label: "Numbers", value: "numbers" } ]
                current: page.v("ws_style", "dots")
                onChosen: function(x) { page.setv("ws_style", x) }
            }
            ToggleRow {
                label: "Seconds"
                desc: "Show seconds in the clock"
                checked: page.v("seconds", false) === true
                onToggled: function(x) { page.setv("seconds", x ? "on" : "off") }
            }

            T { kind: "title"; text: "Old bar"; font.pixelSize: 16; font.bold: true; topPadding: 10 }
            ToggleRow {
                label: "Use Waybar instead"
                desc: "Go back to the old Waybar if the DarkShadow bar gives you trouble. Waybar needs to be installed"
                checked: page.v("enabled", true) !== true
                onToggled: function(x) { Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-bar\" " + (x ? "off" : "on")]); page.ctl.status = x ? "Waybar" : "DarkShadow bar"; refresh.restart() }
            }
        }
    }
}
