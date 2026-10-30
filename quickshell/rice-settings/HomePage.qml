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

            T { kind: "title"; text: "Colors"; font.pixelSize: 16; font.bold: true }

            T {
                width: parent.width
                text: "Pick a color scheme. Auto takes colors from your wallpaper, the rest use fixed colors."
                color: "#8a8a8a"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Flow {
                width: parent.width
                spacing: 10
                Repeater {
                    model: page.ctl.schemes
                    delegate: Rectangle {
                        readonly property bool on: page.ctl.colorMode === modelData.key
                        width: 104
                        height: 74
                        radius: 14
                        color: "#141414"
                        border.width: on ? 2 : 1
                        border.color: on ? "#F6F5F4" : (cMouse.containsMouse ? "#3a3a3a" : "#2a2a2a")
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Rectangle {
                            x: 8; y: 8
                            width: parent.width - 16; height: 36
                            radius: 9
                            color: modelData.preview[0]
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10)
                            Rectangle { x: 7; y: 7; width: 30; height: 8; radius: 4; color: modelData.preview[1] }
                            Rectangle { x: 7; y: 19; width: parent.width - 14; height: 9; radius: 4; color: modelData.preview[2]; opacity: 0.85 }
                        }
                        T {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 50
                            text: modelData.name
                            font.pixelSize: 12
                            font.bold: on
                        }
                        MouseArea {
                            id: cMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.ctl.setColorMode(modelData.key)
                        }
                    }
                }
            }

            T { kind: "title"; text: "Bar & Screen"; font.pixelSize: 16; font.bold: true; topPadding: 12 }

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
        }
    }
}