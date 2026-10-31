import Quickshell
import QtQuick

Item {
    id: page
    property var ctl

    readonly property var widgets: [
        { key: "weather", label: "Weather", icon: "", desc: "Temperature and sky" },
        { key: "media", label: "Media player", icon: "", desc: "Now playing + controls" },
        { key: "resources", label: "Resources", icon: "", desc: "CPU, RAM and GPU" },
        { key: "usercard", label: "User card", icon: "", desc: "Greeting and date" },
        { key: "calendar", label: "Calendar", icon: "", desc: "Month view" },
        { key: "visualizer", label: "Visualizer", icon: "\uf001", desc: "See-through, at the bottom" },
        { key: "battery", label: "Battery", icon: "\uf240", desc: "Charge and time left" }
    ]

    function wOn(k) {
        const w = page.ctl.dst.widgets
        return w && w[k] ? w[k].enabled === true : false
    }
    function cv(k, d) {
        const c = page.ctl.dst.clock
        return c && c[k] !== undefined ? c[k] : d
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

            T { kind: "title"; text: "Widgets"; font.pixelSize: 16; font.bold: true }
            // the widget editor on the desktop (Settings closes so you can see it)
            Rectangle {
                width: parent.width
                height: 72
                radius: 14
                color: edMouse.containsMouse ? "#1c1c1c" : "#141414"
                border.width: 1
                border.color: "#2a2a2a"
                Behavior on color { ColorAnimation { duration: 140 } }
                Rectangle {
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 42; radius: 12
                    color: "#F6F5F4"
                    T { kind: "icon"; anchors.centerIn: parent; text: "\uf044"; font.pixelSize: 17; color: "#0d0d0d" }
                }
                Column {
                    x: 72; anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    T { text: "Edit widgets"; font.pixelSize: 15; font.bold: true }
                    T { kind: "reading"; text: "Add, move, resize and style widgets right on your desktop"; font.pixelSize: 12; color: "#8a8a8a" }
                }
                T { kind: "icon"; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: "\uf054"; color: "#8a8a8a" }
                MouseArea {
                    id: edMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/desktop-set\" edit on"])
                        Qt.quit()
                    }
                }
            }
            T {
                width: parent.width
                text: "Switch a widget on to put it on the desktop. Edit widgets opens the editor on your desktop: add widgets, drag them, pull a corner to resize, change style and opacity. Shortcut: SUPER + ALT + W."
                color: "#8a8a8a"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Flickable {
                id: rowFlick
                width: parent.width
                height: 150
                contentWidth: wrow.width
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Behavior on contentX {
                    enabled: !rowFlick.dragging && !rowFlick.flicking
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(e) {
                        const max = Math.max(0, rowFlick.contentWidth - rowFlick.width)
                        rowFlick.contentX = Math.max(0, Math.min(max, rowFlick.contentX - (e.angleDelta.y + e.angleDelta.x) * 0.7))
                    }
                }

                Row {
                    id: wrow
                    spacing: 10
                    Repeater {
                        model: page.widgets
                        delegate: Rectangle {
                            id: card
                            width: 172
                            height: 146
                            radius: 14
                            readonly property bool on: page.wOn(modelData.key)
                            color: cardMouse.containsMouse ? "#1c1c1c" : "#141414"
                            border.width: 1
                            border.color: card.on ? "#5a5a5a" : "#1f1f1f"
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.ctl.dset("widget", modelData.key, card.on ? "off" : "on")
                            }
                            Rectangle {
                                x: 14
                                y: 14
                                width: 40
                                height: 40
                                radius: 12
                                color: card.on ? "#F6F5F4" : "#202020"
                                Behavior on color { ColorAnimation { duration: 200 } }
                                T { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 18; color: card.on ? "#0d0d0d" : "#F6F5F4" }
                            }
                            Column {
                                x: 14
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 14
                                spacing: 3
                                T { text: modelData.label; font.pixelSize: 14; font.bold: true }
                                T { text: modelData.desc; font.pixelSize: 10; color: "#8a8a8a" }
                            }
                            Tog {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                y: 22
                                checked: card.on
                                onToggled: function(v) { page.ctl.dset("widget", modelData.key, v ? "on" : "off") }
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 8
                Pill { label: "Reset widget positions"; onClicked: page.ctl.dreset() }
            }

            T { kind: "title"; text: "Clock"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            ToggleRow {
                label: "Enable"
                desc: "Show a clock on the desktop"
                checked: page.cv("enabled", false) === true
                onToggled: function(v) { page.ctl.dset("clock", "enabled", v ? "on" : "off") }
            }
            ToggleRow {
                label: "Show only when locked"
                desc: "Hide it on the desktop"
                checked: page.cv("onlyLocked", false) === true
                onToggled: function(v) { page.ctl.dset("clock", "onlyLocked", v ? "on" : "off") }
            }
            SegRow {
                label: "Placement strategy"
                desc: "Drag it, or auto-pick a spot"
                options: [
                    { label: "Draggable", value: "draggable" },
                    { label: "Least busy", value: "leastBusy" },
                    { label: "Most busy", value: "mostBusy" }
                ]
                current: page.cv("placement", "draggable")
                onChosen: function(v) { page.ctl.dset("clock", "placement", v) }
            }
            SegRow {
                label: "Clock style"
                desc: "Look of the desktop clock"
                options: [
                    { label: "Digital", value: "digital" },
                    { label: "Cookie", value: "cookie" },
                    { label: "Pixel", value: "pixel" }
                ]
                current: page.cv("style", "digital")
                onChosen: function(v) { page.ctl.dset("clock", "style", v) }
            }
        }
    }
}
