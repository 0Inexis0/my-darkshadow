pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// One append-only log reader shared by all bars/screens. No prompts leave the process.
Singleton {
    id: ai
    property var data: ({ providers: [], active: 0 })
    readonly property var providers: data.providers || []
    readonly property bool active: (data.active || 0) > 0
    readonly property var current: {
        for (let p of providers) if (p.state === "waiting") return p
        for (let p of providers) if (p.active > 0) return p
        return providers.reduce((latest, p) => (p.updated || 0) > (latest.updated || 0) ? p : latest, ({}))
    }
    readonly property string label: {
        const names = providers.filter(p => p.active > 0).map(p => p.provider === "codex" ? "Codex" : "Claude")
        return names.join(" + ")
    }
    function state(s) {
        if (s === "working") return Tr.t("Working")
        if (s === "waiting") return Tr.t("Needs approval")
        if (s === "idle") return Tr.t("Ready")
        if (s === "unknown") return Tr.t("No recent signal")
        return Tr.t("No local session")
    }
    function tokens(v) { return v >= 1000000 ? (v / 1000000).toFixed(1) + "M" : (v >= 1000 ? (v / 1000).toFixed(1) + "k" : String(v || 0)) }
    function activity(action) {
        if (action === "editing") return Tr.t("Editing files")
        if (action === "terminal") return Tr.t("Running commands")
        if (action === "searching") return Tr.t("Searching")
        if (action === "reviewing") return Tr.t("Reviewing")
        if (action === "responding") return Tr.t("Writing a response")
        if (action === "tools") return Tr.t("Using tools")
        return Tr.t("Thinking")
    }
    Process {
        id: reader
        command: [Quickshell.env("HOME") + "/.local/bin/rice-ai", "watch"]
        running: true
        stdout: SplitParser { onRead: function(line) { try { ai.data = JSON.parse(line) } catch (e) {} } }
        onExited: { ai.data = { providers: [], active: 0 }; retry.restart() }
    }
    Timer { id: retry; interval: 10000; onTriggered: reader.running = true }
}
