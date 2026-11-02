pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Settings window preferences kept in ~/.config/rice/settings-app.json (Home > Settings).
// Prefs.scroll: how fast the pages scroll with the wheel or the touchpad (1 = as before).
Singleton {
    id: prefs
    property real scroll: 1.0
    readonly property real wheel: 0.6 * scroll       // pixels per wheel unit on a page
    // size of the Settings window: 1 = the default size, 0.75 smaller, 1.5 bigger
    property real size: 1.0
    function setSize(v) {
        size = Math.max(0.75, Math.min(1.5, Math.round(v * 20) / 20))
        save("size", size)
    }

    function save(key, value) {
        Quickshell.execDetached(["python3", "-c",
            "import json,os,sys\np=os.path.expanduser('~/.config/rice/settings-app.json')\n" +
            "try: d=json.load(open(p))\nexcept Exception: d={}\nd[sys.argv[1]]=json.loads(sys.argv[2])\n" +
            "os.makedirs(os.path.dirname(p),exist_ok=True)\njson.dump(d,open(p,'w'))",
            key, JSON.stringify(value)])
    }
    function setScroll(v) {
        scroll = Math.max(0.3, Math.min(3, Math.round(v * 20) / 20))
        save("scroll", scroll)
    }
    Process {
        command: ["bash", "-c", "cat \"$HOME/.config/rice/settings-app.json\" 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j.scroll !== undefined) prefs.scroll = Math.max(0.3, Math.min(3, Number(j.scroll)))
                    if (j.size !== undefined) prefs.size = Math.max(0.75, Math.min(1.5, Number(j.size)))
                } catch (e) { }
            }
        }
    }
}
