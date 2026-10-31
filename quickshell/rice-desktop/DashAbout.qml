import Quickshell
import Quickshell.Io
import QtQuick

// About tab: this computer on the left, your distro in the middle, DarkShadow's Shell on the right.
Item {
    id: ab
    property var d
    property bool live: false
    readonly property var p: d.p
    readonly property var a: d.about || ({})
    readonly property var di: a.distro || ({})
    property var up: ({ installed: "", latest: "", update: false, news: [], changes: 0 })
    property bool checking: false

    Process {
        id: upProc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-update\" check --json 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { ab.up = JSON.parse(text) } catch (e) { } ab.checking = false } }
    }
    Process {
        id: upCache
        command: ["bash", "-c", "cat \"$HOME/.cache/rice/update.json\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { ab.up = JSON.parse(text) } catch (e) { } } }
    }
    onLiveChanged: if (live) { upCache.running = true; checking = true; upProc.running = true; d.loadAbout() }

    function gib(b) { return (b / 1073741824).toFixed(1) + " GiB" }
    function open(u) { if (u) { Quickshell.execDetached(["xdg-open", u]); d.close() } }

    readonly property real gap: 12
    readonly property real midW: 250

    // ======== this computer ========
    DCard {
        id: sys
        p: ab.p; live: ab.live; order: 0
        width: (ab.width - ab.midW - 2 * ab.gap) / 2; height: ab.height
        Row {
            x: 18; y: 14
            spacing: 8
            T { kind: "icon"; text: ab.d.md(0xF0697); font.pixelSize: 16; color: ab.p.primary; anchors.verticalCenter: parent.verticalCenter }
            T { text: "This computer"; font.pixelSize: 16; font.bold: true; color: ab.p.text }
        }
        Column {
            x: 18; y: 46
            width: parent.width - 36
            spacing: 3
            Repeater {
                model: [
                    { g: 0xF0697, n: "Board", v: ab.a.board || ab.a.product || "Unknown" },
                    { g: 0xF0379, n: "Model", v: ab.a.product || "" },
                    { g: 0xF061A, n: "CPU", v: (ab.a.cpu || "") + (ab.a.cores ? "  (" + ab.a.cores + " threads)" : "") },
                    { g: 0xF08AE, n: "GPU", v: ab.a.gpu || "" },
                    { g: 0xF035B, n: "Memory", v: ab.a.memory ? ab.gib(ab.a.memory) : "" },
                    { g: 0xF02CA, n: "Disk", v: ab.a.disk ? ab.gib(ab.a.disk.used) + " / " + ab.gib(ab.a.disk.total) : "" },
                    { g: 0xF0EC0, n: "Kernel", v: ab.a.kernel ? ab.a.kernel + " " + (ab.a.arch || "") : "" },
                    { g: 0xF03D7, n: "Packages", v: ab.a.packages || "" },
                    { g: 0xF0379, n: "Display", v: ab.a.display || "" },
                    { g: 0xF051B, n: "Uptime", v: ab.d.uptimeText(ab.d.stats.uptime || ab.a.uptime || 0) }
                ].filter(function(r) { return r.v !== "" })
                Item {
                    width: parent.width; height: 25
                    T { kind: "icon"; text: ab.d.md(modelData.g); font.pixelSize: 13; color: ab.p.sub; anchors.verticalCenter: parent.verticalCenter }
                    T { x: 24; text: modelData.n; font.pixelSize: 12; color: ab.p.sub; anchors.verticalCenter: parent.verticalCenter }
                    T { x: 92; width: parent.width - 92; elide: Text.ElideRight; text: modelData.v; font.pixelSize: 12; color: ab.p.text; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ======== distro ========
    DCard {
        id: dist
        p: ab.p; live: ab.live; order: 1; strong: true
        x: sys.width + ab.gap
        width: ab.midW; height: ab.height
        Rectangle {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            y: 26
            width: 108; height: 108; radius: 34
            color: ab.p.container
            T { kind: "icon"; anchors.centerIn: parent; text: ab.d.distroGlyph(); font.pixelSize: 58; color: ab.p.onContainer }
            // slow breathing glow
            SequentialAnimation on scale {
                running: ab.live
                loops: Animation.Infinite
                NumberAnimation { to: 1.04; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
            }
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: logo.y + logo.height + 16
            width: parent.width - 30
            spacing: 2
            T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: ab.di.name || "Linux"; font.pixelSize: 21; font.bold: true; color: ab.p.text }
            T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: ab.di.version || ""; font.pixelSize: 11; color: ab.p.sub }
            T { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: (ab.a.user || "") + (ab.a.host ? "@" + ab.a.host : ""); font.pixelSize: 11; color: ab.p.sub; topPadding: 4 }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 52
            spacing: 8
            Btn { icon: ab.d.md(0xF059F); text: "Website"; primary: true; onClicked: ab.open(ab.di.url) }
            Btn { visible: !!ab.di.docs; icon: ab.d.md(0xF02FD); text: "Docs"; onClicked: ab.open(ab.di.docs) }
        }
    }

    // ======== DarkShadow's Shell ========
    DCard {
        id: rice
        p: ab.p; live: ab.live; order: 2
        x: dist.x + dist.width + ab.gap
        width: sys.width; height: ab.height
        Image {
            id: moon
            x: 18; y: 18
            width: 56; height: 56
            source: "file://" + Quickshell.env("HOME") + "/.local/share/rice/icon.png"
            sourceSize.width: 112; sourceSize.height: 112
            smooth: true
        }
        Column {
            anchors.left: moon.right; anchors.leftMargin: 14
            anchors.right: parent.right; anchors.rightMargin: 16
            y: 22
            spacing: 4
            T { text: "DarkShadow's Shell"; font.pixelSize: 16; font.bold: true; color: ab.p.text }
            Row {
                spacing: 6
                Rectangle {
                    width: vt.implicitWidth + 14; height: 20; radius: 10
                    color: ab.p.container
                    T { id: vt; anchors.centerIn: parent; text: "V" + (ab.up.installed || ab.a.rice || "?"); font.pixelSize: 10; font.bold: true; color: ab.p.onContainer }
                }
                Rectangle { width: 7; height: 7; radius: 3.5; anchors.verticalCenter: parent.verticalCenter
                    color: ab.checking ? ab.p.sub : (ab.up.update ? ab.p.primary : "#7bd88f") }
                T {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ab.checking ? "Checking..." : (ab.up.update ? "V" + ab.up.latest + " is available" : "Up to date")
                    font.pixelSize: 11; color: ab.up.update ? ab.p.primary : ab.p.sub
                }
            }
        }
        Column {
            x: 18; y: 92
            width: parent.width - 36
            spacing: 5
            T { text: ab.up.update ? "WHAT'S NEW" : "QUICKSHELL  ·  HYPRLAND  ·  WAYBAR"; font.pixelSize: 9; font.letterSpacing: 1.2; color: ab.p.sub }
            Repeater {
                model: ab.up.update ? (ab.up.news || []).slice(0, 4) : [ab.a.wm || "Hyprland", ab.a.quickshell || "Quickshell", "Shell: " + (ab.a.shell || "fish")]
                Row {
                    spacing: 8
                    width: parent.width
                    Rectangle { width: 4; height: 4; radius: 2; color: ab.p.primary; anchors.verticalCenter: parent.verticalCenter }
                    T { width: parent.width - 12; elide: Text.ElideRight; text: modelData; font.pixelSize: 11; color: ab.p.text }
                }
            }
        }
        Row {
            x: 18; y: parent.height - 52
            spacing: 8
            Btn {
                primary: ab.up.update === true
                icon: ab.up.update ? ab.d.md(0xF06B0) : ab.d.md(0xF0450)
                text: ab.up.update ? "Update now" : (ab.checking ? "Checking..." : "Check again")
                onClicked: {
                    if (ab.up.update) {
                        Quickshell.execDetached(["bash", "-c", "t=\"${TERMINAL:-kitty}\"; command -v \"$t\" >/dev/null || t=kitty; exec \"$t\" -e \"$HOME/.local/bin/rice-update\""])
                        ab.d.close()
                    } else if (!ab.checking) { ab.checking = true; upProc.running = true }
                }
            }
            Btn { icon: ab.d.md(0xF02A4); text: "GitHub"; onClicked: ab.open("https://github.com/shadowww-dev/shadows-shell") }
        }
    }

    component Btn: Rectangle {
        id: bb
        property string icon: ""
        property string text: ""
        property bool primary: false
        signal clicked()
        height: 36
        width: br.implicitWidth + 28
        radius: 18
        color: primary ? (bm.containsMouse ? Qt.lighter(ab.p.primary, 1.08) : ab.p.primary) : (bm.containsMouse ? ab.p.card2 : ab.p.container)
        Behavior on color { ColorAnimation { duration: 120 } }
        scale: bm.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Row {
            id: br
            anchors.centerIn: parent
            spacing: 6
            T { kind: "icon"; text: bb.icon; font.pixelSize: 14; color: bb.primary ? ab.p.onPrimary : ab.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
            T { text: bb.text; font.pixelSize: 12; font.bold: bb.primary; color: bb.primary ? ab.p.onPrimary : ab.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bb.clicked() }
    }
}
