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
    property date now: new Date()
    property string uptime: ""
    property int tip: 0
    readonly property var tips: [
        "Press SUPER + U anywhere to open these settings.",
        "SUPER + W opens the wallpaper menu. The Auto theme follows your new wallpaper.",
        "Drag the desktop widgets anywhere, their position is saved.",
        "Pick a scheme in Theme to recolor the bar, borders, notifications and lock screen.",
        "Try the One island bar style in Waybar for a floating look.",
        "Idle & Lockscreen decides when the screen locks and when the computer sleeps.",
        "Click your picture above to change it. It is also shown on the lock screen.",
        "Touch the bottom-right corner of the screen for quick toggles, apps and wallpapers.",
        "Type right away in the hot corner's Apps search and press Enter to launch.",
        "Keep Awake in the hot corner stops the screen from locking during a movie.",
        "Gaming mode turns off animations, blur and gaps. Click it again to bring them back.",
        "Notifications has nine popup styles. Try Island or Accent bar.",
        "Theme has 21 color schemes, from pure Mono to Ocean and Rose.",
        "Rofi can open as a full-width bar at the bottom of the screen.",
        "Lock screen clocks come in Big, Stacked and Minimal. Preview them in Idle & Lockscreen.",
        "Run rice-notify test in a terminal to see a sample notification.",
        "Everything here is also a command: waybar-set, rice-hotcorner, rice-lock, rice-notify."
    ]
    function greeting() {
        const h = now.getHours()
        return h < 5 ? "Good night" : (h < 12 ? "Good morning" : (h < 18 ? "Good afternoon" : "Good evening"))
    }
    function themeName() {
        const l = page.ctl.schemes || []
        for (let i = 0; i < l.length; i++) if (l[i].key === page.ctl.colorMode) return l[i].name
        return page.ctl.colorMode
    }

    Timer { interval: 15000; running: true; repeat: true; onTriggered: page.now = new Date() }
    Timer { interval: 7000; running: true; repeat: true; onTriggered: tipFade.restart() }
    Process {
        id: upProc
        command: ["bash", "-c", "cut -d. -f1 /proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text.trim())
                if (isNaN(t)) return
                const d = Math.floor(t / 86400), h = Math.floor(t % 86400 / 3600), m = Math.floor(t % 3600 / 60)
                page.uptime = (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m"
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: upProc.running = true }

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

            T {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.greeting() + ", " + page.user
                font.pixelSize: 26
                font.bold: true
            }
            T {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.now.toLocaleDateString(Qt.locale("en_US"), "dddd, d MMMM") + "  \u00b7  " + page.now.toLocaleTimeString(Qt.locale("en_US"), "HH:mm")
                color: "#8a8a8a"
                font.pixelSize: 13
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                topPadding: 2
                bottomPadding: 6
                Repeater {
                    model: [
                        { i: "\udb80\udfd8", t: "Theme \u00b7 " + page.themeName() },
                        { i: "\uf017", t: "Up " + page.uptime },
                        { i: page.ctl.osGlyph(), t: page.ctl.osName }
                    ]
                    delegate: Rectangle {
                        visible: modelData.t.length > 3
                        height: 30
                        width: chip.implicitWidth + 26
                        radius: 15
                        color: "#141414"
                        border.width: 1
                        border.color: "#222222"
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 7
                            T { kind: "icon"; text: modelData.i; font.pixelSize: 12; color: "#c8c8cc"; anchors.verticalCenter: parent.verticalCenter }
                            T { text: modelData.t; font.pixelSize: 12; color: "#c8c8cc"; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 84
                radius: 16
                border.width: 1
                border.color: "#222222"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#1a1922" }
                    GradientStop { position: 1; color: "#121214" }
                }
                Rectangle {
                    id: bulb
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46; height: 46; radius: 14
                    color: Qt.rgba(1, 1, 1, 0.06)
                    T { kind: "icon"; anchors.centerIn: parent; text: "\uf0eb"; font.pixelSize: 20 }
                }
                Column {
                    id: tipCol
                    anchors.left: bulb.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    T { text: "Make yourself at home"; font.pixelSize: 14; font.bold: true }
                    T { kind: "reading"; width: parent.width; text: page.tips[page.tip]; color: "#9a9aa4"; font.pixelSize: 12; wrapMode: Text.WordWrap }
                }
                SequentialAnimation {
                    id: tipFade
                    NumberAnimation { target: tipCol; property: "opacity"; to: 0; duration: 220 }
                    ScriptAction { script: page.tip = (page.tip + 1) % page.tips.length }
                    NumberAnimation { target: tipCol; property: "opacity"; to: 1; duration: 320 }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tipFade.restart() }
            }

            T { kind: "title"; text: "Make it yours"; font.pixelSize: 16; font.bold: true; topPadding: 10 }

            Flow {
                id: quick
                width: parent.width
                spacing: 10
                Repeater {
                    model: [
                        { i: "\udb80\udfd8", t: "Theme", d: "Colors & schemes", p: 4 },
                        { i: "\uf03e", t: "Wallpaper", d: "Pick a new one", p: -1 },
                        { i: "\uf0f3", t: "Notifications", d: "Popups & panel", p: 6 },
                        { i: "\uf023", t: "Lock screen", d: "Idle & lock", p: 7 },
                        { i: "\uf0c9", t: "Waybar", d: "Bar layout & style", p: 1 },
                        { i: "\uf002", t: "Rofi", d: "App launcher", p: 3 }
                    ]
                    delegate: Rectangle {
                        width: (quick.width - 20) / 3
                        height: 76
                        radius: 14
                        color: qMouse.containsMouse ? "#1b1b1d" : "#141414"
                        border.width: 1
                        border.color: qMouse.containsMouse ? "#333333" : "#1f1f1f"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle {
                            id: qi
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40; height: 40; radius: 12
                            color: Qt.rgba(1, 1, 1, 0.06)
                            T { kind: "icon"; anchors.centerIn: parent; text: modelData.i; font.pixelSize: 17 }
                        }
                        Column {
                            anchors.left: qi.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            T { text: modelData.t; font.pixelSize: 13; font.bold: true; width: parent.width; elide: Text.ElideRight }
                            T { kind: "reading"; text: modelData.d; font.pixelSize: 11; color: "#8a8a8a"; width: parent.width; elide: Text.ElideRight }
                        }
                        MouseArea {
                            id: qMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.p >= 0) page.ctl.page = modelData.p
                                else Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-wallpaper\""])
                            }
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