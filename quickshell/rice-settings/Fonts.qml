pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: f
    property string main: "JetBrainsMono Nerd Font"
    property string numbers: "JetBrainsMono Nerd Font"
    property string title: "JetBrainsMono Nerd Font"
    property string mono: "JetBrainsMono Nerd Font"
    property string icons: "JetBrainsMono Nerd Font"
    property string reading: "JetBrainsMono Nerd Font"

    // the old default (JetBrains everywhere) counts as "not chosen": the window then uses Rubik / Inter
    readonly property var fams: Qt.fontFamilies()
    readonly property string ui: fams.indexOf("Rubik") >= 0 ? "Rubik" : (fams.indexOf("Inter") >= 0 ? "Inter" : "JetBrainsMono Nerd Font")
    function pick(v) { return v === "JetBrainsMono Nerd Font" ? ui : v }

    function family(kind) {
        switch (kind) {
        case "title": return pick(title)
        case "number": return pick(numbers)
        case "mono": return mono
        case "icon": return icons
        case "reading": return pick(reading)
        default: return pick(main)
        }
    }

    Process {
        id: proc
        command: ["bash", "-c", "cat \"$HOME/.config/rice/fonts.json\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j.main) f.main = j.main
                    if (j.numbers) f.numbers = j.numbers
                    if (j.title) f.title = j.title
                    if (j.mono) f.mono = j.mono
                    if (j.icons) f.icons = j.icons
                    if (j.reading) f.reading = j.reading
                } catch (e) { }
            }
        }
    }
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: { if (!proc.running) proc.running = true }
    }
}
