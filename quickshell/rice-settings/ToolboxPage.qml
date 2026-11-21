import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Desktop > Toolbox: the sheet with tasks, a note, a focus timer, a converter, the system and a chat
// (SUPER + X). Which edge it comes from, how wide it is, which tabs it has, and its key. rice-tools state / set.
Item {
    id: page
    property var ctl
    property var st: ({ side: "right", width: 440, dim: true, outside: true, remember: true, tab: "tasks",
                        tabs: ["tasks", "note", "timer", "convert", "system", "chat"], all: ["tasks", "note", "timer", "convert", "system", "chat"], keys: "SUPER + X" })
    readonly property var names: ({ tasks: "Tasks", note: "Note", timer: "Timer", convert: "Convert", system: "System", chat: "Chat" })
    readonly property var syms: ({ tasks: "checklist", note: "sticky_note_2", timer: "timer", convert: "swap_horiz", system: "monitoring", chat: "forum" })
    function sh(args) { runner.command = ["bash", "-c", "\"$HOME/.local/bin/rice-tools\" \"$@\" 2>&1", "_"].concat(args); runner.running = true }
    function put(k, v, arg) { const n = Object.assign({}, page.st); n[k] = v; page.st = n; page.sh(["set", k, arg]) }
    function nice(k) { return String(k).split(" + ").map(function(p) { return p.length > 1 ? p.charAt(0) + p.slice(1).toLowerCase() : p }).join(" + ") }
    function setTabs(l) { if (l.length > 0) page.put("tabs", l, l.join(",")) }
    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-tools\" state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.st = JSON.parse(text) } catch (e) { } } }
    }
    Process { id: runner; stdout: StdioCollector { onStreamFinished: stateLater.restart() } }
    Timer { id: stateLater; interval: 350; onTriggered: stateProc.running = true }
    Process { id: keyProc; onExited: stateLater.restart() }
    onVisibleChanged: if (visible) stateProc.running = true

    PageScroll {
        anchors.fill: parent

        // ---------- a small screen that shows where the sheet is ----------
        Rectangle {
            width: parent.width
            height: 230
            radius: M3.rXL
            color: M3.primaryContainer
            clip: true
            Column {
                x: 26; anchors.verticalCenter: parent.verticalCenter; spacing: 8; width: parent.width - 360
                T { text: I18n.t("Toolbox"); font.pixelSize: 26; font.weight: Font.DemiBold; color: M3.inkPrimaryC }
                T { width: parent.width; wrapMode: Text.Wrap; font.pixelSize: 13; color: M3.inkPrimaryC; opacity: 0.8
                    text: I18n.t("Tasks, a note, a focus timer, a converter, the system and a chat, on a sheet at the edge of the screen.") }
                Row { spacing: 8; topPadding: 6
                    Btn { primary: true; text: I18n.t("Open it"); sym: "open_in_new"
                        onClicked: Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-tools\" open"]) }
                    Rectangle { height: 40; width: kt.implicitWidth + 28; radius: 20 * M3.shapeK; color: M3.alpha(M3.inkPrimaryC, 0.12)
                        T { id: kt; anchors.centerIn: parent; text: page.nice(page.st.keys || "SUPER + X"); font.pixelSize: 13; font.weight: Font.DemiBold; color: M3.inkPrimaryC } } }
            }
            Rectangle {
                id: scr
                width: 290; height: 174; radius: 16
                anchors.right: parent.right; anchors.rightMargin: 26; anchors.verticalCenter: parent.verticalCenter
                color: M3.surfaceLowest
                clip: true
                // windows behind it
                Rectangle { x: 14; y: 26; width: 120; height: 78; radius: 8; color: M3.alpha(M3.ink, 0.08) }
                Rectangle { x: 144; y: 26; width: 132; height: 134; radius: 8; color: M3.alpha(M3.ink, 0.06) }
                Rectangle { x: 14; y: 112; width: 120; height: 48; radius: 8; color: M3.alpha(M3.ink, 0.05) }
                Rectangle { anchors.fill: parent; radius: scr.radius; color: "black"; opacity: page.st.dim !== false ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: 240 } } }
                Rectangle {
                    id: mini
                    readonly property real w: 60 + ((page.st.width || 440) - 360) / 200 * 40
                    width: w; height: parent.height - 12; y: 6; radius: 12
                    Behavior on height { NumberAnimation { duration: 420; easing.type: M3.springy; easing.overshoot: 1.1 } }
                    opacity: page.st.opacity === undefined ? 0.8 : Math.max(0.35, page.st.opacity)
                    clip: true
                    x: page.st.side === "left" ? 6 : parent.width - w - 6
                    Behavior on x { NumberAnimation { duration: 520; easing.type: M3.springy; easing.overshoot: 1.1 } }
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    color: M3.surfaceHigh
                    border.width: 1; border.color: M3.outlineVariant
                    Rectangle { x: 8; y: 8; width: 16; height: 16; radius: 6; color: M3.primary }
                    Rectangle { x: 30; y: 12; width: parent.width - 42; height: 7; radius: 3.5; color: M3.alpha(M3.ink, 0.5) }
                    Column { x: 8; y: 34; spacing: 5
                        Repeater { model: 4; Rectangle { width: mini.width - 16; height: 16; radius: 6; color: M3.alpha(M3.ink, 0.1) } } }
                    Row { x: 6; y: parent.height - 22; spacing: 3
                        Repeater { model: (page.st.tabs || []).length
                            Rectangle { width: (mini.width - 12 - 3 * ((page.st.tabs || []).length - 1)) / Math.max(1, (page.st.tabs || []).length); height: 14; radius: 7
                                color: index === 0 ? M3.primary : M3.alpha(M3.ink, 0.14) } } }
                }
            }
        }

        SectionTitle { text: I18n.t("Where and how") }
        SettingRow {
            label: I18n.t("Side of the screen")
            desc: page.st.side === "left" ? I18n.t("It comes out of the left edge") : I18n.t("It comes out of the right edge")
            reserved: 300
            Seg {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                options: [{ value: "left", label: I18n.t("Left") }, { value: "right", label: I18n.t("Right") }]
                current: page.st.side || "right"
                onChosen: v => page.put("side", v, v)
            }
        }
        SliderRow {
            label: I18n.t("Width")
            desc: I18n.t("How wide the sheet is")
            from: 360; to: 560; step: 10; decimals: 0; unit: " px"
            value: page.st.width || 440
            onCommitted: function(v) { page.put("width", Math.round(v), String(Math.round(v))) }
        }
        SliderRow {
            label: I18n.t("Transparency")
            desc: I18n.t("How much of what is behind the sheet shows through it")
            from: 0; to: 70; step: 1; decimals: 0; unit: "%"
            value: Math.round((1 - (page.st.opacity === undefined ? 0.8 : page.st.opacity)) * 100)
            onCommitted: function(v) { const o = Math.round((1 - v / 100) * 100) / 100; page.put("opacity", o, String(o)) }
        }
        ToggleRow {
            label: I18n.t("Blur behind it")
            desc: I18n.t("What shows through the sheet is blurred, like frosted glass")
            checked: page.st.blur !== false
            onToggled: function(v) { page.put("blur", v, v ? "on" : "off") }
        }
        ToggleRow {
            label: I18n.t("Dim the screen behind it")
            desc: I18n.t("The rest of the screen gets a little darker while the toolbox is open")
            checked: page.st.dim !== false
            onToggled: function(v) { page.put("dim", v, v ? "on" : "off") }
        }
        ToggleRow {
            label: I18n.t("A click outside closes it")
            desc: I18n.t("Off: only its key, the X or Esc close it")
            checked: page.st.outside !== false
            onToggled: function(v) { page.put("outside", v, v ? "on" : "off") }
        }
        ToggleRow {
            label: I18n.t("Open on the tab I used last")
            desc: I18n.t("Off: it always opens on the first tab below")
            checked: page.st.remember !== false
            onToggled: function(v) { page.put("remember", v, v ? "on" : "off"); if (!v && page.st.tabs.length) page.sh(["set", "tab", page.st.tabs[0]]) }
        }

        SectionTitle { text: I18n.t("Tabs"); sub: I18n.t("Turn off the ones you do not use, and put them in your order with the arrows. Ctrl + 1 ... 6 goes straight to one.") }
        Repeater {
            model: (page.st.tabs || []).concat((page.st.all || []).filter(k => (page.st.tabs || []).indexOf(k) < 0))
            delegate: SettingRow {
                id: trow
                required property string modelData
                required property int index
                readonly property bool on: (page.st.tabs || []).indexOf(modelData) >= 0
                readonly property int at: (page.st.tabs || []).indexOf(modelData)
                label: I18n.t(page.names[modelData])
                desc: on ? "Ctrl + " + (at + 1) : I18n.t("Hidden")
                reserved: 220
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                    Repeater {
                        model: [{ d: -1, s: "arrow_upward" }, { d: 1, s: "arrow_downward" }]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool can: trow.on && trow.at + modelData.d >= 0 && trow.at + modelData.d < page.st.tabs.length
                            width: 36; height: 36; radius: 18 * M3.shapeK; anchors.verticalCenter: parent.verticalCenter
                            color: am.containsMouse && can ? M3.surfaceHighest : M3.surfaceHigh
                            opacity: can ? 1 : 0.3
                            Icon { anchors.centerIn: parent; name: parent.modelData.s; glyph: parent.modelData.d < 0 ? "\uf062" : "\uf063"; size: 18; color: M3.ink }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; enabled: parent.can; cursorShape: Qt.PointingHandCursor
                                onClicked: { const l = page.st.tabs.slice(); const i = trow.at, j = i + parent.modelData.d; const x = l[i]; l[i] = l[j]; l[j] = x; page.setTabs(l) } }
                        }
                    }
                    Tog {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: trow.on
                        onToggled: {
                            const l = page.st.tabs.slice()
                            if (trow.on) { if (l.length > 1) { l.splice(trow.at, 1); page.setTabs(l) } }
                            else { l.push(trow.modelData); page.setTabs(l) }
                        }
                    }
                }
            }
        }

        SectionTitle { text: I18n.t("Key"); sub: I18n.t("Any other key: Settings > System > Keybinds, the pencil next to Toolbox.") }
        SettingRow {
            label: I18n.t("Open and close the toolbox")
            desc: page.nice(page.st.keys || "SUPER + X")
            reserved: 520
            Seg {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                options: ["SUPER + X", "SUPER + B", "SUPER + ALT + T"].map(function(c) { return { value: c, label: page.nice(c) } })
                current: page.st.keys || "SUPER + X"
                onChosen: v => { const n = Object.assign({}, page.st); n.keys = v; page.st = n
                                 keyProc.command = ["bash", "-c", "\"$HOME/.local/bin/rice-keymap\" set tools \"$1\"", "_", v]; keyProc.running = true }
            }
        }
        SettingRow {
            label: I18n.t("Inside the toolbox")
            desc: I18n.t("Ctrl + Tab: the next tab  ·  Ctrl + 1 ... 6: that tab  ·  Esc: close")
        }
    }
}
