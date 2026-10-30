import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string user: Quickshell.env("USER")
    property string distro: "Linux"
    property bool closing: false
    readonly property int life: 12000

    Process {
        command: ["bash", "-c", ". /etc/os-release 2>/dev/null; echo \"${PRETTY_NAME:-${NAME:-Linux}}\""]
        running: true
        stdout: StdioCollector { onStreamFinished: { const t = text.trim(); if (t.length > 0) root.distro = t } }
    }

    function close() {
        if (closing) return
        closing = true
        fade.start()
    }

    PanelWindow {
        id: win
        color: "transparent"
        implicitWidth: 560
        implicitHeight: 350
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "rice-welcome"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 28
            color: Qt.rgba(0.07, 0.07, 0.08, 0.62)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.09)
            opacity: 0
            scale: 0.94
            transformOrigin: Item.Center

            NumberAnimation on opacity { id: fin; to: 1; duration: 380; easing.type: Easing.OutCubic; running: true }
            NumberAnimation on scale { to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.8; running: true }
            NumberAnimation { id: fade; target: card; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic; onFinished: Qt.quit() }

            // soft glow behind the title
            Rectangle {
                width: 420; height: 160; radius: 80
                anchors.horizontalCenter: parent.horizontalCenter
                y: 20
                color: Qt.rgba(0.55, 0.48, 1, 0.10)
            }

            RoundImage {
                id: face
                width: 84; height: 84
                cornerRadius: 24
                anchors.horizontalCenter: parent.horizontalCenter
                y: 30
                source: "file://" + root.home + "/.face"
                fallback: root.user.length > 0 ? root.user[0].toUpperCase() : "?"
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 128
                spacing: 6
                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    kind: "title"
                    text: "Welcome to Shadow's Shell"
                    font.pixelSize: 26
                    font.bold: true
                }
                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Hi " + root.user + "  ·  " + root.distro
                    font.pixelSize: 13
                    color: "#9a9aa4"
                }
            }

            Row {
                id: tips
                anchors.horizontalCenter: parent.horizontalCenter
                y: 202
                spacing: 10
                Repeater {
                    model: [
                        { k: "SUPER + U", v: "Settings" },
                        { k: "SUPER + Q", v: "Terminal" },
                        { k: "SUPER + W", v: "Wallpaper" }
                    ]
                    delegate: Rectangle {
                        width: 160; height: 52; radius: 14
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            T { anchors.horizontalCenter: parent.horizontalCenter; kind: "mono"; text: modelData.k; font.pixelSize: 12; font.bold: true }
                            T { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; font.pixelSize: 11; color: "#8a8a94" }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 274
                spacing: 12

                Rectangle {
                    width: 168; height: 40; radius: 14
                    color: openMouse.containsMouse ? "#ffffff" : "#F6F5F4"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    T { anchors.centerIn: parent; text: "Open Settings"; font.pixelSize: 13; font.bold: true; color: "#0d0d0d" }
                    MouseArea {
                        id: openMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-settings\""])
                            root.close()
                        }
                    }
                }
                Rectangle {
                    width: 110; height: 40; radius: 14
                    color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    T { anchors.centerIn: parent; text: "Close"; font.pixelSize: 13 }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            T {
                id: never
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                text: "Don't show again"
                font.pixelSize: 10
                color: neverMouse.containsMouse ? "#c8c8cc" : "#6a6a72"
                MouseArea {
                    id: neverMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-welcome\" off"])
                        root.close()
                    }
                }
            }

            // time left, pauses while the pointer is over the card
            Rectangle {
                id: bar
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 28
                anchors.bottomMargin: 0
                height: 2
                radius: 1
                color: Qt.rgba(1, 1, 1, 0.28)
                width: 0
                NumberAnimation on width {
                    id: life
                    from: card.width - 56
                    to: 0
                    duration: root.life
                    running: true
                    paused: hover.hovered
                    onFinished: root.close()
                }
            }
            HoverHandler { id: hover }
        }
    }
}
