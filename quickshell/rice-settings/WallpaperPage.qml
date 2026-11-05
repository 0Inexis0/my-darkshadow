import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Wallpaper: the wallpaper you have, the colors it gives the shell, and all your wallpapers to pick from.
Item {
    id: page
    property var ctl
    property var w: ({ dir: "", current: "", walls: [] })
    Process {
        id: wallsProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" walls 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.w = JSON.parse(text) } catch (e) { } } }
    }
    Timer { id: again; interval: 2500; onTriggered: wallsProc.running = true }
    onVisibleChanged: if (visible) wallsProc.running = true
    function setWall(p) {
        const n = Object.assign({}, w); n.current = p; w = n
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-dashboard\" wall \"$1\"", "_", p])
        page.ctl.status = "Wallpaper set, colors follow in a moment"
        again.restart()
    }
    function randomWall() { const l = w.walls || []; if (l.length) setWall(l[Math.floor(Math.random() * l.length)].path) }
    function themeName() {
        const l = page.ctl ? page.ctl.schemes || [] : []
        for (let i = 0; i < l.length; i++) if (l[i].key === page.ctl.colorMode) return l[i].name
        return page.ctl ? page.ctl.colorMode : ""
    }

    PageScroll {
        anchors.fill: parent

        // ---------- what you have now ----------
        Rectangle {
            id: now
            width: parent.width
            height: Math.max(230, Math.min(300, width * 0.32))
            radius: M3.rXL
            color: M3.surfaceC
            Rectangle {
                id: frame
                x: 12; y: 12
                width: Math.min(parent.width * 0.56, (parent.height - 24) * 16 / 9)
                height: parent.height - 24
                radius: M3.rL
                color: M3.surfaceHigh
                RoundImage {
                    anchors.fill: parent
                    cornerRadius: M3.rL
                    fallback: ""
                    res: 1280
                    source: page.w.current ? "file://" + page.w.current : ""
                }
                Rectangle {
                    anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 10
                    width: nt.implicitWidth + 20; height: 26; radius: 13
                    color: Qt.rgba(0, 0, 0, 0.55)
                    visible: page.w.current !== ""
                    T { id: nt; anchors.centerIn: parent; text: (page.w.current || "").split("/").pop(); font.pixelSize: 11; color: "#ffffff"
                        width: Math.min(implicitWidth, frame.width - 40); elide: Text.ElideMiddle }
                }
            }
            Column {
                x: frame.x + frame.width + 20
                y: 18
                width: parent.width - x - 18
                spacing: 10
                T { text: I18n.t("COLORS FROM YOUR WALLPAPER"); font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.1; color: M3.primary }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: [M3.primary, M3.tertiary, M3.primaryContainer, M3.secondaryContainer, M3.surfaceHighest, M3.surfaceHigh, M3.surfaceC, M3.inkPrimaryC]
                        delegate: Rectangle { width: 30; height: 30; radius: 15; color: modelData; border.width: 1; border.color: M3.alpha("#ffffff", 0.08) }
                    }
                }
                Rectangle {
                    width: tn.implicitWidth + 26; height: 30; radius: 15; color: M3.secondaryContainer
                    T { id: tn; anchors.centerIn: parent; text: "Theme · " + page.themeName(); font.pixelSize: 12; color: M3.inkSecondaryC }
                }
                Flow {
                    width: parent.width
                    spacing: 8
                    Btn { text: I18n.t("Surprise me"); sym: "shuffle"; icon: ""; primary: true; onClicked: page.randomWall() }
                    Btn { text: "Theme"; sym: "palette"; icon: ""; onClicked: page.ctl.page = 8 }
                    Btn { text: "Folder"; sym: "folder_open"; icon: ""; onClicked: if (page.w.dir) Quickshell.execDetached(["xdg-open", page.w.dir]) }
                }
            }
        }

        // ---------- all wallpapers ----------
        SectionTitle {
            text: I18n.t("Your wallpapers")
            sub: page.w.dir ? (page.w.walls.length + " in " + page.w.dir.replace(Quickshell.env("HOME"), "~") + ". Click one to use it.") : "No wallpaper folder found (~/Pictures/Wallpapers)."
        }
        Grid {
            id: grid
            width: parent.width
            columns: width > 760 ? 4 : 3
            spacing: 10
            Repeater {
                model: page.w.walls || []
                delegate: Item {
                    id: wt
                    readonly property bool on: page.w.current === modelData.path
                    width: (grid.width - (grid.columns - 1) * 10) / grid.columns
                    height: width * 0.62
                    Rectangle {
                        anchors.fill: parent
                        radius: wm.pressed ? M3.rS : M3.rL
                        color: M3.surfaceHigh
                        border.width: wt.on ? 3 : 0
                        border.color: M3.primary
                        Behavior on radius { NumberAnimation { duration: M3.d(180) } }
                    }
                    RoundImage {
                        anchors.fill: parent
                        anchors.margins: wt.on ? 6 : 0
                        cornerRadius: wt.on ? M3.rM : M3.rL
                        res: 480
                        source: "file://" + (modelData.thumb || modelData.path)
                        scale: wm.containsMouse && !wt.on ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: M3.d(220); easing.type: Easing.OutCubic } }
                        Behavior on anchors.margins { NumberAnimation { duration: M3.d(220); easing.type: M3.springy; easing.overshoot: 1.6 * Prefs.bounce } }
                    }
                    Rectangle {
                        visible: wt.on
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
                        width: 26; height: 26; radius: 13; color: M3.primary
                        Icon { anchors.centerIn: parent; name: "check"; glyph: ""; size: 15; color: M3.inkPrimary }
                    }
                    MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.setWall(modelData.path) }
                }
            }
        }
    }
}
