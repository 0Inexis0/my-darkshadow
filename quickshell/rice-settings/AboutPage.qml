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
            height: 64
            radius: 14
            color: "#141414"
            border.width: 1
            border.color: "#1f1f1f"
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                T { text: "Dotfiles"; font.pixelSize: 14 }
                T { kind: "reading"; text: "Shadow's Shell"; color: "#8a8a8a"; font.pixelSize: 12 }
            }
            T { kind: "icon"; anchors.right: parent.right; anchors.rightMargin: 18; anchors.verticalCenter: parent.verticalCenter; text: ""; color: "#8a8a8a" }
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
