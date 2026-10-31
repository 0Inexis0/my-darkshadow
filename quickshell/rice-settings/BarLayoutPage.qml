import Quickshell
import QtQuick

// Settings > Bar layout: drag Waybar modules between left, center and right, reorder them,
// hide them, and order the small icons inside "System icons".
Item {
    id: page
    property var ctl

    readonly property var info: ({
        "image#nix": ["", "Launcher"], "custom/distro": ["", "Launcher"],
        "group/ws": ["", "Workspaces"], "mpris": ["", "Music"],
        "wireplumber": ["", "Volume"], "clock": ["", "Clock"],
        "group/apps": ["", "System icons"], "custom/notification": ["", "Notifications"],
        "custom/lock": ["", "Power"], "battery": ["", "Battery"],
        "bluetooth": ["", "Bluetooth"], "tray": ["", "Tray"], "network": ["", "Network"]
    })
    readonly property var subsAll: ["bluetooth", "tray", "network"]
    readonly property var defaults: ({
        left: ["image#nix", "group/ws", "mpris"], center: [],
        right: ["wireplumber", "clock", "group/apps", "custom/notification", "custom/lock"]
    })

    // local copy so drops show at once; refreshed from Settings state when not dragging
    property var lay: ({ left: [], center: [], right: [], available: [] })
    property var apps: []
    function pull() {
        if (dragName !== "") return
        const st = page.ctl ? page.ctl.st : null
        if (st && st.layout) lay = JSON.parse(JSON.stringify(st.layout))
        if (st && st.apps) apps = st.apps.slice()
    }
    Connections { target: page.ctl; function onStChanged() { page.pull() } }
    Component.onCompleted: pull()

    function chip(n) {
        let i = info[n]
        if (n === "image#nix" || n === "custom/distro") i = [page.ctl ? page.ctl.osGlyph() : "", "Launcher"]
        if (!i) i = ["", n.replace(/^custom\//, "").replace(/^group\//, "")]
        return { name: n, icon: i[0], label: i[1] }
    }
    function chips(list) { return (list || []).map(chip) }
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
    readonly property var zonesSub: [zApps, zSubHidden]

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
            page.ctl.setSt("layout", n)
            page.ctl.run(["layout-set", JSON.stringify({ left: n.left, center: n.center, right: n.right })])
            page.ctl.status = to === "available" ? chip(name).label + " hidden" : chip(name).label + " moved"
        } else {
            let a = apps.filter(function(m) { return page.subsAll.indexOf(m) >= 0 })
            const at = a.indexOf(name)
            if (from === "apps" && to === "apps" && at >= 0 && at < idx) idx -= 1
            a = a.filter(function(m) { return m !== name })
            if (to === "apps") a.splice(Math.max(0, Math.min(idx, a.length)), 0, name)
            const extra = apps.filter(function(m) { return page.subsAll.indexOf(m) < 0 })
            apps = a.concat(extra)
            page.ctl.setSt("apps", apps)
            page.ctl.run(["apps-set", a.join(",")])
            page.ctl.status = chip(name).label + (to === "apps" ? " moved" : " hidden")
        }
    }

    Column {
        id: col
        x: 24
        width: parent.width - 48
        spacing: 10

        SectionTitle {
            text: "Bar layout"
            sub: "Drag a module to move it. Drop it between others to change the order, or into \"Not on the bar\" to hide it. Point at an icon to see its name."
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
                        width: (parent.width - 8) * 0.37; height: parent.height
                        items: page.chips(page.lay.left)
                        align: Qt.AlignLeft
                    }
                    LayoutZone {
                        id: zCenter
                        compact: true
                        zone: "center"; title: "CENTER"; page: page
                        width: (parent.width - 8) * 0.26; height: parent.height
                        items: page.chips(page.lay.center)
                        align: Qt.AlignHCenter
                    }
                    LayoutZone {
                        id: zRight
                        compact: true
                        zone: "right"; title: "RIGHT"; page: page
                        width: (parent.width - 8) * 0.37; height: parent.height
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

        SectionTitle { text: "System icons"; sub: "The small icons grouped together on the bar. Drag to change their order; drop one below to hide it." }
        LayoutZone {
            id: zApps
            zone: "apps"; kind: "sub"; page: page; wrap: true
            width: parent.width; height: 70
            color: hot ? Qt.rgba(1, 1, 1, 0.06) : "#141414"
            border.color: hot ? Qt.rgba(1, 1, 1, 0.35) : "#1f1f1f"
            items: page.chips(page.apps.filter(function(m) { return page.subsAll.indexOf(m) >= 0 }))
        }
        LayoutZone {
            id: zSubHidden
            zone: "subHidden"; kind: "sub"; page: page; wrap: true; title: "HIDDEN"
            width: parent.width; height: 70
            color: hot ? Qt.rgba(1, 1, 1, 0.06) : "#121212"
            border.color: hot ? Qt.rgba(1, 1, 1, 0.35) : "#1f1f1f"
            items: page.chips(page.subHidden)
        }

        Row {
            spacing: 10
            topPadding: 6
            Btn {
                text: "Default layout"
                icon: ""
                onClicked: {
                    const n = { left: page.defaults.left.slice(), center: [], right: page.defaults.right.slice(), available: [] }
                    const all = ["image#nix", "custom/distro", "group/ws", "mpris", "wireplumber", "clock", "group/apps", "custom/notification", "custom/lock", "battery"]
                    const placed = n.left.concat(n.right)
                    n.available = (page.lay.left.concat(page.lay.center, page.lay.right, page.lay.available))
                        .filter(function(m) { return placed.indexOf(m) < 0 && all.indexOf(m) >= 0 })
                    page.lay = n
                    page.ctl.setSt("layout", n)
                    page.ctl.run(["layout-set", JSON.stringify({ left: n.left, center: n.center, right: n.right })])
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
