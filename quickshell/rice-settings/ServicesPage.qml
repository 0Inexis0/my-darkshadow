import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl
    property var fonts: ({})

    readonly property var roles: [
        { key: "main", label: "Main font", desc: "Interface text, e.g. Rubik" },
        { key: "numbers", label: "Numbers family", desc: "Digits in clocks and stats, e.g. Rubik" },
        { key: "title", label: "Title family", desc: "Headings, e.g. Gabarito" },
        { key: "mono", label: "Monospace font", desc: "Terminal, e.g. JetBrains Mono NF" },
        { key: "icons", label: "Nerd font icons", desc: "Symbols, e.g. JetBrains Mono NF" },
        { key: "reading", label: "Reading font", desc: "Descriptions, e.g. Readex Pro" }
    ]

    function applyFont(key, value) {
        setProc.command = ["bash", "-c", "\"$HOME/.local/bin/font-set\" set \"$1\" \"$2\" 2>&1", "_", key, value]
        setProc.running = true
    }

    Process {
        id: stateProc
        command: ["bash", "-c", "\"$HOME/.local/bin/font-set\" state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { page.fonts = JSON.parse(text) } catch (e) { } }
        }
    }
    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: {
                page.ctl.status = text.trim()
                refresh.restart()
            }
        }
    }
    Process {
        id: resetProc
        command: ["bash", "-c", "\"$HOME/.local/bin/font-set\" reset 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.ctl.status = text.trim()
                refresh.restart()
            }
        }
    }
    Timer { id: refresh; interval: 500; onTriggered: stateProc.running = true }

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

            T { kind: "title"; text: "Fonts"; font.pixelSize: 16; font.bold: true }
            T {
                width: parent.width
                kind: "reading"
                text: "Type the name of an installed font family and press Enter. Applies to the settings window, desktop widgets, Waybar (main + icons) and kitty (monospace)."
                color: "#8a8a8a"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: page.roles
                delegate: SettingRow {
                    reserved: 270
                    label: modelData.label
                    desc: modelData.desc
                    Field {
                        id: fld
                        width: 240
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.fonts[modelData.key] !== undefined ? page.fonts[modelData.key] : ""
                        placeholder: "Font family"
                        onAccepted: page.applyFont(modelData.key, text)
                    }
                }
            }

            Row {
                spacing: 8
                Pill { label: "Reset fonts"; onClicked: resetProc.running = true }
            }

            T { kind: "title"; text: "Autostart"; font.pixelSize: 16; font.bold: true; topPadding: 18 }

            AutostartPage { width: parent.width; ctl: page.ctl }
        }
    }
}
