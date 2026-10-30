import QtQuick

Item {
    id: page
    property var ctl

    function dv(k, d) {
        const c = page.ctl.dst.dock
        return c && c[k] !== undefined ? c[k] : d
    }
    function lv(k) {
        const c = page.ctl.dst.lock
        return !!(c && c[k] === true)
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 6
        contentWidth: width
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Behavior on contentY {
            enabled: !flick.dragging && !flick.flicking
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(e) {
                const max = Math.max(0, flick.contentHeight - flick.height)
                flick.contentY = Math.max(0, Math.min(max, flick.contentY - e.angleDelta.y * 0.6))
            }
        }

        Column {
            id: col
            width: flick.width
            spacing: 10

            T { kind: "title"; text: "Dock"; font.pixelSize: 16; font.bold: true }

            ToggleRow {
                label: "Enable"
                desc: "A minimal dock with your apps at the bottom of the screen"
                checked: page.dv("enabled", false) === true
                onToggled: function(v) { page.ctl.dset("dock", "enabled", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Background"
                desc: "Draw a panel behind the icons"
                checked: page.dv("background", true) === true
                onToggled: function(v) { page.ctl.dset("dock", "background", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Hover to reveal"
                desc: "Hide the dock and slide it in when the pointer touches the bottom edge"
                checked: page.dv("hover", true) === true
                onToggled: function(v) { page.ctl.dset("dock", "hover", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Pinned on startup"
                desc: "Start with the dock held open"
                checked: page.dv("pinnedStartup", false) === true
                onToggled: function(v) { page.ctl.dset("dock", "pinnedStartup", v ? "on" : "off") }
            }

            T { kind: "title"; text: "Buttons"; font.pixelSize: 16; font.bold: true; topPadding: 8 }

            ToggleRow {
                label: "Media player"
                desc: "Show the current track in the dock"
                checked: page.dv("media", true) === true
                onToggled: function(v) { page.ctl.dset("dock", "media", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Show pin button"
                desc: "Button that holds the dock open"
                checked: page.dv("pinButton", true) === true
                onToggled: function(v) { page.ctl.dset("dock", "pinButton", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Show apps button"
                desc: "Button that opens the app launcher"
                checked: page.dv("appsButton", true) === true
                onToggled: function(v) { page.ctl.dset("dock", "appsButton", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Tint app icons"
                desc: "Paint icons in a single neutral tone"
                checked: page.dv("tint", false) === true
                onToggled: function(v) { page.ctl.dset("dock", "tint", v ? "on" : "off") }
            }

            T {
                width: parent.width
                topPadding: 14
                text: "Lock screen options moved to Idle & Lockscreen."
                color: "#8a8a8a"
                font.pixelSize: 12
            }
        }
    }
}
