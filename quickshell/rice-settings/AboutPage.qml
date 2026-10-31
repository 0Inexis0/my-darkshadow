import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: page
    property var ctl
    property string distroName: "Linux"
    property string distroId: "linux"
    property string distroUrl: ""
    property string distroVersion: ""

    readonly property var glyphs: ({
        "nixos": "", "arch": "", "ubuntu": "", "fedora": "",
        "debian": "", "manjaro": "", "endeavouros": "", "opensuse": ""
    })
    function glyph() { return glyphs[distroId] !== undefined ? glyphs[distroId] : "" }
    function open(url) { Quickshell.execDetached(["xdg-open", url]) }

    // updates: rice-update compares your version with the newest one on GitHub
    property var up: ({ installed: "", latest: "", update: false, error: "", news: [], changes: 0 })
    property bool checking: true
    function checkUpdates() { page.checking = true; upProc.running = true }
    function runUpdate() {
        Quickshell.execDetached(["bash", "-c", "t=\"${TERMINAL:-kitty}\"; command -v \"$t\" >/dev/null || t=kitty; exec \"$t\" -e \"$HOME/.local/bin/rice-update\""])
    }
    Process {
        id: upProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-update\" check --json 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.up = JSON.parse(text) } catch (e) { page.up = { installed: "", latest: "", update: false, error: "rice-update is missing" } }
                page.checking = false
            }
        }
    }

    Process {
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; printf '%s\\n%s\\n%s\\n%s\\n' \"${NAME:-Linux}\" \"${ID:-linux}\" \"${HOME_URL:-}\" \"${VERSION:-}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("\n")
                if (p.length >= 3) {
                    page.distroName = p[0]
                    page.distroId = p[1]
                    page.distroUrl = p[2]
                    page.distroVersion = p[3] !== undefined ? p[3] : ""
                }
            }
        }
    }

    Column {
        id: top
        anchors.horizontalCenter: parent.horizontalCenter
        y: 30
        width: parent.width - 48
        spacing: 14

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 112
            height: 112
            radius: 32
            color: "#161616"
            border.width: 1
            border.color: "#2a2a2a"
            T { kind: "icon"; anchors.centerIn: parent; text: page.glyph(); font.pixelSize: 62 }
        }

        T {
            kind: "title"
            anchors.horizontalCenter: parent.horizontalCenter
            text: page.distroName
            font.pixelSize: 26
            font.bold: true
        }
        T {
            kind: "reading"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: page.distroVersion.length > 0
            text: page.distroVersion
            color: "#8a8a8a"
            font.pixelSize: 12
        }

        Item { width: 1; height: 6 }

        Rectangle {
            width: parent.width
            height: 64
            radius: 14
            color: webMouse.containsMouse ? "#1c1c1c" : "#141414"
            border.width: 1
            border.color: "#1f1f1f"
            Behavior on color { ColorAnimation { duration: 140 } }
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                T { text: "Distro website"; font.pixelSize: 14 }
                T { kind: "reading"; text: page.distroUrl.length > 0 ? page.distroUrl : "https://nixos.org"; color: "#8a8a8a"; font.pixelSize: 12 }
            }
            T { kind: "icon"; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: ""; color: "#8a8a8a" }
            MouseArea {
                id: webMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.open(page.distroUrl.length > 0 ? page.distroUrl : "https://nixos.org")
            }
        }

        Rectangle {
            width: parent.width
            height: 72
            radius: 14
            color: "#141414"
            border.width: 1
            border.color: page.up.update ? Qt.rgba(1, 1, 1, 0.22) : "#1f1f1f"
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.right: upBtn.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Row {
                    spacing: 8
                    T { text: "DarkShadow's Shell"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        visible: page.up.installed.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: verT.implicitWidth + 14
                        height: 20
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.08)
                        T { id: verT; kind: "reading"; anchors.centerIn: parent; text: "V" + page.up.installed; font.pixelSize: 11; color: "#cfcfcf" }
                    }
                }
                Row {
                    spacing: 6
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7; height: 7; radius: 3.5
                        color: page.checking ? "#8a8a8a" : (page.up.update ? "#F6F5F4" : (page.up.error ? "#e0a050" : "#7bd88f"))
                        SequentialAnimation on opacity {
                            running: page.checking || page.up.update
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }
                    T {
                        kind: "reading"
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.checking ? "Checking for updates..."
                            : page.up.update ? (page.up.latest === page.up.installed && page.up.changes > 0
                                ? page.up.changes + " new change" + (page.up.changes === 1 ? "" : "s") + " for V" + page.up.latest
                                : "Update V" + page.up.latest + " is available")
                            : page.up.error ? "Up to date as far as we know (offline?)"
                            : "Up to date"
                        color: page.up.update ? "#F6F5F4" : "#8a8a8a"
                        font.pixelSize: 12
                    }
                }
            }
            Btn {
                id: upBtn
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                primary: page.up.update && !page.checking
                icon: page.up.update ? "\uf019" : "\uf00c"
                text: page.checking ? "Checking..." : (page.up.update ? "Update now" : "Up to date")
                // update: opens a terminal so you can see it and type your sudo password; otherwise: check again
                onClicked: { if (page.checking) return; if (page.up.update) page.runUpdate(); else page.checkUpdates() }
            }
        }

        // what the new version brings (from CHANGELOG.md)
        Rectangle {
            visible: page.up.update === true && (page.up.news || []).length > 0 && !page.checking
            width: parent.width
            height: newsCol.implicitHeight + 26
            radius: 14
            color: "#121212"
            border.width: 1
            border.color: "#1f1f1f"
            Column {
                id: newsCol
                x: 18; y: 13
                width: parent.width - 36
                spacing: 6
                T { kind: "reading"; text: "WHAT'S NEW"; font.pixelSize: 10; font.letterSpacing: 1.2; color: "#7a7a84" }
                Repeater {
                    model: page.up.news || []
                    delegate: Row {
                        spacing: 8
                        width: newsCol.width
                        Rectangle { width: 4; height: 4; radius: 2; color: "#F6F5F4"; anchors.verticalCenter: parent.verticalCenter }
                        T { text: modelData; font.pixelSize: 12; color: "#cfcfcf"; width: parent.width - 12; elide: Text.ElideRight }
                    }
                }
            }
        }
    }

    Rectangle {
        id: creator
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 48
        height: 64
        radius: 14
        color: ttMouse.containsMouse ? "#1c1c1c" : "#141414"
        border.width: 1
        border.color: "#1f1f1f"
        Behavior on color { ColorAnimation { duration: 140 } }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            T { kind: "reading"; text: "Created by"; color: "#8a8a8a"; font.pixelSize: 11 }
            T { text: "shadoww.dev on TikTok"; font.pixelSize: 14; font.bold: true }
        }
        T { kind: "icon"; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: ""; color: "#8a8a8a" }
        MouseArea {
            id: ttMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: page.open("https://www.tiktok.com/@shadoww.dev")
        }
    }
}
