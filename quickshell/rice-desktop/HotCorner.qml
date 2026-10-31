import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Hot corner: touch the chosen screen corner and the panel slides out (Settings > Hot corners).
PanelWindow {
    id: hc
    property var cfg: ({ enabled: false })
    property var st: ({})
    property bool open: false
    property string cfgText: ""
    property string lastOpenCmd: ""
    property bool cmdSeen: false
    property real t: 0

    readonly property real spd: cfg.speed ? cfg.speed : 1
    readonly property string corner: cfg.corner ? cfg.corner : "bottom-right"
    readonly property bool atBottom: corner.indexOf("bottom") === 0
    readonly property bool atRight: corner.indexOf("right") > 0
    readonly property string anim: cfg.animation ? cfg.animation : "grow"
    readonly property int gap: 10
    readonly property int trig: cfg.trigger ? cfg.trigger : 4

    // emphasized decelerate in, emphasized accelerate out (Material 3 motion)
    NumberAnimation {
        id: tAnim
        target: hc
        property: "t"
    }
    function animateTo(v) {
        tAnim.stop()
        tAnim.to = v
        tAnim.duration = (v > 0.5 ? 520 : 300) / hc.spd
        tAnim.easing.type = Easing.BezierSpline
        tAnim.easing.bezierCurve = v > 0.5 ? [0.05, 0.7, 0.1, 1.0, 1, 1] : [0.3, 0.0, 0.8, 0.15, 1, 1]
        tAnim.start()
    }

    // panel surface: optional theme tint, transparency can be switched off
    function bgColor() {
        const a = hc.cfg.transparency === false ? 1 : (hc.cfg.opacity !== undefined ? hc.cfg.opacity : 0.9)
        let r = 18, g = 18, b = 20
        if (hc.cfg.tint === true && hc.st.accent) {
            const x = String(hc.st.accent).replace("#", "")
            r = 18 + (parseInt(x.substr(0, 2), 16) - 18) * 0.16
            g = 18 + (parseInt(x.substr(2, 2), 16) - 18) * 0.16
            b = 20 + (parseInt(x.substr(4, 2), 16) - 20) * 0.16
        }
        return Qt.rgba(r / 255, g / 255, b / 255, a)
    }
    function refresh() { if (!stateProc.running) stateProc.running = true }
    function run(cmd, arg, closeFirst) {
        if (closeFirst) hc.open = false
        const s = Object.assign({}, hc.st)
        if (cmd === "close") {
            return
        } else if (cmd === "allapps") {
            Quickshell.execDetached(["bash", "-c", "sleep 0.25; rofi -show drun"])
        } else if (cmd === "settings") {
            Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-settings\""])
        } else if (cmd === "wallpaper") {
            Quickshell.execDetached(["bash", "-c", "sleep 0.25; \"$HOME/.local/bin/rice-wallpaper\""])
        } else if (cmd === "lock") {
            Quickshell.execDetached(["bash", "-c", "sleep 0.3; loginctl lock-session || hyprlock"])
        } else {
            // instant feedback, the real state follows a moment later
            if (cmd === "awake" || cmd === "wifi" || cmd === "bluetooth" || cmd === "dnd" || cmd === "gaming") s[cmd] = !s[cmd]
            if (cmd === "mic") s.mic_muted = !s.mic_muted
            if (cmd === "record" && arg === "stop") s.recording = false
            if (cmd === "wall") s.wall = arg
            hc.st = s
            Quickshell.execDetached(["bash", "-c", "sleep \"$3\"; \"$HOME/.local/bin/rice-hotcorner\" \"$1\" \"$2\"", "_", cmd, arg, closeFirst ? "0.35" : "0"])
        }
        soon.restart()
        later.restart()
    }

    visible: cfg.enabled === true
    color: "transparent"
    anchors { bottom: hc.atBottom; top: !hc.atBottom; right: hc.atRight; left: !hc.atRight }
    implicitWidth: panel.width + 2 * gap + 16
    implicitHeight: panel.height + 2 * gap + 16
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-hotcorner"
    WlrLayershell.keyboardFocus: hc.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: (hc.open || hc.t > 0.02) ? holder : trigger }

    // ---- settings + "open now" requests
    Process {
        id: cfgProc
        command: ["bash", "-c", "cat \"$HOME/.config/rice/hotcorner.json\" 2>/dev/null || \"$HOME/.local/bin/rice-hotcorner\" config; echo; echo '@@'; cat \"$HOME/.cache/rice/hotcorner-open\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("@@")
                const c = p[0].trim()
                if (c.length > 0 && c !== hc.cfgText) {
                    try { hc.cfg = JSON.parse(c); hc.cfgText = c } catch (e) { }
                }
                const o = p.length > 1 ? p[1].trim() : ""
                if (hc.cmdSeen && o.length > 0 && o !== hc.lastOpenCmd) hc.open = true
                hc.lastOpenCmd = o
                hc.cmdSeen = true
            }
        }
    }
    Timer { interval: 400; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!cfgProc.running) cfgProc.running = true }

    // ---- live status while open
    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-hotcorner\" state"]
        stdout: StdioCollector { onStreamFinished: { try { hc.st = JSON.parse(text) } catch (e) { } } }
    }
    Timer { interval: 1500; running: hc.open; repeat: true; triggeredOnStart: true; onTriggered: hc.refresh() }
    Timer { id: soon; interval: 450; onTriggered: hc.refresh() }
    Timer { id: later; interval: 1600; onTriggered: hc.refresh() }

    // ---- corner trigger
    Item {
        id: trigger
        width: hc.trig
        height: hc.trig
        x: hc.atRight ? parent.width - width : 0
        y: hc.atBottom ? parent.height - height : 0
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: openTimer.restart()
            onExited: openTimer.stop()
            onClicked: hc.open = !hc.open
        }
    }
    Timer { id: openTimer; interval: Math.max(1, hc.cfg.delay !== undefined ? hc.cfg.delay : 150); onTriggered: hc.open = true }

    // ---- close when the pointer leaves
    Timer {
        id: leaveTimer
        interval: 380
        onTriggered: if (hc.cfg.close_on_leave !== false && !hover.hovered) hc.open = false
    }
    Timer {
        // opened but the pointer never came into the panel
        id: graceTimer
        interval: 1400
        onTriggered: if (hc.cfg.close_on_leave !== false && !hover.hovered) hc.open = false
    }
    onOpenChanged: {
        animateTo(open ? 1 : 0)
        if (open) { refresh(); graceTimer.restart() }
        else { graceTimer.stop(); leaveTimer.stop() }
    }

    Item {
        id: holder
        readonly property bool grow: hc.anim === "grow"
        width: grow ? panel.width * (0.62 + 0.38 * hc.t) : panel.width
        height: grow ? Math.max(1, panel.height * hc.t) : panel.height
        x: (hc.atRight ? parent.width - width - hc.gap : hc.gap)
           + (hc.anim === "slide" ? (1 - hc.t) * (hc.atRight ? panel.width + hc.gap + 4 : -(panel.width + hc.gap + 4)) : 0)
        y: hc.atBottom ? parent.height - height - hc.gap : hc.gap
        visible: hc.t > 0.005
        clip: grow
        opacity: hc.anim === "fade" ? hc.t : (hc.anim === "scale" ? Math.min(1, hc.t * 3) : 1)
        transform: Scale {
            origin.x: hc.atRight ? holder.width : 0
            origin.y: hc.atBottom ? holder.height : 0
            xScale: hc.anim === "scale" ? 0.82 + 0.18 * hc.t : 1
            yScale: hc.anim === "scale" ? 0.82 + 0.18 * hc.t : 1
        }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) { leaveTimer.stop(); graceTimer.stop() }
                else if (hc.open) leaveTimer.restart()
            }
        }

        // the shape that grows (rounded even while it is small)
        Rectangle {
            anchors.fill: parent
            radius: Math.min(panel.rad, Math.min(width, height) / 2)
            color: hc.bgColor()
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }

        HotCornerPanel {
            id: panel
            showBg: false
            cfg: hc.cfg
            st: hc.st
            open: hc.open
            // content stays pinned to the corner while the shape reveals it
            x: hc.atRight ? holder.width - width : 0
            y: hc.atBottom ? holder.height - height : 0
            onAct: function(cmd, arg, closeFirst) { hc.run(cmd, arg, closeFirst) }
            onLaunch: function(entry) { hc.open = false; entry.execute() }
        }
    }
}
