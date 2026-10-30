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

    function family(kind) {
        switch (kind) {
        case "title": return title
        case "number": return numbers
        case "mono": return mono
        case "icon": return icons
        case "reading": return reading
        default: return main
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
