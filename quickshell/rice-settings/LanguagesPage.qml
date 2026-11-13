import Quickshell
import Quickshell.Io
import QtQuick

// Settings > System > Languages: the language of this app. The choice is kept (settings-app.json) and applies at once.
// The words are in I18nData.qml; a text without a translation stays in English.
Item {
    id: page
    property var ctl
    readonly property var all: I18n.langs
    // Japanese, Korean and Chinese need their letters: rice-fonts cjk downloads Noto Sans for that language
    // (about 13 MB, no password), then Settings and the shell start again so they see the new font
    property string fontMsg: ""
    function pick(code) {
        Prefs.setLang(code)
        if (/^(ja|ko|zh)/.test(code) && !fonts.running) {
            fontMsg = I18n.t("Getting the font for this language…")
            fonts.code = code
            fonts.running = true
        } else fontMsg = ""
    }
    Process {
        id: fonts
        property string code: ""
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-fonts\" cjk \"$1\"", "_", code]
        onExited: function(c) {
            if (c === 0) {
                page.fontMsg = I18n.t("Font installed. Settings opens again in a moment")
                // the shell and Settings only see a new font when they start
                Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-desktop\" restart >/dev/null 2>&1; sleep 0.8; " +
                    "mkdir -p \"$HOME/.cache/rice\"; echo 31 > \"$HOME/.cache/rice/settings-page\"; rm -f \"$HOME/.cache/rice/settings-parked\"; " +
                    "exec qs -n -p \"$HOME/.config/quickshell/rice-settings\""])
                restartT.start()
            } else if (c === 2) page.fontMsg = ""
            else page.fontMsg = I18n.t("Could not download the font. Install Noto Sans CJK with your package manager (Arch: noto-fonts-cjk)")
        }
    }
    Timer { id: restartT; interval: 500; onTriggered: Qt.quit() }

    PageScroll {
        anchors.fill: parent

        // ---------- the language now ----------
        Rectangle {
            width: parent.width
            height: 132
            radius: M3.rXL
            color: M3.primaryContainer
            clip: true
            Blob { width: 220; height: 220; x: parent.width - 150; y: -50; kind: "flower"; color: M3.alpha(M3.inkPrimaryC, 0.06) }
            Icon { x: 24; y: 22; name: "translate"; glyph: ""; size: 20; color: M3.alpha(M3.inkPrimaryC, 0.75) }
            T { x: 54; y: 22; text: I18n.t("YOUR LANGUAGE"); font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.2
                color: M3.alpha(M3.inkPrimaryC, 0.75) }
            T { x: 24; y: 48; kind: "title"; text: I18n.nameOf(I18n.lang); font.pixelSize: 30; font.weight: Font.Medium
                color: M3.inkPrimaryC; width: parent.width - 48; elide: Text.ElideRight }
            T { x: 24; y: 94; kind: "reading"; text: I18n.t("The language of the whole shell. It changes right away."); font.pixelSize: 13
                color: M3.alpha(M3.inkPrimaryC, 0.85); width: parent.width - 48; elide: Text.ElideRight }
        }

        // the font for Japanese, Korean or Chinese is on its way (or could not be had)
        Rectangle {
            visible: page.fontMsg !== ""
            width: parent.width; height: fm.implicitHeight + 26; radius: M3.rM
            color: M3.alpha(M3.tertiary, 0.14)
            Icon { id: fIc; x: 16; anchors.verticalCenter: parent.verticalCenter; name: fonts.running ? "downloading" : "text_fields"; glyph: ""; size: 20; color: M3.tertiary }
            T { id: fm; x: 48; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 64; wrapMode: Text.WordWrap; font.pixelSize: 13
                text: page.fontMsg }
        }

        SectionTitle { text: I18n.t("All languages"); sub: I18n.t("Settings, the bar, the panels, the menus and the lock screen follow it. A few pages are still partly in English.") }

        // ---------- the languages ----------
        Flow {
            id: flow
            width: parent.width
            spacing: 10
            readonly property int cols: width >= 700 ? 3 : 2
            readonly property real cw: (width - (cols - 1) * spacing) / cols
            Repeater {
                model: page.all
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool on: I18n.lang === modelData[0]
                    width: flow.cw
                    height: 64
                    radius: M3.rL
                    color: on ? M3.secondaryContainer : (hov.hovered ? M3.surfaceHigh : M3.surfaceC)
                    border.width: on ? 2 : 0
                    border.color: M3.primary
                    Behavior on color { ColorAnimation { duration: 160 } }
                    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
                    Column {
                        x: 18; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 36 - 26
                        spacing: 2
                        T { text: card.modelData[1]; font.pixelSize: 15; font.weight: Font.Medium; width: parent.width; elide: Text.ElideRight
                            color: card.on ? M3.inkSecondaryC : M3.ink }
                        T { text: card.modelData[2]; font.pixelSize: 11; color: M3.inkDim; width: parent.width; elide: Text.ElideRight }
                    }
                    Icon { visible: card.on; name: "check_circle"; glyph: ""; size: 20; color: M3.primary
                        anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.pick(card.modelData[0]) }
                }
            }
        }
    }
}
