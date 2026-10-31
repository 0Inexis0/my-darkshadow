import QtQuick

// Performance tab: CPU, GPU, storage, network, memory and battery (rice-dashboard stats). Cards can be edited.
Item {
    id: pf
    property var d
    property bool live: false
    readonly property var p: d.p
    readonly property var s: d.stats || ({})
    property int diskIdx: 0
    property var rxHist: []
    property var txHist: []
    signal tick()
    Connections {
        target: pf.d
        function onStatsChanged() {
            if (!pf.d.stats.net) return
            const r = pf.rxHist.slice(-59), t = pf.txHist.slice(-59)
            r.push(pf.d.stats.net.rx); t.push(pf.d.stats.net.tx)
            pf.rxHist = r; pf.txHist = t
            pf.tick()
        }
    }
    function gib(b) { return (b / 1073741824).toFixed(1) }
    function rate(b) {
        if (b < 1024) return b.toFixed(1) + " B/s"
        if (b < 1048576) return (b / 1024).toFixed(1) + " KB/s"
        return (b / 1048576).toFixed(1) + " MB/s"
    }
    function size(b) {
        if (b < 1048576) return (b / 1024).toFixed(0) + "KB"
        if (b < 1073741824) return (b / 1048576).toFixed(1) + "MB"
        return (b / 1073741824).toFixed(2) + "GB"
    }

    DashGrid {
        anchors.fill: parent
        d: pf.d
        tabId: "performance"
        rows: 2
        live: pf.live
        catalog: [
            { id: "cpu", name: "CPU", sizes: [[5, 1], [4, 1], [6, 1]] },
            { id: "gpu", name: "GPU", sizes: [[5, 1], [4, 1], [6, 1]] },
            { id: "battery", name: "Battery", sizes: [[2, 2], [2, 1], [3, 1]] },
            { id: "storage", name: "Storage", sizes: [[4, 1], [3, 1], [5, 1]] },
            { id: "network", name: "Network", sizes: [[4, 1], [3, 1], [6, 1]] },
            { id: "memory", name: "Memory", sizes: [[2, 1], [3, 1]] }
        ]
        defaults: [
            { id: "cpu", w: 5, h: 1 }, { id: "gpu", w: 5, h: 1 }, { id: "battery", w: 2, h: 2 },
            { id: "storage", w: 4, h: 1 }, { id: "network", w: 4, h: 1 }, { id: "memory", w: 2, h: 1 }
        ]
        comps: ({ cpu: cpuC, gpu: gpuC, battery: batC, storage: diskC, network: netC, memory: memC })
    }

    // ---------- CPU / GPU ----------
    component Chipset: DCard {
        id: cc
        property string kind: "cpu"
        property string title: "CPU"
        property string icon: "memory"
        property int glyph: 0xF061A
        p: pf.p
        readonly property var v: pf.s[kind] || ({})
        readonly property int use: v.usage !== undefined && v.usage !== null ? v.usage : -1
        readonly property real bs: Math.min(height - 40, width * 0.3, 104)
        Item {
            id: ico
            x: 16; y: 16; width: 42; height: 42
            DRing { anchors.fill: parent; p: pf.p; value: cc.use > 0 ? cc.use : 0; line: 3; gapped: false }
            MIcon { anchors.centerIn: parent; name: cc.icon; glyph: pf.d.md(cc.glyph); size: 20; color: pf.p.text }
        }
        Column {
            anchors.left: ico.right; anchors.leftMargin: 12
            anchors.right: blob.left; anchors.rightMargin: 10
            y: 16
            spacing: 2
            DText { text: cc.title; font.pixelSize: 18; font.weight: Font.DemiBold; color: pf.p.primary }
            DText { width: parent.width; elide: Text.ElideRight; text: cc.v.name || "..."; font.pixelSize: 12; color: pf.p.text }
        }
        Row {
            x: 18; y: parent.height - 56
            spacing: 6
            MIcon { name: "thermostat"; glyph: pf.d.md(0xF050F); size: 16; color: pf.p.sub }
            DText { text: cc.v.temp !== undefined && cc.v.temp !== null ? cc.v.temp + "°C" : "--"; font.pixelSize: 14; color: pf.p.text; anchors.verticalCenter: parent.verticalCenter }
            DText { visible: cc.kind === "gpu" && !!cc.v.mem_total; text: "·  " + ((cc.v.mem_used || 0) / 1024).toFixed(1) + " / " + ((cc.v.mem_total || 0) / 1024).toFixed(1) + " GiB"; font.pixelSize: 12; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
        }
        Item {
            x: 18; y: parent.height - 28
            width: blob.x - 34; height: 6
            Rectangle { anchors.fill: parent; radius: 3; color: pf.p.track }
            Rectangle {
                width: parent.width * Math.min(1, (cc.v.temp || 0) / 100); height: parent.height; radius: 3
                color: (cc.v.temp || 0) >= 85 ? "#e06c75" : pf.p.primary
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }
        }
        DText { anchors.horizontalCenter: blob.horizontalCenter; y: 12; text: "Usage"; font.pixelSize: 12; color: pf.p.sub }
        Cookie {
            id: blob
            anchors.right: parent.right; anchors.rightMargin: 16
            y: 32 + (parent.height - 32 - height) / 2 - 6
            width: cc.bs; height: cc.bs
            fill: pf.p.container
            DText { anchors.centerIn: parent; text: cc.use >= 0 ? cc.use + "%" : "--"; font.pixelSize: cc.bs * 0.27; font.weight: Font.DemiBold; color: pf.p.onContainer }
        }
    }
    Component { id: cpuC; Chipset { kind: "cpu"; title: "CPU"; icon: "memory"; glyph: 0xF061A } }
    Component { id: gpuC; Chipset { kind: "gpu"; title: "GPU"; icon: "monitor"; glyph: 0xF08AE } }

    // ---------- storage ----------
    Component {
        id: diskC
        DCard {
            id: st
            p: pf.p
            readonly property var list: pf.s.disks || pf.d.disks || []
            readonly property var dk: list.length > 0 ? list[Math.min(pf.diskIdx, list.length - 1)] : null
            readonly property real rs: Math.min(height - 36, 116)
            Item {
                id: sr
                x: 16; anchors.verticalCenter: parent.verticalCenter
                width: st.rs; height: st.rs
                DRing { anchors.fill: parent; p: pf.p; value: st.dk ? st.dk.pct : 0; line: 8 }
                Column {
                    anchors.centerIn: parent
                    MIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "hard_drive"; glyph: pf.d.md(0xF02CA); size: 16; color: pf.p.sub }
                    DText { anchors.horizontalCenter: parent.horizontalCenter; text: st.dk ? st.dk.pct + "%" : "--"; font.pixelSize: st.rs * 0.2; font.weight: Font.DemiBold; color: pf.p.text }
                    DText { anchors.horizontalCenter: parent.horizontalCenter; text: "Used"; font.pixelSize: 11; color: pf.p.sub }
                }
            }
            Column {
                anchors.left: sr.right; anchors.leftMargin: 16
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                DText { text: "Storage"; font.pixelSize: 17; font.weight: Font.DemiBold; color: pf.p.text }
                DText { width: parent.width; elide: Text.ElideRight; text: st.dk ? pf.gib(st.dk.used) + " / " + pf.gib(st.dk.total) + " GiB" : "--"; font.pixelSize: 13; color: pf.p.sub }
                Item { width: 1; height: 6 }
                Rectangle {
                    width: Math.min(parent.width, dl.implicitWidth + 34); height: 32; radius: 16
                    color: dm.containsMouse ? pf.p.card2 : pf.p.container
                    Row {
                        id: dl
                        anchors.centerIn: parent
                        spacing: 6
                        MIcon { name: "storage"; glyph: pf.d.md(0xF02CA); size: 15; color: pf.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                        DText { text: st.dk ? st.dk.dev : "disk"; font.pixelSize: 12; color: pf.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                        MIcon { visible: st.list.length > 1; name: "expand_more"; glyph: pf.d.md(0xF0140); size: 15; color: pf.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: pf.diskIdx = st.list.length > 0 ? (pf.diskIdx + 1) % st.list.length : 0 }
                }
            }
        }
    }

    // ---------- network ----------
    Component {
        id: netC
        DCard {
            id: nt
            p: pf.p
            Connections { target: pf; function onTick() { graph.requestPaint() } }
            Row {
                x: 16; y: 12
                spacing: 8
                MIcon { name: "swap_vert"; glyph: pf.d.md(0xF04E1); size: 18; color: pf.p.primary; anchors.verticalCenter: parent.verticalCenter }
                DText { text: "Network"; font.pixelSize: 17; font.weight: Font.DemiBold; color: pf.p.text }
                DText { text: pf.s.net ? pf.s.net.iface : ""; font.pixelSize: 10; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
            }
            Canvas {
                id: graph
                x: 16; y: 40
                width: parent.width - 32; height: Math.max(10, parent.height - 40 - 64)
                onWidthChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d")
                    c.reset()
                    const W = width, H = height
                    const all = pf.rxHist.concat(pf.txHist)
                    const mx = Math.max(1024, Math.max.apply(null, all.length ? all : [1]))
                    function line(arr, col, fillA) {
                        if (arr.length < 2) return
                        c.beginPath()
                        for (let i = 0; i < arr.length; i++) {
                            const x = W - (arr.length - 1 - i) * (W / 59), y = H - (arr[i] / mx) * (H - 4)
                            if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
                        }
                        c.strokeStyle = col; c.lineWidth = 1.6; c.stroke()
                        c.lineTo(W, H); c.lineTo(W - (arr.length - 1) * (W / 59), H); c.closePath()
                        c.globalAlpha = fillA; c.fillStyle = col; c.fill(); c.globalAlpha = 1
                    }
                    c.strokeStyle = pf.p.track; c.lineWidth = 1
                    c.beginPath(); c.moveTo(0, H - 0.5); c.lineTo(W, H - 0.5); c.stroke()
                    line(pf.txHist, pf.p.sub, 0.12)
                    line(pf.rxHist, pf.p.primary, 0.25)
                }
            }
            Column {
                x: 16; width: parent.width - 32
                y: parent.height - 62
                spacing: 2
                Repeater {
                    model: [
                        { n: "download", g: 0xF01DA, t: "Download", v: pf.s.net ? pf.rate(pf.s.net.rx) : "--" },
                        { n: "upload", g: 0xF0552, t: "Upload", v: pf.s.net ? pf.rate(pf.s.net.tx) : "--" },
                        { n: "history", g: 0xF051B, t: "Total", v: pf.s.net ? "↓" + pf.size(pf.s.net.rx_total) + "  ↑" + pf.size(pf.s.net.tx_total) : "--" }
                    ]
                    Item {
                        width: parent.width; height: 19
                        MIcon { name: modelData.n; glyph: pf.d.md(modelData.g); size: 15; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
                        DText { x: 22; text: modelData.t; font.pixelSize: 12; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
                        DText { anchors.right: parent.right; text: modelData.v; font.pixelSize: 12; font.weight: Font.DemiBold; color: pf.p.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }

    // ---------- memory ----------
    Component {
        id: memC
        DCard {
            id: mem
            p: pf.p
            readonly property real rs: Math.min(height - 70, width - 40, 96)
            Row {
                x: 16; y: 12
                spacing: 8
                MIcon { name: "memory_alt"; glyph: pf.d.md(0xF035B); size: 18; color: pf.p.primary; anchors.verticalCenter: parent.verticalCenter }
                DText { text: "Memory"; font.pixelSize: 17; font.weight: Font.DemiBold; color: pf.p.text }
            }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 40; width: mem.rs; height: mem.rs
                DRing { anchors.fill: parent; p: pf.p; value: pf.s.mem ? pf.s.mem.pct : 0; line: 7 }
                Column {
                    anchors.centerIn: parent
                    DText { anchors.horizontalCenter: parent.horizontalCenter; text: pf.s.mem ? pf.s.mem.pct + "%" : "--"; font.pixelSize: mem.rs * 0.22; font.weight: Font.DemiBold; color: pf.p.text }
                    DText { anchors.horizontalCenter: parent.horizontalCenter; text: "Used"; font.pixelSize: 10; color: pf.p.sub }
                }
            }
            DText { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 24; text: pf.s.mem ? pf.gib(pf.s.mem.used) + " / " + pf.gib(pf.s.mem.total) + " GiB" : ""; font.pixelSize: 12; color: pf.p.text }
        }
    }

    // ---------- battery ----------
    Component {
        id: batC
        DCard {
            id: bat
            p: pf.p
            readonly property var b: pf.s.battery || ({})
            readonly property var mb: b.main || null
            readonly property bool charging: !!mb && (mb.status === "Charging" || mb.status === "Full")
            clip: true
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: bat.mb ? Math.max(pf.p.cardRadius * 2, (parent.height - 70) * bat.mb.pct / 100 + pf.p.cardRadius) : 0
                radius: pf.p.cardRadius
                color: bat.mb && bat.mb.pct <= 15 && !bat.charging ? "#c0545e" : pf.p.primary
                opacity: 0.92
                Behavior on height { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
            }
            Column {
                x: 16; y: 14
                spacing: 2
                MIcon { name: bat.mb ? (bat.charging ? "battery_charging_full" : "battery_full") : "power"; glyph: bat.mb ? (bat.charging ? pf.d.md(0xF0241) : pf.d.md(0xF0079)) : pf.d.md(0xF06A5); size: 26; color: pf.p.primary }
                DText { text: bat.mb ? "Battery" : "Power"; font.pixelSize: 16; font.weight: Font.DemiBold; color: pf.p.text }
            }
            Column {
                visible: !bat.mb
                x: 16; y: 80; width: parent.width - 32
                spacing: 8
                DText { width: parent.width; wrapMode: Text.WordWrap; visible: !(bat.b.devices || []).length; text: "Plugged in. No battery in this computer."; font.pixelSize: 11; color: pf.p.sub }
                Repeater {
                    model: (bat.b.devices || []).slice(0, 3)
                    Column {
                        width: parent.width
                        spacing: 3
                        DText { width: parent.width; elide: Text.ElideRight; text: modelData.name + "  " + modelData.pct + "%"; font.pixelSize: 11; color: pf.p.text }
                        Rectangle { width: parent.width; height: 5; radius: 2.5; color: pf.p.track
                            Rectangle { width: parent.width * modelData.pct / 100; height: 5; radius: 2.5; color: pf.p.primary } }
                    }
                }
            }
            Column {
                visible: !!bat.mb
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.bottom: parent.bottom; anchors.bottomMargin: 12
                DText { anchors.right: parent.right; text: bat.mb ? (bat.mb.status === "Full" ? "Full" : bat.charging ? "Charging" : "On battery") : ""; font.pixelSize: 12; color: pf.p.onPrimary }
                Row {
                    anchors.right: parent.right
                    spacing: 2
                    MIcon { visible: bat.charging; name: "bolt"; glyph: pf.d.md(0xF0241); size: 26; color: pf.p.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                    DText { text: bat.mb ? bat.mb.pct + "%" : ""; font.pixelSize: Math.min(36, bat.width * 0.24); font.weight: Font.DemiBold; color: pf.p.onPrimary }
                }
            }
        }
    }

    // wavy "cookie" shape (Material 3 expressive)
    component Cookie: Canvas {
        id: ck
        property color fill: "#333"
        property int bumps: 9
        onFillChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const c = getContext("2d")
            c.reset()
            const cx = width / 2, cy = height / 2, R = Math.min(width, height) / 2 - 2
            c.beginPath()
            for (let i = 0; i <= 180; i++) {
                const a = i / 180 * Math.PI * 2
                const r = R * (0.9 + 0.1 * Math.cos(a * ck.bumps))
                const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a)
                if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
            c.closePath()
            c.fillStyle = ck.fill
            c.fill()
        }
    }
}
