import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
    id: page
    property var ctl
    readonly property string home: Quickshell.env("HOME")
    readonly property string user: Quickshell.env("USER")
    readonly property string faceUrl: "file://" + home + "/.face"

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Choose a profile picture", "--file-filter=Images | *.png *.jpg *.jpeg *.webp"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0) {
                    Quickshell.execDetached(["bash", "-c", "cp -f \"$1\" \"$HOME/.face\"", "_", p])
                    faceReload.restart()
                }
            }
        }
    }

    Timer {
        id: faceReload
        interval: 400
        onTriggered: { avatarImg.source = ""; avatarImg.source = page.faceUrl }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            x: 24
            y: 28
            width: flick.width - 48
            spacing: 12

            Item {
                id: avatar
                width: 112
                height: 112
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    visible: false
                    source: page.faceUrl
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    sourceSize.width: 256
                    sourceSize.height: 256
                }
                Item {
                    id: maskItem
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    Rectangle { anchors.fill: parent; radius: width / 2 }
                }
                MultiEffect {
                    anchors.fill: parent
                    source: avatarImg
                    maskEnabled: true
                    maskSource: maskItem
                    visible: avatarImg.status === Image.Ready
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    visible: avatarImg.status !== Image.Ready
                    color: "#161616"
                    border.width: 2
                    border.color: "#3a3a3a"
                    T { anchors.centerIn: parent; text: "+"; color: "#8a8a8a"; font.pixelSize: 44 }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(0, 0, 0, 0.5)
                    opacity: avatarMouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    T { anchors.centerIn: parent; text: "Change"; font.pixelSize: 13; font.bold: true }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: "#F6F5F4"
                    opacity: avatarMouse.containsMouse ? 0.9 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
                MouseArea {
                    id: avatarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.running = true
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                T { text: "\uf015"; font.pixelSize: 24; anchors.verticalCenter: parent.verticalCenter }
                T { text: "Welcome back, " + page.user; font.pixelSize: 24; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }

            T {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Make your desktop feel like home."
                color: "#8a8a8a"
                font.pixelSize: 13
                bottomPadding: 10
            }

            T { text: "Wallpapers & Colors"; font.pixelSize: 16; font.bold: true }

            SettingRow {
                label: "Wallpaper"
                desc: "Pick a wallpaper (same as SUPER + W)"
                Pill {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    label: "Change"
                    onClicked: Quickshell.execDetached(["qs", "-n", "-p", page.home + "/.config/quickshell/hyprquickpaper"])
                }
            }

            SettingRow {
                label: "Color mode"
                desc: "How colors are taken from the wallpaper"
                Seg {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    options: [
                        { label: "Auto", value: "auto" },
                        { label: "Grey", value: "grey" },
                        { label: "Navy", value: "navy" }
                    ]
                    current: page.ctl.colorMode
                    onChosen: function(v) { page.ctl.setColorMode(v) }
                }
            }

            T { text: "Bar & Screen"; font.pixelSize: 16; font.bold: true; topPadding: 12 }

            SettingRow {
                label: "Bar transparency"
                desc: "Translucent bar with blur; off makes it solid"
                Tog {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    checked: page.ctl.st.transparent === true
                    onToggled: function(v) {
                        page.ctl.setSt("transparent", v)
                        page.ctl.run(["transparency", v ? "on" : "off"])
                    }
                }
            }

            SettingRow {
                label: "Bar position"
                desc: "Top or bottom of the screen"
                Seg {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    options: [
                        { label: "Top", value: "top" },
                        { label: "Bottom", value: "bottom" }
                    ]
                    current: page.ctl.st.position !== undefined ? page.ctl.st.position : "top"
                    onChosen: function(v) {
                        page.ctl.setSt("position", v)
                        page.ctl.run(["position", v])
                    }
                }
            }

            SettingRow {
                label: "Bar style"
                desc: "Flat bar, floating bar or separate islands"
                Seg {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    options: [
                        { label: "Flat", value: "flat" },
                        { label: "Floating", value: "floating" },
                        { label: "Islands", value: "islands" }
                    ]
                    current: page.ctl.st.style !== undefined ? page.ctl.st.style : "flat"
                    onChosen: function(v) {
                        page.ctl.setSt("style", v)
                        page.ctl.run(["style", v])
                    }
                }
            }
        }
    }
}
