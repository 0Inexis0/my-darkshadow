import Quickshell
import Quickshell.Io
import QtQuick

// Settings > System > Screen: the size of everything (scale), the resolution and the refresh rate of each screen,
// on Hyprland and on niri (hypr-set monitors / monitor-apply). A change shows at once; it is kept only after you
// press Keep, otherwise it goes back by itself after 15 seconds (so a screen that goes black fixes itself).
Item {
    id: page
    property var ctl
    property var mons: []
    property string sel: ""                 // the screen being changed
    property int countdown: 0
    readonly property var m: {
        for (let i = 0; i < mons.length; i++) if (mons[i].name === sel) return mons[i]
        return mons.length ? mons[0] : null
    }
    readonly property string curRes: m ? m.width + "x" + m.height : ""
    readonly property string wm: Quickshell.env("NIRI_SOCKET") ? "niri" : "Hyprland"

    function ratesFor(res) {
        if (!m) return []
        for (let i = 0; i < m.modes.length; i++) if (m.modes[i].res === res) return m.modes[i].rates
        return []
    }
    function scaleText(s) { return Math.round(Number(s) * 100) + " %" }
    function apply(res, rate, scale) {
        if (!m) return
        ctl.hrun(["monitor-apply", m.name, res, String(rate), String(scale)], "Screen changed: keep it or it goes back")
        countdown = 15
        again.restart()
    }
    function keep() { ctl.hrun(["monitor-keep"], "Screen settings saved"); countdown = 0; again.restart() }
    function revert() { ctl.hrun(["monitor-revert"], "Screen settings went back"); countdown = 0; again.restart() }

    Process {
        id: monProc
        command: ["bash", "-c", "\"$HOME/.local/bin/hypr-set\" monitors"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.mons = JSON.parse(text) } catch (e) { return }
                if (page.sel === "" && page.mons.length) page.sel = page.mons[0].name
            }
        }
    }
    Timer { id: again; interval: 1200; onTriggered: monProc.running = true }
    Timer {
        interval: 1000; repeat: true; running: page.countdown > 0
        onTriggered: { page.countdown -= 1; if (page.countdown === 0) page.revert() }
    }

    PageScroll {
        anchors.fill: parent

        // ---------- the screen now ----------
        Rectangle {
            width: parent.width
            height: 150
            radius: M3.rXL
            color: M3.primaryContainer
            clip: true
            Blob { width: 220; height: 220; x: parent.width - 170; y: -40; kind: "puffy"; color: M3.alpha(M3.inkPrimaryC, 0.07)
                RotationAnimator on rotation { from: 0; to: 360; duration: 50000; loops: Animation.Infinite; running: page.visible } }
            Item {
                x: 24; anchors.verticalCenter: parent.verticalCenter
                width: 96; height: 96
                Blob { anchors.fill: parent; kind: Prefs.accentShape; color: M3.primary }
                Icon { anchors.centerIn: parent; name: "desktop_windows"; glyph: ""; size: 38; color: M3.inkPrimary }
            }
            Column {
                x: 140; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 140 - 24
                spacing: 3
                T { text: I18n.t("YOUR SCREEN"); font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.2; color: M3.alpha(M3.inkPrimaryC, 0.75) }
                T { kind: "title"; width: parent.width; elide: Text.ElideRight; font.pixelSize: 24; font.weight: Font.Medium; color: M3.inkPrimaryC
                    text: page.m ? page.curRes + "  ·  " + page.m.rate + " Hz" : "Looking for screens ..." }
                T { font.pixelSize: 12; color: M3.alpha(M3.inkPrimaryC, 0.85)
                    text: page.m ? page.m.name + "  ·  size " + page.scaleText(page.m.scale) + "  ·  " + page.wm : "" }
            }
        }

        // ---------- keep it? ----------
        Rectangle {
            visible: page.countdown > 0
            width: parent.width
            height: 64
            radius: M3.rL
            color: M3.tertiaryContainer !== undefined ? M3.tertiaryContainer : M3.secondaryContainer
            T { x: 18; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 290; wrapMode: Text.WordWrap
                text: "Keep this? It goes back in " + page.countdown + " s"; font.pixelSize: 14; font.weight: Font.Medium
                color: M3.inkTertiaryC !== undefined ? M3.inkTertiaryC : M3.inkSecondaryC }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Btn { text: "Keep"; sym: "check"; icon: ""; primary: true; onClicked: page.keep() }
                Btn { text: I18n.t("Go back"); sym: "undo"; icon: ""; variant: "outlined"; onClicked: page.revert() }
            }
        }

        // ---------- which screen ----------
        SectionTitle { visible: page.mons.length > 1; text: "Screens"; sub: I18n.t("Pick the screen to change.") }
        Flow {
            visible: page.mons.length > 1
            width: parent.width
            spacing: 8
            Repeater {
                model: page.mons
                delegate: Rectangle {
                    readonly property bool on: page.m && page.m.name === modelData.name
                    width: st.implicitWidth + 32; height: 40; radius: 20
                    color: on ? M3.primary : (sm.containsMouse ? M3.surfaceHighest : M3.surfaceHigh)
                    T { id: st; anchors.centerIn: parent; text: modelData.name + "  " + modelData.width + "x" + modelData.height
                        font.pixelSize: 13; color: parent.on ? M3.inkPrimary : M3.ink }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.sel = modelData.name }
                }
            }
        }

        // ---------- size ----------
        SectionTitle { text: "Size"; sub: I18n.t("How big everything looks: text, windows, the bar. 100 % shows the most; bigger is easier to read on small, sharp screens.") }
        SegRow {
            label: I18n.t("Size of everything")
            desc: page.m ? "Now " + page.scaleText(page.m.scale) : ""
            options: [{ label: "100 %", value: "1" }, { label: "125 %", value: "1.25" }, { label: "150 %", value: "1.5" }, { label: "200 %", value: "2" }]
            current: page.m ? String(Number(page.m.scale)) : ""
            onChosen: function(v) { if (page.m) page.apply(page.curRes, page.m.rate, v) }
        }

        // ---------- resolution ----------
        SectionTitle { text: "Resolution"; sub: I18n.t("The number of pixels. The first one is your screen's own (the sharpest).") }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: page.m ? page.m.modes : []
                delegate: Rectangle {
                    readonly property bool on: modelData.res === page.curRes
                    width: rt.implicitWidth + 32; height: 40; radius: on ? 12 * M3.shapeK : 20 * M3.shapeK
                    Behavior on radius { NumberAnimation { duration: 200 } }
                    color: on ? M3.primary : (rm.containsMouse ? M3.surfaceHighest : M3.surfaceHigh)
                    T { id: rt; anchors.centerIn: parent; text: modelData.res.replace("x", " × "); font.pixelSize: 13; color: parent.on ? M3.inkPrimary : M3.ink }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (!parent.on) { const r = page.ratesFor(modelData.res); page.apply(modelData.res, r.length ? r[0] : page.m.rate, page.m.scale) } }
                }
            }
        }

        // ---------- refresh rate ----------
        SectionTitle { text: I18n.t("Refresh rate"); sub: I18n.t("How many times a second the picture changes. Higher is smoother (and uses a little more power on a laptop).") }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: page.ratesFor(page.curRes)
                delegate: Rectangle {
                    readonly property bool on: page.m && Math.abs(Number(modelData) - Number(page.m.rate)) < 0.5
                    width: ft.implicitWidth + 32; height: 40; radius: on ? 12 * M3.shapeK : 20 * M3.shapeK
                    Behavior on radius { NumberAnimation { duration: 200 } }
                    color: on ? M3.primary : (fm.containsMouse ? M3.surfaceHighest : M3.surfaceHigh)
                    T { id: ft; anchors.centerIn: parent; text: Math.round(Number(modelData)) + " Hz"; font.pixelSize: 13; color: parent.on ? M3.inkPrimary : M3.ink }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (!parent.on) page.apply(page.curRes, modelData, page.m.scale) }
                }
            }
        }

        T {
            visible: page.mons.length === 0
            width: parent.width; wrapMode: Text.WordWrap; topPadding: 12
            text: "No screens found (" + page.wm + " did not answer)."
            color: M3.inkDim
        }
    }
}
