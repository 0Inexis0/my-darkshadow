import Quickshell
import QtQuick

Item {
    id: page
    property var ctl
    property string openZone: ""

    readonly property var labels: ({
        "image#nix": "NixOS logo",
        "group/ws": "Workspaces",
        "mpris": "Music",
        "wireplumber": "Volume",
        "clock": "Clock",
        "group/apps": "System icons",
        "custom/notification": "Notifications",
        "custom/lock": "Power"
    })
    readonly property var zones: ["left", "center", "right"]

    function pname(n) {
        if (n === "current") return "Waybar config 1"
        if (n === "old") return "Waybar config 2"
        return n
    }

    function lbl(n) { return labels[n] !== undefined ? labels[n] : n }

    function layout() {
        const l = page.ctl.st.layout
        return l !== undefined ? l : { left: [], center: [], right: [], available: [] }
    }

    function mutate(fn) {
        const L = JSON.parse(JSON.stringify(layout()))
        fn(L)
        page.ctl.setSt("layout", L)
    }

    function addTo(zone, name) {
        mutate(function(L) {
            for (let i = 0; i < page.zones.length; i++) {
                const z = page.zones[i]
                L[z] = L[z].filter(function(x) { return x !== name })
            }
            L.available = L.available.filter(function(x) { return x !== name })
            L[zone].push(name)
        })
        page.ctl.run(["layout-add", zone, name])
    }

    function removeFrom(zone, name) {
        mutate(function(L) {
            L[zone] = L[zone].filter(function(x) { return x !== name })
            L.available.push(name)
        })
        page.ctl.run(["layout-remove", zone, name])
    }

    function moveIn(zone, name, dir) {
        mutate(function(L) {
            const a = L[zone]
            const i = a.indexOf(name)
            const j = dir === "left" ? i - 1 : i + 1
            if (i < 0 || j < 0 || j >= a.length) return
            const t = a[i]
            a[i] = a[j]
            a[j] = t
        })
        page.ctl.run(["layout-move", zone, name, dir])
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
                flick.contentY = Math.max(0, Math.min(max, flick.contentY - e.angleDelta.y * 0.9))
            }
        }

        Column {
            id: col
            width: flick.width
            spacing: 10

            T { kind: "title"; text: "Bar layout"; font.pixelSize: 16; font.bold: true }
            T {
                width: parent.width
                text: "Arrange what sits on the left, in the middle and on the right. Use ‹ › to reorder, × to remove and + to add."
                color: "#8a8a8a"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            ZoneCard {
                title: "Left"
                items: page.layout().left
                available: page.layout().available
                labelOf: page.lbl
                adding: page.openZone === "left"
                onAddToggled: page.openZone = (page.openZone === "left" ? "" : "left")
                onAddRequested: function(n) { page.addTo("left", n) }
                onRemoveRequested: function(n) { page.removeFrom("left", n) }
                onMoveRequested: function(n, d) { page.moveIn("left", n, d) }
            }
            ZoneCard {
                title: "Center"
                items: page.layout().center
                available: page.layout().available
                labelOf: page.lbl
                adding: page.openZone === "center"
                onAddToggled: page.openZone = (page.openZone === "center" ? "" : "center")
                onAddRequested: function(n) { page.addTo("center", n) }
                onRemoveRequested: function(n) { page.removeFrom("center", n) }
                onMoveRequested: function(n, d) { page.moveIn("center", n, d) }
            }
            ZoneCard {
                title: "Right"
                items: page.layout().right
                available: page.layout().available
                labelOf: page.lbl
                adding: page.openZone === "right"
                onAddToggled: page.openZone = (page.openZone === "right" ? "" : "right")
                onAddRequested: function(n) { page.addTo("right", n) }
                onRemoveRequested: function(n) { page.removeFrom("right", n) }
                onMoveRequested: function(n, d) { page.moveIn("right", n, d) }
            }

            T { kind: "title"; text: "Positioning & styles"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            SegRow {
                label: "Bar position"
                desc: "Top or bottom edge of the screen"
                options: [
                    { label: "Top", value: "top" },
                    { label: "Bottom", value: "bottom" }
                ]
                current: page.ctl.st.position !== undefined ? page.ctl.st.position : "top"
                onChosen: function(v) { page.ctl.setSt("position", v); page.ctl.run(["position", v]) }
            }

            SegRow {
                label: "Bar style"
                desc: "Flat, floating, separate islands or a single centered island"
                options: [
                    { label: "Flat", value: "flat" },
                    { label: "Floating", value: "floating" },
                    { label: "Islands", value: "islands" },
                    { label: "One island", value: "island" }
                ]
                current: page.ctl.st.style !== undefined ? page.ctl.st.style : "flat"
                onChosen: function(v) {
                    page.ctl.setSt("style", v)
                    if (v === "islands" && page.ctl.st.group === "none") page.ctl.setSt("group", "pills")
                    page.ctl.run(["style", v])
                }
            }

            SegRow {
                label: "Group style"
                desc: "Module backgrounds"
                options: [
                    { label: "None", value: "none" },
                    { label: "Pills", value: "pills" },
                    { label: "Segmented", value: "segmented" }
                ]
                current: page.ctl.st.group !== undefined ? page.ctl.st.group : "none"
                onChosen: function(v) { page.ctl.setSt("group", v); page.ctl.run(["group", v]) }
            }

            ToggleRow {
                label: "Autohide"
                desc: "Hidden until the pointer touches the screen edge"
                checked: page.ctl.st.autohide === true
                onToggled: function(v) { page.ctl.setSt("autohide", v); page.ctl.run(["autohide", v ? "on" : "off"]) }
            }

            T { kind: "title"; text: "Appearance"; font.pixelSize: 16; font.bold: true; topPadding: 14 }

            SettingRow {
                reserved: 300
                label: "Bar opacity"
                desc: "Background of the bar. Lower means more transparent."
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    T {
                        text: Math.round(opSlide.shown * 100) + "%"
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 13
                        color: "#8a8a8a"
                    }
                    Slide {
                        id: opSlide
                        from: 0.1
                        to: 1.0
                        step: 0.05
                        value: page.ctl.st.opacity !== undefined ? page.ctl.st.opacity : 0.45
                        onReleased: function(v) {
                            page.ctl.setSt("opacity", v)
                            page.ctl.setSt("transparent", v < 0.99)
                            page.ctl.run(["opacity", v.toFixed(2)])
                        }
                    }
                }
            }

            SettingRow {
                reserved: 300
                label: "Bar height"
                desc: "Vertical padding of the modules."
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    T {
                        text: Math.round(hSlide.shown) + " px"
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 13
                        color: "#8a8a8a"
                    }
                    Slide {
                        id: hSlide
                        from: 0
                        to: 8
                        step: 1
                        value: page.ctl.st.height !== undefined ? page.ctl.st.height : 4
                        onReleased: function(v) {
                            page.ctl.setSt("height", Math.round(v))
                            page.ctl.run(["height", Math.round(v)])
                        }
                    }
                }
            }

            T { kind: "title"; text: "Layouts"; font.pixelSize: 16; font.bold: true; topPadding: 14 }
            T {
                width: parent.width
                text: "Saved bar configs. Apply one to switch instantly; the previous one is kept for undo."
                color: "#8a8a8a"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: page.ctl.presets.slice(0, 6)
                delegate: Rectangle {
                    width: col.width
                    height: 46
                    radius: 10
                    color: rowMouse.containsMouse ? "#1c1c1c" : "#141414"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    T {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.pname(modelData)
                    }
                    T {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Apply"
                        font.pixelSize: 13
                        color: rowMouse.containsMouse ? "#F6F5F4" : "#8a8a8a"
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", page.ctl.presetTool, "apply", modelData])
                            page.ctl.status = "Applied: " + page.pname(modelData)
                            page.ctl.stateTimer.restart()
                        }
                    }
                }
            }

            T {
                visible: page.ctl.presets.length === 0
                text: "No presets yet. Save the current bar below."
                color: "#8a8a8a"
                font.pixelSize: 13
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: parent.width - savePill.width - parent.spacing
                    height: 38
                    radius: 10
                    color: "#141414"
                    border.width: 1
                    border.color: nameInput.activeFocus ? "#5a5a5a" : "#2a2a2a"

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#F6F5F4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        onAccepted: savePill.clicked()
                    }
                    T {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Preset name"
                        color: "#6a6a6a"
                        font.pixelSize: 13
                        visible: nameInput.text.length === 0
                    }
                }

                Pill {
                    id: savePill
                    label: "Save current"
                    onClicked: {
                        const n = nameInput.text.trim()
                        if (n.length === 0) { page.ctl.status = "Type a name first"; return }
                        Quickshell.execDetached(["bash", page.ctl.presetTool, "save", n])
                        nameInput.text = ""
                        page.ctl.status = "Saved: " + n
                        page.ctl.stateTimer.restart()
                    }
                }
            }

            Row {
                spacing: 8
                Pill {
                    label: "Undo last change"
                    onClicked: {
                        Quickshell.execDetached(["bash", page.ctl.presetTool, "apply", "_last"])
                        page.ctl.status = "Switched back"
                        page.ctl.stateTimer.restart()
                    }
                }
                Pill {
                    label: "Reload bar"
                    onClicked: {
                        Quickshell.execDetached(["bash", page.ctl.home + "/.local/bin/waybar-reload"])
                        page.ctl.status = "Bar reloaded"
                    }
                }
            }
        }
    }
}
