import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Notifications shown by the shell itself (rice-cc engine shell): the server, the pop-ups and the list the
// control center shows. Their look follows Settings > Notifications (~/.config/rice/notify.json): theme,
// transparency, blur, place, width, how long they stay, corners and text size. With swaync all of this sleeps.
Scope {
    id: nf
    property bool shellMode: false
    property bool dnd: false
    readonly property var list: srvLoader.item ? srvLoader.item.trackedNotifications.values : []
    readonly property int count: list.length
    property var pops: []              // notifications on screen right now
    property var leaving: []           // pop-ups that are on their way out

    // ---------- Settings > Notifications ----------
    property var ns: ({})
    function v(k, d) { return ns[k] !== undefined ? ns[k] : d }
    readonly property string theme: v("colors", "shell")
    readonly property real popupAlpha: v("popup_opacity", 0.85)
    readonly property real ccAlpha: v("opacity", 0.8)
    readonly property string posX: v("pos_x", "right")
    readonly property string posY: v("pos_y", "top")
    readonly property int popW: v("popup_width", 380)
    readonly property int timeout: v("timeout", 6)
    readonly property bool sticky: v("critical_sticky", true)
    readonly property int radius: v("radius", 22) + 4
    readonly property int fontSize: v("font_size", 13)
    readonly property bool images: v("images", true)
    NPal { id: popPal; theme: nf.theme; alpha: nf.popupAlpha }
    readonly property var pal: popPal

    Trigger {
        path: Quickshell.env("HOME") + "/.config/rice/cc.json"
        every: 3000
        onContent: function(t) {
            let j = {}
            try { j = t.trim() !== "" ? JSON.parse(t) : {} } catch (e) { j = {} }
            nf.shellMode = j.engine === "shell"
            nf.dnd = j.dnd === true
        }
    }
    Trigger {
        path: Quickshell.env("HOME") + "/.config/rice/notify.json"
        every: 4000
        onContent: function(t) { try { nf.ns = t.trim() !== "" ? JSON.parse(t) : {} } catch (e) { } }
    }
    // the server starts a moment after the switch, so swaync has let go of the notification name
    property bool srvOn: false
    onShellModeChanged: { if (!shellMode) srvOn = false; else srvT.restart() }
    Timer { id: srvT; interval: 1500; onTriggered: nf.srvOn = nf.shellMode }
    Loader {
        id: srvLoader
        active: nf.srvOn
        source: "NotifServer.qml"
    }
    Connections {
        target: srvLoader.item
        ignoreUnknownSignals: true
        function onArrived(n) { nf.arrive(n) }
    }

    function urgent(n) { return n.urgency === 2 }
    function arrive(n) {
        if (nf.dnd && !urgent(n)) return
        const p = pops.slice(); p.unshift(n)
        if (p.length > 4) leave(p[p.length - 1])
        pops = p
        Quickshell.execDetached(["bash", "-c", "SWAYNC_APP_NAME=\"$1\" \"$HOME/.local/bin/rice-sound\" notify", "_", n.appName || ""])
    }
    // a pop-up first plays its way out, then leaves the list
    function leave(n) {
        if (leaving.indexOf(n) >= 0 || pops.indexOf(n) < 0) return
        leaving = leaving.concat([n])
        goneT.restart()
    }
    Timer {
        id: goneT; interval: 260
        onTriggered: { const l = nf.leaving; nf.pops = nf.pops.filter(function(x) { return l.indexOf(x) < 0 }); nf.leaving = [] }
    }
    function unpop(n) { leave(n) }
    function dismiss(n) { leave(n); try { n.dismiss() } catch (e) { } }
    function clearAll() { const l = list.slice(); pops.forEach(function(x) { nf.leave(x) }); l.forEach(function(n) { try { n.dismiss() } catch (e) { } }) }
    function setDnd(on) { dnd = on; Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-cc\" dnd " + (on ? "on" : "off")]) }

    // ---------- the pop-ups ----------
    PanelWindow {
        id: popWin
        visible: nf.shellMode && nf.pops.length > 0
        color: "transparent"
        anchors { top: nf.posY === "top"; bottom: nf.posY === "bottom"; right: nf.posX === "right"; left: nf.posX === "left" }
        margins { top: 50; bottom: 10; left: 4; right: 4 }
        implicitWidth: nf.popW + 40
        implicitHeight: Math.max(10, popCol.implicitHeight + 40)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "rice-notify-popup"
        Column {
            id: popCol
            x: 20; y: nf.posY === "top" ? 16 : parent.height - height - 16
            width: parent.width - 40
            spacing: 10
            // the others slide softly to make room
            move: Transition { NumberAnimation { properties: "y"; duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.emph } }
            Repeater {
                model: nf.pops
                delegate: NotifCard {
                    width: popCol.width
                    n: modelData
                    nf: nf
                    popup: true
                    out: nf.leaving.indexOf(modelData) >= 0
                    onClosed: nf.dismiss(modelData)
                    onTimedOut: nf.unpop(modelData)
                }
            }
        }
    }
}
