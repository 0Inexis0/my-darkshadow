import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: vpn
    property bool watching: true
    property var state: ({ status: "disconnected", available: false })
    property var locations: [{ value: "auto", label: "Fastest US server" }]
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/rice-vpn"
    readonly property bool connected: state.status === "connected"
    readonly property bool busy: state.status === "connecting" || state.status === "disconnecting" || action.running
    readonly property bool available: state.available === true
    readonly property string error: state.status === "error" ? (state.message || "Could not connect to a US server. Please try again.") : ""
    readonly property string statusText: state.status === "connecting" ? "Connecting…"
        : state.status === "disconnecting" ? "Disconnecting…"
        : connected ? "Connected" : available ? "Not connected" : "Not configured"
    function refresh() { if (!status.running) status.running = true }
    function run(command, value) {
        if (action.running) return
        action.command = [bin, command].concat(value === undefined ? [] : [value])
        action.running = true
    }
    function toggle() {
        if (!available || state.status === "disconnecting") return
        run(connected || state.status === "connecting" ? "disconnect" : "connect")
    }
    function loadLocations() { if (available && !places.running) places.running = true }
    onWatchingChanged: if (watching) refresh()
    Process {
        id: status
        command: [vpn.bin, "state"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { vpn.state = JSON.parse(text) } catch (e) {} } }
    }
    Process {
        id: action
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    result.available = vpn.available
                    vpn.state = result
                } catch (e) {}
                followup.restart()
            }
        }
        onExited: followup.restart()
    }
    Process {
        id: places
        command: [vpn.bin, "locations"]
        stdout: StdioCollector { onStreamFinished: { try { const rows = JSON.parse(text); if (Array.isArray(rows)) vpn.locations = rows } catch (e) {} } }
    }
    Timer { interval: vpn.busy ? 650 : 2000; running: vpn.watching; repeat: true; onTriggered: vpn.refresh() }
    Timer { id: followup; interval: 200; onTriggered: vpn.refresh() }
}
