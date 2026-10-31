import QtQuick

// Performance tab: CPU, GPU, storage, network, memory and battery (rice-dashboard stats).
Item {
    id: pf
    property var d
    property bool live: false
    readonly property var p: d.p
    readonly property var s: d.stats || ({})
    property int diskIdx: 0
    property var rxHist: []
    property var txHist: []
    Connections {
        target: pf.d
        function onStatsChanged() {
            if (!pf.d.stats.net) return
            const r = pf.rxHist.slice(-59), t = pf.txHist.slice(-59)
            r.push(pf.d.stats.net.rx); t.push(pf.d.stats.net.tx)
            pf.rxHist = r; pf.txHist = t
            graph.requestPaint()
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

    readonly property real gap: 12
    readonly property real batW: 170
    readonly property real leftW: width - batW - gap
    readonly property real row1: 158

    // ======== CPU and GPU ========
    Repeater {
        model: [
            { k: "cpu", t: "CPU", g: 0xF061A },
            { k: "gpu", t: "GPU", g: 0xF08AE }
        ]
        DCard {
            id: cc
            p: pf.p; live: pf.live; order: index
            readonly property var v: pf.s[modelData.k] || ({})
            readonly property int use: v.usage !== undefined && v.usage !== null ? v.usage : -1
            x: index * ((pf.leftW - pf.gap) / 2 + pf.gap); y: 0
            width: (pf.leftW - pf.gap) / 2; height: pf.row1
            Item {
                id: ico
                x: 16; y: 16; width: 42; height: 42
                DRing { anchors.fill: parent; p: pf.p; value: cc.use > 0 ? cc.use : 0; line: 3; gapped: false }
                T { kind: "icon"; anchors.centerIn: parent; text: pf.d.md(modelData.g); font.pixelSize: 17; color: pf.p.text }
            }
            Column {
                anchors.left: ico.right; anchors.leftMargin: 12
                anchors.right: blob.left; anchors.rightMargin: 10
                y: 16
                spacing: 2
                T { text: modelData.t; font.pixelSize: 17; font.bold: true; color: pf.p.primary }
                T { width: parent.width; elide: Text.ElideRight; text: cc.v.name || "..."; font.pixelSize: 12; color: pf.p.text }
            }
            Row {
                x: 18; y: parent.height - 58
                spacing: 6
                T { kind: "icon"; text: pf.d.md(0xF050F); font.pixelSize: 14; color: pf.p.sub }
                T { text: cc.v.temp !== undefined && cc.v.temp !== null ? cc.v.temp + "°C" : "--"; font.pixelSize: 14; color: pf.p.text }
                T { visible: modelData.k === "gpu" && !!cc.v.mem_total; text: "  ·  " + (cc.v.mem_used / 1024).toFixed(1) + " / " + (cc.v.mem_total / 1024).toFixed(1) + " GiB"; font.pixelSize: 12; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
            }
            // temperature bar (0..100 C)
            Item {
                x: 18; y: parent.height - 30
                width: blob.x - 32; height: 6
                Rectangle { anchors.fill: parent; radius: 3; color: pf.p.track }
                Rectangle {
                    width: parent.width * Math.min(1, (cc.v.temp || 0) / 100); height: parent.height; radius: 3
                    color: (cc.v.temp || 0) >= 85 ? "#e06c75" : pf.p.primary
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                }
            }
            T { anchors.horizontalCenter: blob.horizontalCenter; y: 16; text: "Usage"; font.pixelSize: 12; color: pf.p.sub }
            Cookie {
                id: blob
                anchors.right: parent.right; anchors.rightMargin: 16
                y: 40
                width: 96; height: 96
                fill: pf.p.container
                T { anchors.centerIn: parent; kind: "number"; text: cc.use >= 0 ? cc.use + "%" : "--"; font.pixelSize: 26; font.bold: true; color: pf.p.onContainer }
            }
        }
    }

    // ======== storage ========
    DCard {
        id: st
        p: pf.p; live: pf.live; order: 2
        readonly property var list: pf.s.disks || pf.d.disks || []
        readonly property var dk: list.length > 0 ? list[Math.min(pf.diskIdx, list.length - 1)] : null
        x: 0; y: pf.row1 + pf.gap
        width: 290; height: pf.height - y
        Item {
            id: sr
            x: 16; anchors.verticalCenter: parent.verticalCenter
            width: 112; height: 112
            DRing { anchors.fill: parent; p: pf.p; value: st.dk ? st.dk.pct : 0; line: 8 }
            Column {
                anchors.centerIn: parent
                T { anchors.horizontalCenter: parent.horizontalCenter; kind: "number"; text: st.dk ? st.dk.pct + "%" : "--"; font.pixelSize: 22; font.bold: true; color: pf.p.text }
                T { anchors.horizontalCenter: parent.horizontalCenter; text: "Used"; font.pixelSize: 11; color: pf.p.sub }
            }
        }
        Column {
            anchors.left: sr.right; anchors.leftMargin: 16
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            T { text: "Storage"; font.pixelSize: 16; font.bold: true; color: pf.p.text }
            T { text: st.dk ? pf.gib(st.dk.used) + " / " + pf.gib(st.dk.total) + " GiB" : "--"; font.pixelSize: 12; color: pf.p.sub }
            Item { width: 1; height: 6 }
            Rectangle {
                width: Math.min(parent.width, dl.implicitWidth + 40); height: 30; radius: 15
                color: dm.containsMouse ? pf.p.card2 : pf.p.container
                Row {
                    id: dl
                    anchors.centerIn: parent
                    spacing: 6
                    T { kind: "icon"; text: pf.d.md(0xF02CA); font.pixelSize: 12; color: pf.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                    T { text: st.dk ? st.dk.dev + "  " + st.dk.mount : "disk"; font.pixelSize: 11; color: pf.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                    T { visible: st.list.length > 1; kind: "icon"; text: pf.d.md(0xF0140); font.pixelSize: 12; color: pf.p.onContainer; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: pf.diskIdx = st.list.length > 0 ? (pf.diskIdx + 1) % st.list.length : 0 }
            }
        }
    }

    // ======== network ========
    DCard {
        id: nt
        p: pf.p; live: pf.live; order: 3
        x: st.width + pf.gap; y: st.y
        width: pf.leftW - st.width - mem.width - 2 * pf.gap; height: st.height
        Row {
            x: 16; y: 12
            spacing: 8
            T { kind: "icon"; text: pf.d.md(0xF04E1); font.pixelSize: 15; color: pf.p.primary; anchors.verticalCenter: parent.verticalCenter }
            T { text: "Network"; font.pixelSize: 16; font.bold: true; color: pf.p.text }
            T { text: pf.s.net ? pf.s.net.iface : ""; font.pixelSize: 10; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
        }
        Canvas {
            id: graph
            x: 16; y: 38
            width: parent.width - 32; height: parent.height - 38 - 64
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
                line(pf.rxHist, pf.p.primary, 0.22)
            }
        }
        Column {
            x: 16; width: parent.width - 32
            y: parent.height - 60
            spacing: 2
            Repeater {
                model: [
                    { g: 0xF01DA, n: "Download", v: pf.s.net ? pf.rate(pf.s.net.rx) : "--" },
                    { g: 0xF0552, n: "Upload", v: pf.s.net ? pf.rate(pf.s.net.tx) : "--" },
                    { g: 0xF051B, n: "Total", v: pf.s.net ? "↓" + pf.size(pf.s.net.rx_total) + "  ↑" + pf.size(pf.s.net.tx_total) : "--" }
                ]
                Item {
                    width: parent.width; height: 18
                    T { kind: "icon"; text: pf.d.md(modelData.g); font.pixelSize: 12; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
                    T { x: 22; text: modelData.n; font.pixelSize: 12; color: pf.p.sub; anchors.verticalCenter: parent.verticalCenter }
                    T { anchors.right: parent.right; text: modelData.v; font.pixelSize: 12; font.bold: true; color: pf.p.text; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ======== memory ========
    DCard {
        id: mem
        p: pf.p; live: pf.live; order: 4
        x: pf.leftW - width; y: st.y
        width: 180; height: st.height
        Row {
            x: 16; y: 12
            spacing: 8
            T { kind: "icon"; text: pf.d.md(0xF035B); font.pixelSize: 15; color: pf.p.primary; anchors.verticalCenter: parent.verticalCenter }
            T { text: "Memory"; font.pixelSize: 16; font.bold: true; color: pf.p.text }
        }
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40; width: 86; height: 86
            DRing { anchors.fill: parent; p: pf.p; value: pf.s.mem ? pf.s.mem.pct : 0; line: 7 }
            Column {
                anchors.centerIn: parent
                T { anchors.horizontalCenter: parent.horizontalCenter; kind: "number"; text: pf.s.mem ? pf.s.mem.pct + "%" : "--"; font.pixelSize: 19; font.bold: true; color: pf.p.text }
                T { anchors.horizontalCenter: parent.horizontalCenter; text: "Used"; font.pixelSize: 10; color: pf.p.sub }
            }
        }
        T { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 26; text: pf.s.mem ? pf.gib(pf.s.mem.used) + " / " + pf.gib(pf.s.mem.total) + " GiB" : ""; font.pixelSize: 12; color: pf.p.text }
    }

    // ======== battery ========
    DCard {
        id: bat
        p: pf.p; live: pf.live; order: 5
        readonly property var b: pf.s.battery || ({})
        readonly property var mb: b.main || null
        readonly property bool charging: !!mb && (mb.status === "Charging" || mb.status === "Full")
        x: pf.leftW + pf.gap; y: 0
        width: pf.batW; height: pf.height
        clip: true
        // the level fills the card from the bottom
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            // the top stays free for the title
            height: bat.mb ? Math.max(pf.p.cardRadius * 2, (parent.height - 76) * bat.mb.pct / 100 + pf.p.cardRadius) : 0
            radius: pf.p.cardRadius
            color: bat.mb && bat.mb.pct <= 15 && !bat.charging ? "#c0545e" : pf.p.primary
            opacity: 0.9
            Behavior on height { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        }
        Column {
            x: 18; y: 16
            spacing: 4
            T { kind: "icon"; text: bat.mb ? (bat.charging ? pf.d.md(0xF0241) : pf.d.md(0xF0079)) : pf.d.md(0xF06A5); font.pixelSize: 24; color: pf.p.primary }
            T { text: bat.mb ? "Battery" : "Power"; font.pixelSize: 15; font.bold: true; color: pf.p.text }
        }
        // devices (mouse, headset) when there is no battery, or under the level
        Column {
            visible: !bat.mb
            x: 18; y: 90; width: parent.width - 36
            spacing: 8
            T { width: parent.width; wrapMode: Text.WordWrap; text: (bat.b.devices || []).length ? "" : "Plugged in. No battery in this computer."; font.pixelSize: 11; color: pf.p.sub; visible: text !== "" }
            Repeater {
                model: (bat.b.devices || []).slice(0, 4)
                Column {
                    width: parent.width
                    spacing: 3
                    T { width: parent.width; elide: Text.ElideRight; text: modelData.name; font.pixelSize: 11; color: pf.p.text }
                    Rectangle { width: parent.width; height: 5; radius: 2.5; color: pf.p.track
                        Rectangle { width: parent.width * modelData.pct / 100; height: 5; radius: 2.5; color: pf.p.primary } }
                }
            }
        }
        Column {
            visible: !!bat.mb
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.bottom: parent.bottom; anchors.bottomMargin: 14
            spacing: 0
            T { anchors.right: parent.right; text: bat.mb ? (bat.mb.status === "Full" ? "Full" : bat.charging ? "Charging" : "On battery") : ""; font.pixelSize: 12; color: pf.p.onPrimary }
            Row {
                anchors.right: parent.right
                spacing: 4
                T { visible: bat.charging; kind: "icon"; text: pf.d.md(0xF0241); font.pixelSize: 24; color: pf.p.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                T { kind: "number"; text: bat.mb ? bat.mb.pct + "%" : ""; font.pixelSize: 34; font.bold: true; color: pf.p.onPrimary }
            }
            T { anchors.right: parent.right; visible: !!bat.mb && !!bat.mb.left; text: bat.mb && bat.mb.left ? bat.mb.left : ""; font.pixelSize: 10; color: pf.p.onPrimary; opacity: 0.8 }
        }
    }

    // wavy "cookie" shape (Material 3 expressive)
    component Cookie: Canvas {
        id: ck
        property color fill: "#333"
        property int bumps: 9
        onFillChanged: requestPaint()
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
