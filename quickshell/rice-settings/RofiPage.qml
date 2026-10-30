import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl
    property var rs: ({ themes: {} })

    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/rice-rofi"

    function v(k, d) { return rs[k] !== undefined ? rs[k] : d }

    function norm(value) { return value === "on" ? true : value === "off" ? false : value }
    function setv(key, value) {
        const n = Object.assign({}, rs)
        n[key] = page.norm(value)
        rs = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-rofi\" set \"$1\" \"$2\"", "_", key, String(value)])
        page.ctl.status = "Applied"
        refresh.restart()
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-rofi\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { page.rs = JSON.parse(text) } catch (e) { } }
        }
    }
    Timer { id: refresh; interval: 700; onTriggered: stateProc.running = true }

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

            T { kind: "title"; text: "Theme"; font.pixelSize: 16; font.bold: true }

            Flow {
                width: parent.width
                spacing: 10
                Repeater {
                    model: Object.keys(page.rs.themes || {})
                    delegate: Rectangle {
                        readonly property var th: page.rs.themes[modelData]
                        readonly property bool on: page.v("theme", "shadow") === modelData
                        width: 124
                        height: 84
                        radius: 14
                        color: "#141414"
                        border.width: on ? 2 : 1
                        border.color: on ? "#F6F5F4" : (tMouse.containsMouse ? "#3a3a3a" : "#2a2a2a")
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Rectangle {
                            x: 10; y: 10
                            width: parent.width - 20; height: 34
                            radius: 8
                            color: th.bg
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.12)
                            Rectangle { x: 6; y: 6; width: 34; height: 8; radius: 4; color: th.alt }
                            Rectangle { x: 6; y: 18; width: parent.width - 12; height: 10; radius: 5; color: th.sel }
                        }
                        T {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 54
                            text: th.name
                            font.pixelSize: 12
                            font.bold: on
                        }
                        MouseArea {
                            id: tMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.setv("theme", modelData)
                        }
                    }
                }
            }

            T { kind: "title"; text: "Layout"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            SegRow {
                label: "Style"
                desc: "List, icon grid, or a full-width bar"
                options: [
                    { label: "List", value: "list" },
                    { label: "Grid", value: "grid" },
                    { label: "Bar", value: "bar" }
                ]
                current: page.v("layout", "list")
                onChosen: function(x) { page.setv("layout", x) }
            }
            SegRow {
                label: "Position"
                desc: "Where the launcher opens on the screen"
                options: [
                    { label: "Top", value: "top" },
                    { label: "Center", value: "center" },
                    { label: "Bottom", value: "bottom" }
                ]
                current: page.v("position", "center")
                onChosen: function(x) { page.setv("position", x) }
            }
            SliderRow {
                label: "Width"
                desc: "Not used by the bar style"
                from: 360; to: 1200; step: 20
                value: page.v("width", 620)
                unit: " px"
                onCommitted: function(x) { page.setv("width", Math.round(x)) }
            }
            SliderRow {
                label: "Rows"
                desc: "How many results are visible"
                from: 3; to: 14; step: 1
                value: page.v("lines", 8)
                onCommitted: function(x) { page.setv("lines", Math.round(x)) }
            }

            T { kind: "title"; text: "Appearance"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            ToggleRow {
                label: "Transparency"
                desc: "Translucent background; off makes it solid"
                checked: page.v("transparency", true) === true
                onToggled: function(x) { page.setv("transparency", x ? "on" : "off") }
            }
            SliderRow {
                label: "Opacity"
                desc: "Lower is more transparent"
                from: 0.3; to: 1.0; step: 0.02
                decimals: 2
                value: page.v("opacity", 0.82)
                onCommitted: function(x) { page.setv("opacity", x.toFixed(2)) }
            }
            ToggleRow {
                label: "Blur"
                desc: "Blur whatever is behind the launcher (needs transparency)"
                checked: page.v("blur", true) === true
                onToggled: function(x) { page.setv("blur", x ? "on" : "off") }
            }
            SliderRow {
                label: "Corner radius"
                desc: "Roundness of the window"
                from: 0; to: 32; step: 1
                value: page.v("radius", 18)
                unit: " px"
                onCommitted: function(x) { page.setv("radius", Math.round(x)) }
            }

            T { kind: "title"; text: "Text"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            SliderRow {
                label: "Font size"
                desc: "The font comes from Services > Fonts (monospace)"
                from: 9; to: 20; step: 1
                value: page.v("font_size", 13)
                unit: " pt"
                onCommitted: function(x) { page.setv("font_size", Math.round(x)) }
            }
            ToggleRow {
                label: "App icons"
                desc: "Show icons next to the results"
                checked: page.v("icons", true) === true
                onToggled: function(x) { page.setv("icons", x ? "on" : "off") }
            }

            Row {
                spacing: 10
                topPadding: 8
                Rectangle {
                    width: 150; height: 38; radius: 12
                    color: pMouse.containsMouse ? "#ffffff" : "#F6F5F4"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    T { anchors.centerIn: parent; text: "Preview"; font.pixelSize: 13; font.bold: true; color: "#0d0d0d" }
                    MouseArea {
                        id: pMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bash", "-c", "sleep 0.3; rofi -show drun"])
                    }
                }
                Rectangle {
                    width: 150; height: 38; radius: 12
                    color: rMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    T { anchors.centerIn: parent; text: "Reset"; font.pixelSize: 13 }
                    MouseArea {
                        id: rMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-rofi\" reset"])
                            page.ctl.status = "Rofi reset"
                            refresh.restart()
                        }
                    }
                }
            }

            T {
                visible: page.rs.installed === false
                width: parent.width
                text: "rofi was not found on this system. Install it to use these settings."
                color: "#e0a050"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
