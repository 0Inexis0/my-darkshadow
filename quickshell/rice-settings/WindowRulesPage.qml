import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Desktop > Window rules: your own rules (where an app opens, floating, size, see-through ...) and an
// optional gaming workspace. Kept by rice-rules in ~/.config/rice/rules.json: updates never touch them.
Item {
    id: page
    property var ctl

    property var gaming: ({ on: false, ws: "9", launchers: true, fullscreen: false, nogaps: true, follow: true })
    property var rules: []
    property bool niri: !!Quickshell.env("NIRI_SOCKET")
    property bool loaded: false

    Process {
        id: listProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-rules\" list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { const j = JSON.parse(text); page.gaming = j.gaming; page.rules = j.rules; page.niri = j.niri; page.loaded = true } catch (e) { }
            }
        }
    }
    function save(msg) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-rules\" save \"$1\"", "_",
                                 JSON.stringify({ gaming: page.gaming, rules: page.rules })])
        page.ctl.status = msg
    }
    function setG(k, v) { const n = Object.assign({}, gaming); n[k] = v; gaming = n; save(I18n.t("Gaming workspace saved")) }
    function setRules(list, msg) { rules = list; save(msg) }

    // ---------- the editor (a new rule, or one you touched) ----------
    readonly property var blank: ({ on: true, by: "class", match: "", name: "", float: false, center: false, w: 0, h: 0,
                                    ws: "", silent: false, opacity: 1.0, fullscreen: false, maximize: false, pin: false })
    property int editIdx: -2                   // -2 closed, -1 a new rule, n: rule n
    property var draft: blank
    function openEditor(i) { editIdx = i; draft = JSON.parse(JSON.stringify(i >= 0 ? rules[i] : blank)); winProc.running = true }
    function setD(k, v) { const n = Object.assign({}, draft); n[k] = v; draft = n }
    function rx(s) { return "^" + s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$" }
    function commit() {
        const d = Object.assign({}, draft)
        d.match = String(d.match).trim()
        if (!d.match.length) { page.ctl.status = I18n.t("Pick a window or type an app id first"); return }
        const l = rules.slice()
        if (editIdx >= 0) l[editIdx] = d; else l.push(d)
        editIdx = -2
        setRules(l, I18n.t("Window rule saved"))
    }
    function summary(r) {
        const s = []
        if (r.ws) s.push(I18n.t("workspace ") + r.ws + (r.silent ? I18n.t(" (in the background)") : ""))
        if (r.float || r.pin) s.push(I18n.t("floating"))
        if (r.center) s.push(I18n.t("centered"))
        if (r.w && r.h) s.push(r.w + " × " + r.h)
        if (r.pin) s.push(I18n.t("on every workspace"))
        if (r.fullscreen) s.push(I18n.t("fullscreen")); else if (r.maximize) s.push(I18n.t("maximized"))
        if (r.opacity < 0.999) s.push(Math.round(r.opacity * 100) + "%")
        return s.length ? s.join("  ·  ") : I18n.t("nothing set yet")
    }

    property var openWins: []
    Process {
        id: winProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-rules\" windows"]
        stdout: StdioCollector { onStreamFinished: { try { page.openWins = JSON.parse(text) } catch (e) { page.openWins = [] } } }
    }

    component Head: Row {
        property string icon: ""
        property string glyph: ""
        property string title: ""
        property string sub: ""
        width: parent ? parent.width : 400
        spacing: 14
        topPadding: 18
        Item {
            width: 40; height: 40
            Blob { anchors.fill: parent; kind: Prefs.accentShape; color: M3.secondaryContainer }
            Icon { anchors.centerIn: parent; name: parent.parent.icon; glyph: parent.parent.glyph; size: 18; color: M3.inkSecondaryC }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 60
            spacing: 2
            T { kind: "title"; text: parent.parent.title; font.pixelSize: 17; font.weight: Font.DemiBold }
            T { kind: "reading"; text: parent.parent.sub; font.pixelSize: 12; color: M3.inkDim; width: parent.width; wrapMode: Text.WordWrap }
        }
    }
    // a small pill you can switch on and off
    component Opt: Rectangle {
        id: o
        property string text: ""
        property bool on: false
        signal toggled(bool v)
        height: 36; width: ot.implicitWidth + (o.on ? 50 : 32); radius: o.on ? 12 * M3.shapeK : 18 * M3.shapeK
        color: o.on ? M3.secondaryContainer : (om.containsMouse ? M3.surfaceHighest : "transparent")
        border.width: o.on ? 0 : 1; border.color: M3.outlineVariant
        Behavior on radius { NumberAnimation { duration: 180 } }
        Behavior on width { NumberAnimation { duration: 160 } }
        Row {
            anchors.centerIn: parent; spacing: 6
            Icon { visible: o.on; name: "check"; glyph: ""; size: 15; color: M3.inkSecondaryC; anchors.verticalCenter: parent.verticalCenter }
            T { id: ot; text: o.text; font.pixelSize: 13; font.weight: Font.Medium; color: o.on ? M3.inkSecondaryC : M3.ink; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: o.toggled(!o.on) }
    }

    PageScroll {
        anchors.fill: parent

        // ---------- hero ----------
        Rectangle {
            width: parent.width; height: 132; radius: M3.rXL; clip: true
            gradient: Gradient { GradientStop { position: 0; color: M3.stageTop } GradientStop { position: 1; color: M3.stageBottom } }
            // three little windows: one floating, two tiled, in your colors
            Item {
                anchors.right: parent.right; anchors.rightMargin: 26; anchors.verticalCenter: parent.verticalCenter
                width: 170; height: 92
                Rectangle { x: 0; y: 0; width: 80; height: 92; radius: 10; color: M3.surfaceHigh; border.width: 2; border.color: M3.outlineVariant }
                Rectangle { x: 86; y: 0; width: 84; height: 92; radius: 10; color: M3.surfaceHigh; border.width: 2; border.color: M3.outlineVariant }
                Rectangle {
                    id: fl; x: 44; y: 18; width: 86; height: 56; radius: 12; color: M3.primaryContainer; border.width: 2; border.color: M3.primary
                    Icon { anchors.centerIn: parent; name: "picture_in_picture"; glyph: ""; size: 20; color: M3.inkPrimaryC }
                    SequentialAnimation on y {
                        running: page.visible; loops: Animation.Infinite
                        NumberAnimation { to: 12; duration: 1800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 22; duration: 1800; easing.type: Easing.InOutSine }
                    }
                }
            }
            Column {
                x: 26; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 250; spacing: 6
                T { kind: "title"; text: I18n.t("Window rules"); font.pixelSize: 24; font.weight: Font.Medium }
                T { kind: "reading"; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 12; color: M3.inkDim
                    text: I18n.t("Tell apps where to open and how. Your rules are yours: updates never change or remove them.") }
            }
        }

        // ---------- gaming workspace ----------
        Head { icon: "sports_esports"; glyph: ""; title: I18n.t("Gaming workspace")
               sub: I18n.t("Games (Steam, Proton, Wine, gamescope, Minecraft) open on their own workspace.") }
        ToggleRow {
            label: I18n.t("Use a gaming workspace")
            desc: page.gaming.on ? I18n.t("Games go to workspace ") + page.gaming.ws : I18n.t("Off: games open where you are")
            checked: page.gaming.on === true
            onToggled: function(v) { page.setG("on", v) }
        }
        Column {
            width: parent.width; spacing: 10
            visible: page.gaming.on === true
            SettingRow {
                label: I18n.t("Which workspace")
                desc: page.niri ? I18n.t("A name or a number. niri makes a named workspace for it") : I18n.t("A number (1 to 10 are on SUPER + 1 ... 0) or a name")
                reserved: 150
                Field {
                    id: gwsField
                    anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 110; height: 40
                    text: page.gaming.ws
                    onAccepted: { const v = text.trim(); if (/^[A-Za-z0-9_-]{1,24}$/.test(v)) page.setG("ws", v); else page.ctl.status = I18n.t("Letters, numbers, - and _ only") }
                }
            }
            Flow {
                width: parent.width; spacing: 8
                Opt { text: I18n.t("Go there when a game starts"); on: page.gaming.follow; onToggled: function(v) { page.setG("follow", v) } }
                Opt { text: I18n.t("Launchers there too"); on: page.gaming.launchers; onToggled: function(v) { page.setG("launchers", v) } }
                Opt { text: I18n.t("Games open fullscreen"); on: page.gaming.fullscreen; onToggled: function(v) { page.setG("fullscreen", v) } }
                Opt { visible: !page.niri; text: I18n.t("No gaps there"); on: page.gaming.nogaps; onToggled: function(v) { page.setG("nogaps", v) } }
            }
        }

        // ---------- your rules ----------
        Head { icon: "rule"; glyph: ""; title: I18n.t("Your rules")
               sub: I18n.t("Pick a window that is open now, or type its app id. A rule works the next time the app opens.") }

        Repeater {
            model: page.rules
            delegate: Rectangle {
                width: parent ? parent.width : 400; height: 72; radius: M3.rL
                color: rh.hovered ? M3.surfaceHigh : M3.surfaceC
                opacity: modelData.on ? 1 : 0.6
                HoverHandler { id: rh }
                Rectangle {
                    x: 16; anchors.verticalCenter: parent.verticalCenter; width: 40; height: 40; radius: 14
                    color: modelData.on ? M3.primaryContainer : M3.surfaceHighest
                    Icon { anchors.centerIn: parent; name: modelData.by === "title" ? "title" : "apps"; glyph: ""; size: 18
                           color: modelData.on ? M3.inkPrimaryC : M3.inkDim }
                }
                Column {
                    x: 70; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 70 - 190; spacing: 3
                    T { width: parent.width; elide: Text.ElideRight; font.pixelSize: 14; font.weight: Font.Medium
                        text: modelData.name || modelData.match.replace(/^\^|\$$/g, "").replace(/\\/g, "") }
                    T { kind: "reading"; width: parent.width; elide: Text.ElideRight; font.pixelSize: 12; color: M3.inkDim
                        text: page.summary(modelData) }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                    Tog { anchors.verticalCenter: parent.verticalCenter; checked: modelData.on
                          onToggled: function(v) { const l = JSON.parse(JSON.stringify(page.rules)); l[index].on = v; page.setRules(l, v ? I18n.t("Rule on") : I18n.t("Rule off")) } }
                    Btn { variant: "text"; width: 44; sym: "edit"; icon: ""; anchors.verticalCenter: parent.verticalCenter; onClicked: page.openEditor(index) }
                    Btn { variant: "text"; width: 44; sym: "delete"; icon: ""; anchors.verticalCenter: parent.verticalCenter
                          onClicked: { const l = page.rules.slice(); l.splice(index, 1); if (page.editIdx === index) page.editIdx = -2; page.setRules(l, I18n.t("Rule removed")) } }
                }
            }
        }
        T {
            visible: page.loaded && page.rules.length === 0 && page.editIdx === -2
            width: parent.width; topPadding: 4; bottomPadding: 4
            text: I18n.t("No rules yet. Make one: for example Discord always on workspace 3, or a calculator that floats.")
            font.pixelSize: 13; color: M3.inkDim; wrapMode: Text.WordWrap
        }
        Btn {
            visible: page.editIdx === -2
            text: I18n.t("New rule"); sym: "add"; icon: ""; primary: true
            onClicked: page.openEditor(-1)
        }

        // ---------- the editor ----------
        Rectangle {
            visible: page.editIdx !== -2
            width: parent.width; radius: M3.rXL; color: M3.surfaceC
            border.width: 2; border.color: M3.alpha(M3.primary, 0.5)
            height: ed.implicitHeight + 40
            Column {
                id: ed
                x: 20; y: 20; width: parent.width - 40; spacing: 12
                T { kind: "title"; text: page.editIdx >= 0 ? I18n.t("Edit rule") : I18n.t("New rule"); font.pixelSize: 18; font.weight: Font.DemiBold }

                T { text: I18n.t("Which window"); font.pixelSize: 13; font.weight: Font.Medium; color: M3.inkDim }
                Flow {
                    width: parent.width; spacing: 8
                    visible: page.openWins.length > 0
                    Repeater {
                        model: page.openWins.slice(0, 14)
                        delegate: Opt {
                            text: modelData.cls || modelData.title
                            on: page.draft.match === page.rx(page.draft.by === "title" ? modelData.title : (modelData.cls || ""))
                            onToggled: { if (modelData.cls) { page.setD("by", "class"); page.setD("match", page.rx(modelData.cls)) }
                                         else { page.setD("by", "title"); page.setD("match", page.rx(modelData.title)) } }
                        }
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    Seg {
                        id: bySeg
                        anchors.verticalCenter: parent.verticalCenter
                        options: [{ value: "class", label: I18n.t("App id") }, { value: "title", label: I18n.t("Title") }]
                        current: page.draft.by
                        onChosen: function(v) { page.setD("by", v) }
                    }
                    Field {
                        width: parent.width - bySeg.width - 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.draft.match
                        placeholder: I18n.t("e.g. ^discord$  (a regex: ^ start, $ end)")
                        onTextChanged: if (text !== page.draft.match) page.setD("match", text)
                    }
                }
                Field {
                    width: parent.width
                    text: page.draft.name
                    placeholder: I18n.t("A name for it (optional)")
                    onTextChanged: if (text !== page.draft.name) page.setD("name", text)
                }

                T { text: I18n.t("What it does"); font.pixelSize: 13; font.weight: Font.Medium; color: M3.inkDim; topPadding: 4 }
                Flow {
                    width: parent.width; spacing: 8
                    Opt { text: I18n.t("Float"); on: page.draft.float; onToggled: function(v) { page.setD("float", v) } }
                    Opt { visible: !page.niri; text: I18n.t("Center"); on: page.draft.center; onToggled: function(v) { page.setD("center", v) } }
                    Opt { visible: !page.niri; text: I18n.t("On every workspace"); on: page.draft.pin; onToggled: function(v) { page.setD("pin", v) } }
                    Opt { text: I18n.t("Fullscreen"); on: page.draft.fullscreen; onToggled: function(v) { page.setD("fullscreen", v); if (v) page.setD("maximize", false) } }
                    Opt { text: I18n.t("Maximized"); on: page.draft.maximize; onToggled: function(v) { page.setD("maximize", v); if (v) page.setD("fullscreen", false) } }
                }
                Row {
                    spacing: 10
                    T { text: I18n.t("Workspace"); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: 110 }
                    Field {
                        width: 90; height: 40; anchors.verticalCenter: parent.verticalCenter
                        text: page.draft.ws; placeholder: I18n.t("any")
                        onTextChanged: if (text !== page.draft.ws) page.setD("ws", text.trim())
                    }
                    Opt { anchors.verticalCenter: parent.verticalCenter; visible: page.draft.ws.length > 0
                          text: I18n.t("Open it in the background"); on: page.draft.silent; onToggled: function(v) { page.setD("silent", v) } }
                }
                Row {
                    spacing: 10
                    T { text: I18n.t("Size"); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: 110 }
                    Field { width: 90; height: 40; anchors.verticalCenter: parent.verticalCenter; text: page.draft.w ? String(page.draft.w) : ""; placeholder: I18n.t("width")
                            onTextChanged: { const n = parseInt(text) || 0; if (n !== page.draft.w) page.setD("w", n) } }
                    T { text: "×"; anchors.verticalCenter: parent.verticalCenter; color: M3.inkDim }
                    Field { width: 90; height: 40; anchors.verticalCenter: parent.verticalCenter; text: page.draft.h ? String(page.draft.h) : ""; placeholder: I18n.t("height")
                            onTextChanged: { const n = parseInt(text) || 0; if (n !== page.draft.h) page.setD("h", n) } }
                    T { text: I18n.t("px  (both, or none)"); anchors.verticalCenter: parent.verticalCenter; color: M3.inkDim; font.pixelSize: 12 }
                }
                SliderRow {
                    width: parent.width
                    label: I18n.t("Opacity"); desc: I18n.t("100%: solid")
                    from: 30; to: 100; step: 5; unit: "%"
                    value: Math.round(page.draft.opacity * 100)
                    onCommitted: function(v) { page.setD("opacity", v / 100) }
                }
                Row {
                    spacing: 10; topPadding: 4
                    Btn { text: I18n.t("Save rule"); sym: "check"; icon: ""; primary: true; onClicked: page.commit() }
                    Btn { text: I18n.t("Cancel"); variant: "text"; onClicked: page.editIdx = -2 }
                }
            }
        }

        // ---------- the rest ----------
        Rectangle {
            width: parent.width; height: hint.implicitHeight + 32; radius: M3.rL; color: M3.alpha(M3.tertiary, 0.12)
            T {
                id: hint
                x: 18; y: 16; width: parent.width - 36; wrapMode: Text.WordWrap; font.pixelSize: 12; color: M3.ink
                text: page.niri
                      ? I18n.t("Need more? Your own niri settings go in ~/.config/niri/user.kdl. It is loaded last and updates never touch it.")
                      : I18n.t("Need more? Your own Hyprland settings go in ~/.config/hypr/user.lua. It is loaded last and updates never touch it. Edits to hyprland.lua are lost on update.")
            }
        }
        Item { width: 1; height: 12 }
    }
}
