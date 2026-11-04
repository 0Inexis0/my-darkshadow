import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

// The lock screen of DarkShadow's Shell (Settings > Idle & Lockscreen), started by `rice-lock now`.
// It locks the session with the Wayland session-lock protocol (so nothing can be seen or clicked behind it) and
// checks your password with PAM (the same rules hyprlock uses). rice-lock watches it: if it does not lock within a
// few seconds, or quits without unlocking, hyprlock takes over, so you can never be locked out.
// RICE_LOCK_PREVIEW=1 shows it in a normal full-screen window (Settings > Preview): Esc closes it.
// The shared parts (Look, Fonts, Blob, WavyLine ...) are copied here from rice-desktop by rice-lock.
ShellRoot {
    id: root
    readonly property bool preview: Quickshell.env("RICE_LOCK_PREVIEW") === "1"
    readonly property string home: Quickshell.env("HOME")

    // ---------- settings (rice-lock state) ----------
    property var cfg: ({})
    property bool ready: false
    function v(k, d) { return cfg[k] !== undefined ? cfg[k] : d }
    Process {
        running: true
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-lock\" state 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: {
            try { root.cfg = JSON.parse(text) } catch (e) { root.cfg = {} }
            if (/^#[0-9a-fA-F]{6}$/.test(root.cfg.accent || "")) Look.accent = root.cfg.accent
            root.ready = true
        } }
    }
    // your shape and wavy progress (Settings > Appearance)
    Process {
        running: true
        command: ["bash", "-c", "cat \"$HOME/.config/rice/settings-app.json\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: {
            let j = {}
            try { j = text.trim() !== "" ? JSON.parse(text) : {} } catch (e) { j = {} }
            Look.wavy = j.wavy !== false
            if (typeof j.accentShape === "string" && j.accentShape !== "") Look.shape = j.accentShape
            Look.waveThick = j.progressThick !== undefined ? Math.max(2, Math.min(8, Number(j.progressThick))) : 4
        } }
    }

    // ---------- the password (shared by every screen) ----------
    property string pass: ""
    property string pending: ""
    property string phase: "idle"            // idle | checking | wrong | done
    property string msg: ""
    property int tries: 0
    function submit() {
        if (phase === "checking" || phase === "done" || pass === "") return
        pending = pass
        phase = "checking"; msg = ""
        if (pam.active && pam.responseRequired) { pam.respond(pending); pending = ""; return }
        if (pam.active) return                 // it asks for the password in a moment (onResponseRequiredChanged)
        console.log("[lock] checking the password with PAM:", pam.config)
        if (!pam.start()) {
            console.warn("[lock] PAM did not start (" + pam.config + ")")
            fail("Could not check the password (PAM did not start)")
        }
    }
    function fail(text) {
        tries++
        phase = "wrong"
        msg = text
        pass = ""; pending = ""
        wrongT.restart()
    }
    PamContext {
        id: pam
        // hyprlock's PAM file when it is there (it is set up for exactly this), else the login rules
        config: root.cfg.pam || "login"
        onResponseRequiredChanged: if (responseRequired && root.pending !== "") { respond(root.pending); root.pending = "" }
        onPamMessage: {
            console.log("[lock] PAM says:", message, messageIsError ? "(error)" : "")
            if (messageIsError) root.msg = message
        }
        onError: function(e) { console.warn("[lock] PAM error", e); root.msg = "Could not check the password" }
        onCompleted: function(result) {
            console.log("[lock] PAM finished:", result === PamResult.Success ? "right password" : "result " + result)
            if (result === PamResult.Success) { root.phase = "done"; root.pending = ""; root.unlock(); return }
            root.fail(root.msg !== "" ? root.msg : (result === PamResult.MaxTries ? "Too many tries, wait a moment" : "That is not the password"))
        }
    }
    Timer { id: wrongT; interval: 2600; onTriggered: if (root.phase === "wrong") { root.phase = "idle"; root.msg = "" } }

    // ---------- locking and unlocking ----------
    property real out: 0                     // 0 shown .. 1 gone (the way out after the right password)
    NumberAnimation { id: outA; target: root; property: "out"; to: 1; duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.accel
        onFinished: { lock.locked = false; quitT.restart() } }
    Timer { id: quitT; interval: 150; onTriggered: { Quickshell.execDetached(["rm", "-f", root.home + "/.cache/rice/lock-active"]); Qt.quit() } }
    function unlock() { outA.restart() }
    // tells rice-lock that the screen is really locked (the compositor confirmed it)
    function tellLocked() { Quickshell.execDetached(["bash", "-c", "mkdir -p \"$HOME/.cache/rice\"; echo $PPID > \"$HOME/.cache/rice/lock-active\""]) }

    WlSessionLock {
        id: lock
        locked: !root.preview
        onSecureChanged: { console.log("[lock] the compositor locked the session:", secure); if (secure) root.tellLocked() }
        WlSessionLockSurface {
            color: "black"
            LockView { anchors.fill: parent; focus: true; root: root; scr: screen }
        }
    }

    // ---------- preview: the same thing in a window you can close ----------
    Variants {
        model: root.preview ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "rice-lock-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "black"
            LockView { anchors.fill: parent; focus: true; root: root; scr: modelData; isPreview: true }
        }
    }
}
