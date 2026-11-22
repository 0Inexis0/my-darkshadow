import Quickshell.Io
import QtQuick

// One run of rice-apps-helper: "P 0.42" lines go to `prog`, the line of JSON at the end to `done`.
Process {
    id: j
    property var done: null
    property var prog: null
    property bool answered: false
    stdout: SplitParser {
        splitMarker: "\n"
        onRead: function(l) {
            if (l.indexOf("P ") === 0) { if (j.prog) j.prog(parseFloat(l.substring(2))); return }
            if (j.answered || l.trim() === "") return
            let r = null
            try { r = JSON.parse(l) } catch (e) { return }
            j.answered = true
            if (j.done) j.done(r)
        }
    }
    onExited: function(code) {
        if (!j.answered) { j.answered = true; if (j.done) j.done(null) }
        j.destroy()
    }
}
