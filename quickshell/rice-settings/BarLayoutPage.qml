import Quickshell
import Quickshell.Io
import QtQuick

// Settings > Bar layout: drag the modules of the DarkShadow bar between left, center and right,
// reorder them, or hide them.
Item {
    id: page
    property var ctl

    readonly property var info: ({
        "launcher": ["\udb80\udc3b", "Launcher"], "workspaces": ["\udb80\uddd8", "Workspaces"], "title": ["\udb81\uddb2", "Window title"],
        "media": ["\udb81\udf5a", "Music"], "clock": ["\udb80\udd50", "Clock"], "tray": ["\udb81\udd70", "Tray"],
        "volume": ["\udb81\udd7e", "Volume"], "network": ["\udb81\udda9", "Wi-Fi"], "bluetooth": ["\udb80\udcaf", "Bluetooth"],
        "battery": ["\udb80\udc79", "Battery"], "notifications": ["\udb80\udc9a", "Notifications"], "power": ["\udb81\udc25", "Power"]
    })
    readonly property var subsAll: []
    readonly property var defaults: ({
        left: ["launcher", "workspaces", "title"], center: ["clock"],
        right: ["media", "tray", "volume", "bluetooth", "network", "battery", "notifications", "power"]
    })

    // the bar's settings (rice-bar)
    property var qb: ({})
    function qrun(args) {
        Quickshell.execDetached(["bash", "-c", "\"$HOME/.local/bin/rice-bar\" \"$@\"", "_"].concat(args.map(function(a) { return String(a) })))
    }
    Process {
        id: qproc
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-bar\" state 2>/dev/null"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { page.qb = JSON.parse(text); page.pull() } catch (e) { } } }
    }

    // local copy so drops show at once; refreshed from Settings state when not dragging
    property var lay: ({ left: [], center: [], right: [], available: [] })
    property var apps: []
    function pull() {
        if (dragName !== "") return
        if (qb.layout) lay = JSON.parse(JSON.stringify(qb.layout))
    }
    Component.onCompleted: pull()

    function chip(n) {
        let i = info[n]
        if (!i) i = ["•", n]
        return { name: n, icon: i[0], label: i[1] }
    }
    function chips(list) { return (list || []).map(chip) }
    // room a zone needs for its icons, so nothing wraps onto a second line
    function need(list) { const n = (list || []).length; return n * 42 + 24 }
    readonly property var subHidden: subsAll.filter(function(s) { return apps.indexOf(s) < 0 })

    // ---------------- drag and drop ----------------
    property string dragName: ""
    property string dragKind: ""
    property string dragFrom: ""
    property string overZone: ""
    property int overIndex: -1
    property real gx: 0
    property real gy: 0
    property real offX: 0
    property real offY: 0
    readonly property var zonesMod: [zLeft, zCenter, zRight, zHidden]
    readonly property var zonesSub: []

    function startDrag(c, x, y, ox, oy) {
        dragName = c.name; dragKind = c.kind; dragFrom = c.zone
        ghost.icon = c.icon; ghost.label = c.label
        offX = ox; offY = oy
        moveDrag(x, y)
    }
    function moveDrag(x, y) {
        gx = x; gy = y
        const zs = dragKind === "sub" ? zonesSub : zonesMod
        let hit = null
        for (let i = 0; i < zs.length; i++) {
            const p = zs[i].mapFromItem(page, x, y)
            if (p.x >= 0 && p.y >= 0 && p.x <= zs[i].width && p.y <= zs[i].height) { hit = zs[i]; break }
        }
        if (hit) {
            const p = hit.mapFromItem(page, x, y)
            overZone = hit.zone
            overIndex = hit.indexAt(p.x, p.y)
        } else { overZone = ""; overIndex = -1 }
    }
    function cancelDrag() { dragName = ""; dragKind = ""; overZone = ""; overIndex = -1 }
    function endDrag(x, y) {
        moveDrag(x, y)
        const name = dragName, kind = dragKind, from = dragFrom, to = overZone
        let idx = overIndex
        cancelDrag()
        if (to === "") return
        if (kind === "mod") {
            const n = JSON.parse(JSON.stringify(lay))
            const src = n[from] || []
            const at = src.indexOf(name)
            if (from === to && at >= 0 && at < idx) idx -= 1   // same list: the gap closes first
            for (const z of ["left", "center", "right", "available"]) n[z] = (n[z] || []).filter(function(m) { return m !== name })
            n[to].splice(Math.max(0, Math.min(idx, n[to].length)), 0, name)
            lay = n
            page.qrun(["layout-set", JSON.stringify({ left: n.left, center: n.center, right: n.right })])
            page.ctl.status = to === "available" ? chip(name).label + " hidden" : chip(name).label + " moved"
        }
    }

    Column {
        id: col
        x: 24
        width: parent.width - 48
        spacing: 10

        SectionTitle {
            text: "Bar layout"
            sub: "Drag a module to move it. Drop it between others to change the order, or into \"Not on the bar\" to hide it. "
        }

        // ---------- the bar ----------
        Rectangle {
            width: parent.width
            height: 128
            radius: 16
            border.width: 1
            border.color: "#1f1f1f"
            gradient: Gradient {
                GradientStop { position: 0; color: "#2a2740" }
                GradientStop { position: 1; color: "#12131a" }
            }
            Rectangle {
                id: barBg
                x: 10; y: 12
                width: parent.width - 20
                height: 70
                radius: 14
                color: Qt.rgba(0.04, 0.04, 0.05, 0.92)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.07)
                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    LayoutZone {
                        id: zLeft
                        compact: true
                        zone: "left"; title: "LEFT"; page: page
                        width: Math.max(130, page.need(page.lay.left)); height: parent.height
                        items: page.chips(page.lay.left)
                        align: Qt.AlignLeft
                    }
                    LayoutZone {
                        id: zCenter
                        compact: true
                        zone: "center"; title: "CENTER"; page: page
                        width: Math.max(70, parent.width - 8 - zLeft.width - zRight.width); height: parent.height
                        items: page.chips(page.lay.center)
                        align: Qt.AlignHCenter
                    }
                    LayoutZone {
                        id: zRight
                        compact: true
                        zone: "right"; title: "RIGHT"; page: page
                        width: Math.max(130, page.need(page.lay.right)); height: parent.height
                        items: page.chips(page.lay.right)
                        align: Qt.AlignRight
                    }
                }
            }
            // names, in order, under each part of the bar
            Item {
                x: barBg.x + 4; y: barBg.y + barBg.height + 10
                width: barBg.width - 8; height: 16
                component Names: T {
                    property var list: []
                    text: list.map(function(m) { return page.chip(m).label }).join("  ·  ")
                    font.pixelSize: 10
                    color: "#7a7a84"
                    elide: Text.ElideRight
                }
                Names { list: page.lay.left || []; x: 0; width: zLeft.width; horizontalAlignment: Text.AlignLeft; leftPadding: 10 }
                Names { list: page.lay.center || []; x: zLeft.width + 4; width: zCenter.width; horizontalAlignment: Text.AlignHCenter }
                Names { list: page.lay.right || []; x: zLeft.width + zCenter.width + 8; width: zRight.width; horizontalAlignment: Text.AlignRight; rightPadding: 10 }
            }
        }

        SectionTitle { text: "Not on the bar"; sub: "Drag one up to add it." }
        LayoutZone {
            id: zHidden
            zone: "available"; page: page; wrap: true
            width: parent.width; height: 70
            color: hot ? Qt.rgba(1, 1, 1, 0.06) : "#121212"
            border.color: hot ? Qt.rgba(1, 1, 1, 0.35) : "#1f1f1f"
            items: page.chips(page.lay.available)
        }

        Row {
            spacing: 10
            topPadding: 6
            Btn {
                text: "Default layout"
                icon: ""
                onClicked: {
                    const n = { left: page.defaults.left.slice(), center: page.defaults.center.slice(), right: page.defaults.right.slice(), available: [] }
                    page.lay = n
                    page.qrun(["layout-reset"])
                    page.ctl.status = "Default layout"
                }
            }
        }
    }

    // floating copy under the pointer while dragging
    Rectangle {
        id: ghost
        property string icon: ""
        property string label: ""
        visible: page.dragName !== ""
        x: page.gx - page.offX
        y: page.gy - page.offY
        z: 100
        height: 36
        width: grow.implicitWidth + 26
        radius: 11
        color: "#F6F5F4"
        scale: 1.06
        Row {
            id: grow
            anchors.centerIn: parent
            spacing: 8
            T { kind: "icon"; text: ghost.icon; font.pixelSize: 14; color: "#0d0d0d"; anchors.verticalCenter: parent.verticalCenter }
            T { text: ghost.label; font.pixelSize: 12; font.bold: true; color: "#0d0d0d"; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
