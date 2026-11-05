import QtQuick

// Scrolling a page with the mouse wheel or the touchpad. Put it inside the Flickable:
//   WheelScroll { id: wsc; flick: flick }                 (sideways: horizontal: true)
// and keep the page's own Behavior on contentY for jumps (search) with  enabled: ... && !wsc.active
// The mouse wheel glides to where the notches point; the touchpad moves the page with your fingers, as they go.
// (Before, each wheel step started from where the last glide had got to so far: quick touchpad events added up to
// less than they should, and the page jumped back a little.)
WheelHandler {
    id: ws
    property Flickable flick: null
    property bool horizontal: false
    property real k: Prefs.wheel
    property real goal: 0
    property bool active: false                   // scrolled a moment ago (the page's Behavior stays out of the way)
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    readonly property string prop: horizontal ? "contentX" : "contentY"
    function limit(v) {
        const max = horizontal ? Math.max(0, flick.contentWidth - flick.width) : Math.max(0, flick.contentHeight - flick.height)
        return Math.max(0, Math.min(max, v))
    }
    property NumberAnimation glide: NumberAnimation { target: ws.flick; property: ws.prop; duration: 140; easing.type: Easing.OutCubic }
    property Timer rest: Timer { interval: 220; onTriggered: ws.active = false }
    onWheel: function(e) {
        if (!flick) return
        active = true
        rest.restart()
        const cur = flick[prop]
        if (e.pixelDelta.x !== 0 || e.pixelDelta.y !== 0) {
            // a touchpad: follow the fingers
            glide.stop()
            const d = horizontal ? (e.pixelDelta.x !== 0 ? e.pixelDelta.x : e.pixelDelta.y) : e.pixelDelta.y
            goal = limit(cur - d * Math.max(0.6, Prefs.scroll))
            flick[prop] = goal
            return
        }
        const a = horizontal ? (e.angleDelta.x !== 0 ? e.angleDelta.x : e.angleDelta.y) * 1.15 : e.angleDelta.y
        goal = limit((glide.running ? goal : cur) - a * k)
        glide.stop(); glide.from = cur; glide.to = goal; glide.start()
    }
}
