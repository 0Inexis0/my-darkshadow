import Quickshell
import Quickshell.Io
import QtQuick

// Settings > System > Keyboard: the keyboard layouts you type with (up to 4), the one in use now, how to switch
// between them, and a search over every layout of this computer (xkeyboard-config). Saved by hypr-set.
Item {
    id: page
    property var ctl
    property var st: ({ layouts: [], active: "", options: "", all: [] })
    property string q: ""
    function nameOf(id) { const l = st.all || []; for (let i = 0; i < l.length; i++) if (l[i].id === id) return l[i].name; return id.toUpperCase() }
    readonly property var found: {
        const l = st.all || [], s = q.trim().toLowerCase(), out = []
        for (let i = 0; i < l.length && out.length < 60; i++)
            if (!s || l[i].name.toLowerCase().indexOf(s) >= 0 || l[i].id.indexOf(s) === 0) out.push(l[i])
        return out
    }
    function run(args) {
        setProc.command = ["bash", "-c", "\"$HOME/.local/bin/hypr-set\" \"$@\" 2>&1", "_"].concat(args)
        setProc.running = true
    }
    function setLayouts(list) { const n = Object.assign({}, st); n.layouts = list; st = n; run(["kbd-set", list.join(",")]) }
    function add(id) { if (st.layouts.indexOf(id) >= 0 || st.layouts.length >= 4) return; setLayouts(st.layouts.concat([id])) }
    function remove(id) { if (st.layouts.length <= 1) return; setLayouts(st.layouts.filter(function(x) { return x !== id })) }
    function first(id) { setLayouts([id].concat(st.layouts.filter(function(x) { return x !== id }))) }

    Process {
        id: stProc
        command: ["bash", "-c", "\"$HOME/.local/bin/hypr-set\" kbd-state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.st = JSON.parse(text) } catch (e) { } } }
    }
    Process {
        id: setProc
        stdout: StdioCollector { onStreamFinished: { page.ctl.status = text.trim(); again.restart() } }
    }
    Timer { id: again; interval: 600; onTriggered: stProc.running = true }
    Timer { interval: 3000; running: page.visible; repeat: true; onTriggered: if (!stProc.running) stProc.running = true }

    PageScroll {
        anchors.fill: parent

        // ---------- now ----------
        Rectangle {
            width: parent.width
            height: 140
            radius: M3.rXL
            color: M3.primaryContainer
            clip: true
            // a few key caps
            Grid {
                anchors.right: parent.right; anchors.rightMargin: 24; anchors.verticalCenter: parent.verticalCenter
                columns: 4; spacing: 6
                rotation: -8
                Repeater {
                    model: (page.st.layouts[0] === "pl" ? "ĄĘÓŚŁŻŹĆ" : page.st.layouts[0] === "de" ? "ÄÖÜßQWER" : page.st.layouts[0] === "fr" ? "AZERÉÈÇÀ" : "QWERASDF").split("")
                    delegate: Rectangle { width: 34; height: 34; radius: 9; color: M3.alpha(M3.inkPrimaryC, index === 0 ? 0.3 : 0.12)
                        T { anchors.centerIn: parent; text: modelData; font.pixelSize: 14; font.weight: Font.Medium; color: M3.inkPrimaryC } }
                }
            }
            Column {
                x: 26; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 260
                spacing: 6
                T { text: "TYPING WITH"; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.2; color: M3.alpha(M3.inkPrimaryC, 0.75) }
                T { kind: "title"; width: parent.width; elide: Text.ElideRight; font.pixelSize: 26; font.weight: Font.Medium; color: M3.inkPrimaryC
                    text: page.st.active || (page.st.layouts.length ? page.nameOf(page.st.layouts[0]) : "…") }
                Row {
                    spacing: 8
                    visible: page.st.layouts.length > 1
                    Btn { text: "Next layout"; sym: "keyboard_tab"; icon: ""; primary: true; onClicked: page.run(["kbd-next"]) }
                }
            }
        }

        // ---------- your layouts ----------
        SectionTitle { text: "Your layouts"; sub: "Up to four. The first one is used when you log in." }
        Repeater {
            model: page.st.layouts
            delegate: SettingRow {
                label: page.nameOf(modelData)
                desc: index === 0 ? "Default" : "Code: " + modelData
                reserved: 200
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Rectangle {
                        width: 46; height: 30; radius: 15; color: M3.secondaryContainer
                        T { kind: "code"; anchors.centerIn: parent; text: modelData.toUpperCase(); font.pixelSize: 12; font.weight: Font.Medium; color: M3.inkSecondaryC }
                    }
                    Rectangle {
                        visible: index > 0
                        width: 34; height: 30; radius: 15; color: um.containsMouse ? M3.surfaceHighest : "transparent"
                        Icon { anchors.centerIn: parent; name: "vertical_align_top"; glyph: ""; size: 16; color: M3.inkDim }
                        MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.first(modelData) }
                    }
                    Rectangle {
                        visible: page.st.layouts.length > 1
                        width: 34; height: 30; radius: 15; color: xm.containsMouse ? M3.alpha(M3.error, 0.15) : "transparent"
                        Icon { anchors.centerIn: parent; name: "close"; glyph: ""; size: 16; color: xm.containsMouse ? M3.error : M3.inkDim }
                        MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.remove(modelData) }
                    }
                }
            }
        }
        SegRow {
            visible: page.st.layouts.length > 1
            label: "Switch with"
            desc: "Keys that change the layout"
            options: [{ label: "Alt + Shift", value: "grp:alt_shift_toggle" }, { label: "Super + Space", value: "grp:win_space_toggle" },
                      { label: "Caps Lock", value: "grp:caps_toggle" }]
            current: page.st.options
            onChosen: function(x) { const n = Object.assign({}, page.st); n.options = x; page.st = n; page.run(["kbd-options", x]) }
        }

        // ---------- add ----------
        SectionTitle { text: "Add a layout"; sub: (page.st.all || []).length + " layouts on this computer." }
        Field {
            width: parent.width
            placeholder: "Search: Polish, German, us ..."
            onTextChanged: page.q = text
        }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: page.found
                delegate: Rectangle {
                    readonly property bool have: page.st.layouts.indexOf(modelData.id) >= 0
                    width: lr.implicitWidth + 26; height: 38; radius: have ? 19 : 12
                    color: have ? M3.secondaryContainer : (lm.containsMouse ? M3.surfaceHigh : M3.surfaceC)
                    Behavior on radius { NumberAnimation { duration: M3.d(200) } }
                    Row {
                        id: lr; anchors.centerIn: parent; spacing: 8
                        Icon { name: parent.parent.have ? "check" : "add"; glyph: parent.parent.have ? "" : "+"; size: 15; color: parent.parent.have ? M3.inkSecondaryC : M3.primary; anchors.verticalCenter: parent.verticalCenter }
                        T { text: modelData.name; font.pixelSize: 13; color: parent.parent.have ? M3.inkSecondaryC : M3.ink; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (!parent.have) page.add(modelData.id) }
                }
            }
        }
    }
}
