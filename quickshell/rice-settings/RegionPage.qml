import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Sound & language > Language & region: the clock (24 or 12 hours), °C or °F, the first day of the
// week, and the language you prefer (rice-region).
Item {
    id: page
    property var ctl
    property var rg: ({ clock: "24", units: "c", week: "mon", lang: "en" })
    Process {
        id: st
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-region\" state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.rg = JSON.parse(text) } catch (e) { } } }
    }
    function set(k, v) {
        const n = Object.assign({}, rg); n[k] = v; rg = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-region\" set \"$1\" \"$2\"", "_", k, v])
        page.ctl.status = I18n.t("Saved")
    }
    property var now: new Date()
    Timer { interval: 1000; running: page.visible; repeat: true; onTriggered: page.now = new Date() }
    // Online lookups (V4.48): what the shell asks other websites; nothing goes out for one that is off
    property var on: ({ weather: { place: "" }, lyrics: { enabled: false }, updates: { watch: true } })
    Process {
        id: onSt
        command: ["bash", "-c", "b=\"$HOME/.local/bin\"; printf '{\"weather\":%s,\"lyrics\":%s,\"updates\":%s}' \"$(\"$b/rice-weather\" state 2>/dev/null || echo '{}')\" \"$(\"$b/rice-lyrics\" state 2>/dev/null || echo '{}')\" \"$(\"$b/rice-update\" watch state 2>/dev/null || echo '{}')\""]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.on = JSON.parse(text); placeField.text = page.on.weather.place || "" } catch (e) { } } }
    }
    function runBin(args, msg) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/$1\" \"${@:2}\"", "_"].concat(args))
        page.ctl.status = msg
        onAgain.restart()
    }
    Timer { id: onAgain; interval: 700; onTriggered: onSt.running = true }
    function two(n) { return n < 10 ? "0" + n : "" + n }
    readonly property string clockText: rg.clock === "12"
        ? ((now.getHours() + 11) % 12 + 1) + ":" + two(now.getMinutes()) + (now.getHours() < 12 ? " AM" : " PM")
        : two(now.getHours()) + ":" + two(now.getMinutes())

    readonly property var langs: [
        { k: "en", n: "English" }, { k: "pl", n: "Polski" }, { k: "de", n: "Deutsch" }, { k: "fr", n: "Français" },
        { k: "es", n: "Español" }, { k: "pt", n: "Português" }, { k: "it", n: "Italiano" }, { k: "nl", n: "Nederlands" },
        { k: "cs", n: "Čeština" }, { k: "uk", n: "Українська" }, { k: "ru", n: "Русский" }, { k: "tr", n: "Türkçe" },
        { k: "ja", n: "日本語" }, { k: "ko", n: "한국어" }, { k: "zh", n: "中文" }
    ]

    PageScroll {
        anchors.fill: parent

        // ---------- the clock as you will see it ----------
        Rectangle {
            width: parent.width; height: 150; radius: M3.rXL; color: M3.primaryContainer
            clip: true
            Item {
                x: 24; anchors.verticalCenter: parent.verticalCenter
                width: 110; height: 110
                Blob { anchors.fill: parent; kind: Prefs.accentShape; color: M3.alpha(M3.primary, 0.3)
                    RotationAnimator on rotation { from: 0; to: 360; duration: 30000; loops: Animation.Infinite; running: page.visible } }
                Icon { anchors.centerIn: parent; name: "language"; glyph: ""; size: 40; color: M3.inkPrimaryC }
            }
            Column {
                x: 160; anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                T { text: I18n.t("LANGUAGE & REGION"); font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.2; color: M3.alpha(M3.inkPrimaryC, 0.75) }
                T { kind: "number"; text: page.clockText; font.pixelSize: 34; font.weight: Font.Medium; color: M3.inkPrimaryC }
                T { text: page.now.toLocaleDateString(I18n.loc, "dddd, d MMMM") + "  ·  " + (page.rg.units === "f" ? "41°F" : "5°C") + I18n.t(" outside (example)")
                    font.pixelSize: 12; color: M3.alpha(M3.inkPrimaryC, 0.85) }
            }
        }

        SectionTitle { text: I18n.t("Region"); sub: I18n.t("How times, temperatures and calendars look in the shell.") }
        SegRow {
            label: I18n.t("Clock format"); desc: I18n.t("The bar, the game bar and the desktop")
            options: [{ label: "24 h", value: "24" }, { label: "12 h", value: "12" }]
            current: page.rg.clock
            onChosen: function(x) { page.set("clock", x) }
        }
        SegRow {
            label: I18n.t("Temperature"); desc: I18n.t("Weather widgets and the lock screen")
            options: [{ label: I18n.t("Celsius °C"), value: "c" }, { label: I18n.t("Fahrenheit °F"), value: "f" }]
            current: page.rg.units
            onChosen: function(x) { page.set("units", x) }
        }
        SegRow {
            label: I18n.t("First day of the week"); desc: I18n.t("Calendars")
            options: [{ label: I18n.t("Monday"), value: "mon" }, { label: I18n.t("Sunday"), value: "sun" }]
            current: page.rg.week
            onChosen: function(x) { page.set("week", x) }
        }

        SectionTitle { text: I18n.t("Online lookups"); sub: I18n.t("What the shell asks other websites. Nothing goes out for one that is off.") }
        SettingRow {
            label: I18n.t("Weather place"); desc: page.on.weather && page.on.weather.place
                ? I18n.t("The weather widgets ask wttr.in about this place")
                : I18n.t("Off. Type a city to turn it on (without one, wttr.in would locate your IP)")
            reserved: 330
            Row {
                anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Field { id: placeField; width: 170; placeholder: I18n.t("e.g. Warsaw")
                    onAccepted: if (text.trim() !== "") page.runBin(["rice-weather", "place", text.trim()], I18n.t("Weather place saved")) }
                Btn { text: I18n.t("Save"); variant: "tonal"; anchors.verticalCenter: parent.verticalCenter
                    onClicked: if (placeField.text.trim() !== "") page.runBin(["rice-weather", "place", placeField.text.trim()], I18n.t("Weather place saved")) }
                Btn { visible: !!(page.on.weather && page.on.weather.place); text: I18n.t("Off"); variant: "text"; anchors.verticalCenter: parent.verticalCenter
                    onClicked: { placeField.text = ""; page.runBin(["rice-weather", "off"], I18n.t("Weather lookups off")) } }
            }
        }
        ToggleRow {
            label: I18n.t("Song lyrics"); desc: I18n.t("Asks lrclib.net for the lyrics of what you play (it learns the artist and the title). Lyrics already found keep working")
            checked: !!(page.on.lyrics && page.on.lyrics.enabled)
            onToggled: function(v) { page.runBin(["rice-lyrics", v ? "on" : "off"], v ? I18n.t("Lyrics lookups on") : I18n.t("Lyrics lookups off")) }
        }
        ToggleRow {
            label: I18n.t("Check for updates"); desc: I18n.t("Asks GitHub once a day whether a new version is out, and tells you")
            checked: !(page.on.updates && page.on.updates.watch === false)
            onToggled: function(v) { page.runBin(["rice-update", "watch", v ? "on" : "off"], v ? I18n.t("Update checks on") : I18n.t("Update checks off")) }
        }

        SectionTitle { text: I18n.t("Language"); sub: I18n.t("The shell speaks English for now. Your choice is kept, so the shell can switch when a translation arrives.") }
        Rectangle {
            width: parent.width; height: lflow.implicitHeight + 28; radius: M3.rL; color: M3.surfaceC
            Grid {
                id: lflow
                x: 14; y: 14; width: parent.width - 28
                columns: Math.max(3, Math.floor(width / 150))
                spacing: 6
                Repeater {
                    model: page.langs
                    delegate: Rectangle {
                        readonly property bool on: page.rg.lang === modelData.k
                        width: (lflow.width - (lflow.columns - 1) * 6) / lflow.columns; height: 40
                        radius: on ? 20 : M3.rS
                        color: on ? M3.primary : (lm.containsMouse ? M3.surfaceHighest : M3.surfaceHigh)
                        Behavior on radius { NumberAnimation { duration: M3.d(220); easing.type: M3.springy; easing.overshoot: 1.6 * Prefs.bounce } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Icon { visible: parent.parent.on; name: "check"; glyph: ""; size: 15; color: M3.inkPrimary; anchors.verticalCenter: parent.verticalCenter }
                            T { text: modelData.n; font.pixelSize: 13; color: parent.parent.on ? M3.inkPrimary : M3.ink; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.set("lang", modelData.k) }
                    }
                }
            }
        }
    }
}
