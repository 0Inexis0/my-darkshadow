import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// The island of the Dynamic bar style: it sits where the clock is and grows into whatever happens right now.
//   idle    the time (and, while music plays, the cover in your shape and a small moving wave)
//   media   point at it (or click it): the player, with the cover in your shape, a wavy progress line you can
//           drag, and a play button that changes shape while it plays
//   volume  the volume or the microphone changed: a wavy level you can drag
//   ws      you switched workspace: which one
//   notif   a notification came in (the shell shows notifications): its icon in your shape, the text, and a
//           wave that runs out while it stays
//   rec     the screen is being recorded: the time, the microphone and stop
// Everything moves on springs (Material 3 spatial motion); the content fades in after the shape has grown.
// The small things (time, volume, workspace, recording) change the island in the bar itself; the player and
// notifications open as a card just beside the bar (below it, or above it for a bar at the bottom), so the bar
// is never covered.
Item {
    id: isl
    property var bar: null
    property var pal: null                     // NPal of the bar
    property var nf: null                      // Notifs.qml
    readonly property int bh: bar ? bar.barH : 38
    readonly property bool down: !bar || !bar.atBottom     // grows downwards (bar at the top)
    readonly property var cfg: bar ? bar.bc : ({})
    function on(k) { return cfg[k] !== false }

    Player { id: pl; running: isl.visible }
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [isl.source] }
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    // ---------- what it shows ----------
    property string flash: ""                  // volume | mic | ws | notif (for a moment)
    property bool hoverOpen: false
    property bool pinned: false                // clicked open
    property var note: null                    // the notification it shows
    readonly property string mode: flash !== "" ? flash
        : ((pinned || hoverOpen) && pl.has ? "media"
        : (bar && bar.recOn ? "rec" : "idle"))
    function show(what, ms) { if (flash === "notif") return; flash = what; flashT.interval = ms; flashT.restart() }
    Timer { id: flashT; onTriggered: { isl.flash = ""; isl.note = null } }

    property bool ready: false
    Timer { running: true; interval: 2500; onTriggered: isl.ready = true }
    readonly property real vol: bar ? bar.vol : 0
    readonly property bool muted: bar ? bar.muted : false
    onVolChanged: if (ready && on("island_volume")) show("volume", 1600)
    onMutedChanged: if (ready && on("island_volume")) show("volume", 1600)
    onMicMutedChanged: if (ready && on("island_volume")) show("mic", 1600)
    readonly property int wsId: bar ? bar.focusedId : 1
    onWsIdChanged: if (ready && on("island_ws") && flash !== "notif" && flash !== "volume") show("ws", 1100)
    Connections {
        target: isl.nf
        ignoreUnknownSignals: true
        function onShowed(n) {
            if (!isl.on("island_notifs")) return
            flashT.stop()
            isl.note = n; isl.flash = "notif"
            noteRun.stop(); isl.noteLeft = 1; noteRun.duration = isl.noteLife; noteRun.start()
        }
    }
    // it stays while the wave runs out; pointing at it holds the wave
    readonly property int noteLife: nf ? Math.max(3, nf.timeout) * 1000 : 5000
    property real noteLeft: 1
    NumberAnimation { id: noteRun; target: isl; property: "noteLeft"; to: 0; paused: running && isl.hovering }
    onNoteLeftChanged: if (noteLeft <= 0.001 && flash === "notif") { flash = ""; note = null }

    // ---------- its size ----------
    readonly property real tw: {
        switch (mode) {
        case "volume": case "mic": return 300
        case "ws": return Math.max(190, wsRow.implicitWidth + 40)
        case "rec": return recRow.implicitWidth + 30
        }
        return idleRow.implicitWidth + 30
    }
    readonly property bool big: mode === "media" || mode === "notif"
    // what the island in the bar shows while the card is open: the time (or the recording)
    readonly property string pillMode: big ? (bar && bar.recOn ? "rec" : "idle") : mode
    property color fill: pal ? pal.surface : "#141414"
    property bool flatRest: false
    property real areaW: 1920                    // how wide the bar is (the card stays inside it)
    // its width in the bar
    readonly property real restW: big ? ((bar && bar.recOn ? recRow.implicitWidth : idleRow.implicitWidth) + 30) : tw
    width: restW; height: bh
    Behavior on width { SpringAnimation { spring: Look.lite ? 6 : 3.6; damping: Look.lite ? 0.6 : 0.3; epsilon: 0.4 } }

    // the card: which one it shows (kept while it closes)
    property string cardMode: "media"
    onBigChanged: if (big) cardMode = mode
    onModeChanged: if (big) cardMode = mode
    readonly property real cw: cardMode === "notif" ? 440 : 470
    readonly property real ch: cardMode === "notif" ? 96 : 184
    readonly property bool cardShown: card.opacity > 0.01
    // the part of the screen it takes (the bar lets the pointer through everywhere else)
    readonly property real ux: cardShown ? Math.min(0, card.x) : 0
    readonly property real uy: cardShown ? Math.min(0, card.y) : 0
    readonly property real uw: (cardShown ? Math.max(width, card.x + card.width) : width) - ux
    readonly property real uh: (cardShown ? Math.max(height, card.y + card.height) : height) - uy

    // pointing at it: opens the player; it closes a moment after the pointer leaves (a clicked one waits longer)
    readonly property bool hovering: hov.hovered || hovC.hovered
    HoverHandler { id: hov }
    onHoveringChanged: {
        if (hovering) { closeT.stop(); pinT.stop(); if (on("island_hover") && !big) openT.restart() }
        else { openT.stop(); closeT.restart(); if (pinned) pinT.restart() }
    }
    Timer { id: openT; interval: 260; onTriggered: isl.hoverOpen = pl.has }
    Timer { id: closeT; interval: 450; onTriggered: isl.hoverOpen = false }
    Timer { id: pinT; interval: 3500; onTriggered: isl.pinned = false }
    // the player closes by itself when nothing plays any more
    onPlayingChanged: if (!playing && !hovering) { pinT.restart(); closeT.restart() }
    readonly property bool playing: pl.playing

    // ---------- the shape ----------
    Shadow { anchors.fill: bg; radius: bg.radius; on: Look.shadows && Look.shadowBar && !isl.flatRest; size: Look.shadowSize * 0.5; strength: Look.shadowStrength }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        // inside the notch or a pill with modules it has no color of its own (no darker band)
        color: isl.flatRest ? Qt.rgba(isl.fill.r, isl.fill.g, isl.fill.b, 0) : isl.fill
        clip: true

        // ---------- idle: the time ----------
        Face {
            id: fIdle; name: "idle"; width: idleRow.implicitWidth + 30; height: isl.bh
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(m) {
                    if (m.button === Qt.LeftButton && pl.has) { isl.pinned = !isl.pinned; return }
                    isl.bar.run("\"$HOME/.local/bin/rice-dashboard\" open")
                }
                onWheel: function(e) { if (isl.bar.sink && isl.bar.sink.audio) isl.bar.sink.audio.volume = Math.max(0, Math.min(1, isl.bar.sink.audio.volume + (e.angleDelta.y > 0 ? 0.04 : -0.04))) }
            }
            Row {
                id: idleRow
                anchors.centerIn: parent
                spacing: 9
                ShapeImage { visible: pl.playing; width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter
                    kind: Look.shape; source: pl.art; empty: isl.pal ? isl.pal.container : "#333"; fallbackColor: isl.pal ? isl.pal.inkContainer : "#ccc"
                    RotationAnimator on rotation { from: 0; to: 360; duration: 9000; loops: Animation.Infinite; running: pl.playing && !Look.lite } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: isl.bar ? isl.bar.timeText : ""
                    color: isl.pal ? isl.pal.fg : "white"; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                Eq { visible: pl.playing; anchors.verticalCenter: parent.verticalCenter; h: 14; running: isl.pillMode === "idle" }
            }
        }

        // ---------- rec: the screen is being recorded ----------
        Face {
            name: "rec"; width: recRow.implicitWidth + 30; height: isl.bh
            Row {
                id: recRow
                anchors.centerIn: parent
                spacing: 12
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: "#ff5a5a"
                    SequentialAnimation on opacity { running: isl.pillMode === "rec"; loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 700 } NumberAnimation { to: 1; duration: 700 } } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: isl.bar ? isl.bar.recTime : ""
                    color: isl.pal ? isl.pal.fg : "white"; font.family: Fonts.numbers; font.pixelSize: 14; font.weight: Font.Medium }
                Item { width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                    MIcon { anchors.centerIn: parent; size: 17; name: isl.micMuted ? "mic_off" : "mic"
                        glyph: String.fromCodePoint(isl.micMuted ? 0xF036D : 0xF036C); color: isl.micMuted ? "#ff8a8a" : (isl.pal ? isl.pal.fg : "white") }
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                        onClicked: isl.bar.run("\"$HOME/.local/bin/rice-volume\" mic") } }
                Item { width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.centerIn: parent; width: 13; height: 13; radius: 4; color: "transparent"; border.width: 2; border.color: "#ff8a8a" }
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                        onClicked: { isl.bar.recOn = false; isl.bar.run("\"$HOME/.local/bin/rice-hotcorner\" record stop") } } }
            }
        }

        // ---------- volume / microphone ----------
        Face {
            name: isl.mode === "mic" ? "mic" : "volume"; width: 300; height: isl.bh
            Row {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 16
                spacing: 10
                Item { width: isl.bh - 10; height: width; anchors.verticalCenter: parent.verticalCenter
                    Blob { anchors.fill: parent; kind: Look.shape; color: isl.pal ? isl.pal.primary : "white" }
                    MIcon { anchors.centerIn: parent; size: 16; filled: true; color: isl.pal ? isl.pal.inkPrimary : "black"
                        name: isl.mode === "mic" ? (isl.micMuted ? "mic_off" : "mic") : (isl.muted ? "volume_off" : (isl.vol < 0.5 ? "volume_down" : "volume_up"))
                        glyph: "" } }
                WavyLine {
                    visible: isl.mode !== "mic"
                    width: parent.width - isl.bh - 48; height: 18; anchors.verticalCenter: parent.verticalCenter
                    value: isl.muted ? 0 : Math.min(1, isl.vol); moving: !isl.muted; seekable: true
                    color: isl.pal ? isl.pal.primary : "white"; track: isl.pal ? isl.pal.track : "#444"
                    onMoved: function(v) { if (isl.bar.sink && isl.bar.sink.audio) { isl.bar.sink.audio.muted = false; isl.bar.sink.audio.volume = v }; isl.show("volume", 1600) }
                }
                Text { visible: isl.mode === "mic"; width: parent.width - isl.bh - 48; anchors.verticalCenter: parent.verticalCenter
                    text: isl.micMuted ? "Microphone off" : "Microphone on"; color: isl.pal ? isl.pal.fg : "white"; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium }
                Text { width: 30; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; visible: isl.mode !== "mic"
                    text: isl.muted ? "0" : Math.round(isl.vol * 100); color: isl.pal ? isl.pal.fg : "white"; font.family: Fonts.numbers; font.pixelSize: 13; font.weight: Font.Medium }
            }
        }

        // ---------- workspace ----------
        Face {
            name: "ws"; width: isl.tw; height: isl.bh
            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 7
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Workspace"; color: isl.pal ? isl.pal.dim : "#aaa"; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.Medium; rightPadding: 4 }
                Repeater {
                    model: isl.bar ? Math.min(10, isl.bar.maxWs()) : 5
                    // follows Settings > DarkShadow bar > Workspace style: dots, Pac-Man, letters or numbers
                    delegate: Item {
                        id: wc
                        readonly property int wid: index + 1
                        readonly property bool act: isl.wsId === wid
                        readonly property string st: isl.bar ? isl.bar.wsStyle : "dots"
                        anchors.verticalCenter: parent.verticalCenter
                        width: st === "dots" ? (act ? 30 : 8) : (st === "pacman" ? 16 : 22)
                        height: 22
                        Behavior on width { SpringAnimation { spring: 4; damping: 0.35 } }
                        // dots: the active one a pill with its number
                        Rectangle {
                            visible: wc.st === "dots"
                            anchors.centerIn: parent
                            width: parent.width; height: wc.act ? 20 : 8; radius: height / 2
                            Behavior on height { SpringAnimation { spring: 4; damping: 0.35 } }
                            color: wc.act ? (isl.pal ? isl.pal.primary : "white") : (isl.pal ? isl.pal.track : "#555")
                            Text { anchors.centerIn: parent; visible: wc.act; text: wc.wid; color: isl.pal ? isl.pal.inkPrimary : "black"; font.family: Fonts.main; font.pixelSize: 11; font.weight: Font.Bold }
                        }
                        // letters / numbers: the active one in a round pill of your key color
                        Rectangle {
                            visible: wc.st === "letters" || wc.st === "numbers"
                            anchors.centerIn: parent; width: 22; height: 22; radius: 11
                            color: isl.pal ? isl.pal.primary : "white"
                            opacity: wc.act ? 1 : 0; scale: wc.act ? 1 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                        }
                        Text {
                            visible: wc.st === "letters" || wc.st === "numbers"
                            anchors.centerIn: parent
                            text: wc.st === "numbers" ? String(wc.wid) : String.fromCharCode(64 + wc.wid)
                            color: wc.act ? (isl.pal ? isl.pal.inkPrimary : "black") : (isl.pal ? isl.pal.dim : "#aaa")
                            font.family: Fonts.main; font.pixelSize: 12; font.weight: wc.act ? Font.Bold : Font.Medium
                        }
                        // Pac-Man: dots he has eaten fade, he sits on the one you are on
                        Rectangle {
                            visible: wc.st === "pacman" && !wc.act
                            anchors.centerIn: parent; width: 6; height: 6; radius: 3
                            color: isl.pal ? isl.pal.fg : "white"
                            opacity: wc.wid < isl.wsId ? 0.25 : 0.8
                        }
                        Canvas {
                            visible: wc.st === "pacman" && wc.act
                            anchors.centerIn: parent; width: 16; height: 16
                            property real mouth: 0.22
                            SequentialAnimation on mouth {
                                running: wc.act && wc.st === "pacman" && isl.mode === "ws"; loops: Animation.Infinite
                                NumberAnimation { to: 0.02; duration: 120 } NumberAnimation { to: 0.26; duration: 120 }
                            }
                            onMouthChanged: requestPaint()
                            onVisibleChanged: if (visible) requestPaint()
                            onPaint: {
                                const c = getContext("2d"); c.reset()
                                c.fillStyle = isl.pal ? isl.pal.primary : "#ffd84a"
                                c.beginPath(); c.moveTo(8, 8); c.arc(8, 8, 8, mouth * Math.PI, (2 - mouth) * Math.PI); c.closePath(); c.fill()
                            }
                        }
                    }
                }
            }
        }

    }

    // ---------- the card: the player or a notification, just beside the bar ----------
    Shadow { anchors.fill: card; radius: card.radius; on: Look.shadows && Look.shadowBar; opacity: card.opacity; size: Look.shadowSize; strength: Look.shadowStrength }
    Rectangle {
        id: card
        property real t: isl.big ? 1 : 0
        Behavior on t { NumberAnimation { duration: isl.big ? 520 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: isl.big ? Look.decel : Look.accel } }
        width: isl.cw; height: isl.ch
        Behavior on width { SpringAnimation { spring: 3.6; damping: 0.32; epsilon: 0.4 } }
        Behavior on height { SpringAnimation { spring: 3.6; damping: 0.32; epsilon: 0.4 } }
        // centred on the island, but always on the screen
        x: Math.max(-isl.x, Math.min(isl.areaW - isl.x - width, (isl.width - width) / 2))
        y: isl.down ? isl.bh + 8 : -height - 8
        radius: 30
        color: isl.fill
        visible: opacity > 0.01
        opacity: Math.min(1, t * 1.5)
        // it grows out of the island: from the island's side, small and a little narrower
        transform: Scale {
            origin.x: card.width / 2; origin.y: isl.down ? 0 : card.height
            xScale: 0.7 + 0.3 * card.t; yScale: 0.4 + 0.6 * card.t
        }
        clip: true
        HoverHandler { id: hovC }
        // the player tints the card with your key color
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            opacity: isl.cardMode === "media" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: isl.pal ? Qt.rgba(isl.pal.primary.r, isl.pal.primary.g, isl.pal.primary.b, 0.2) : "transparent" }
                GradientStop { position: 0.7; color: "transparent" }
            }
        }

        // ---------- a notification ----------
        Face {
            name: "notif"; inCard: true; width: 440; height: 96
            readonly property var n: isl.note
            Item {
                id: nIc
                x: 16; y: 16; width: 46; height: 46
                Blob { anchors.fill: parent; kind: Look.shape; color: isl.pal ? isl.pal.container : "#333"
                    RotationAnimator on rotation { from: 0; to: 360; duration: 24000; loops: Animation.Infinite; running: isl.mode === "notif" && !Look.lite } }
                Image { id: nImg; anchors.centerIn: parent; width: 24; height: 24; sourceSize.width: 48; sourceSize.height: 48
                    source: { const n = isl.note; if (!n) return ""
                        if (n.appIcon && n.appIcon !== "") return n.appIcon.indexOf("/") === 0 ? "file://" + n.appIcon : Quickshell.iconPath(n.appIcon, true)
                        return Quickshell.iconPath((n.appName || "dialog-information").toLowerCase(), true) }
                    visible: status === Image.Ready }
                MIcon { anchors.centerIn: parent; size: 20; filled: true; name: "notifications"; glyph: ""; visible: nImg.status !== Image.Ready
                    color: isl.pal ? isl.pal.inkContainer : "white" }
            }
            Column {
                x: 74; y: 14; width: parent.width - 74 - 46; spacing: 2
                Text { text: isl.note ? (isl.note.appName || "Notification") : ""; color: isl.pal ? isl.pal.dim : "#aaa"; font.family: Fonts.main; font.pixelSize: 11 }
                Text { width: parent.width; elide: Text.ElideRight; text: isl.note ? (isl.note.summary || "") : ""
                    color: isl.pal ? isl.pal.fg : "white"; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; maximumLineCount: 1; textFormat: Text.PlainText
                    text: isl.note ? String(isl.note.body || "").replace(/<[^>]*>/g, "") : ""; color: isl.pal ? isl.pal.dim : "#aaa"; font.family: Fonts.main; font.pixelSize: 12 }
            }
            // how long it stays, as a wave that runs out
            WavyLine { x: 74; y: parent.height - 22; width: parent.width - 74 - 20; height: 14
                value: isl.noteLeft; handle: false; moving: true; thick: 3
                color: isl.pal ? isl.pal.primary : "white"; track: isl.pal ? isl.pal.track : "#444" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { isl.flash = ""; isl.bar.run("\"$HOME/.local/bin/rice-cc\" open") } }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 10; y: 10; width: 28; height: 28; radius: 14
                color: xm.containsMouse ? (isl.pal ? isl.pal.cardHi : "#444") : "transparent"
                MIcon { anchors.centerIn: parent; size: 15; name: "close"; glyph: ""; color: isl.pal ? isl.pal.dim : "#aaa" }
                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (isl.note && isl.nf) isl.nf.dismiss(isl.note); isl.flash = ""; isl.note = null } }
            }
        }

        // ---------- the player ----------
        Face {
            name: "media"; inCard: true; width: 470; height: 184
            ShapeImage {
                x: 16; y: 16; width: 78; height: 78
                kind: Look.shape; source: pl.art
                empty: isl.pal ? isl.pal.container : "#333"; fallbackColor: isl.pal ? isl.pal.inkContainer : "#ccc"
            }
            Column {
                x: 110; y: 18; width: parent.width - 110 - 70; spacing: 3
                Text { text: (pl.p && pl.p.identity ? pl.p.identity : "Music").toUpperCase(); color: isl.pal ? isl.pal.primary : "#aaa"
                    font.family: Fonts.main; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                Text { width: parent.width; elide: Text.ElideRight; text: pl.title; color: isl.pal ? isl.pal.fg : "white"
                    font.family: Fonts.main; font.pixelSize: 17; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: pl.artist; color: isl.pal ? isl.pal.dim : "#aaa"; font.family: Fonts.main; font.pixelSize: 13 }
            }
            // a wave that moves while it plays
            Eq { x: parent.width - 58; y: 22; h: 22; bars: 5; running: pl.playing && isl.mode === "media" }
            Text { x: 16; y: 110; width: 38; text: pl.clock(pl.pos); color: isl.pal ? isl.pal.dim : "#aaa"; font.family: Fonts.numbers; font.pixelSize: 11 }
            WavyLine {
                x: 56; y: 105; width: parent.width - 112; height: 22
                value: pl.frac; moving: pl.playing; seekable: true
                color: isl.pal ? isl.pal.primary : "white"; track: isl.pal ? isl.pal.track : "#444"
                onMoved: function(v) { pl.seekTo(v) }
            }
            Text { x: parent.width - 52; y: 110; width: 38; horizontalAlignment: Text.AlignRight
                text: pl.length > 0 ? "-" + pl.clock(pl.length - pl.pos) : ""; color: isl.pal ? isl.pal.dim : "#aaa"; font.family: Fonts.numbers; font.pixelSize: 11 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; y: 134
                spacing: 22
                Btn { icon: "skip_previous"; onHit: pl.prev() }
                // play / pause: your shape while it plays, a circle while it waits; pressing squeezes it
                Item {
                    width: 40; height: 40; anchors.verticalCenter: parent.verticalCenter
                    Blob { anchors.fill: parent; kind: pl.playing ? Look.shape : "circle"; color: isl.pal ? isl.pal.primary : "white"
                        scale: pm.pressed ? 0.86 : (pm.containsMouse ? 1.06 : 1)
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                        RotationAnimator on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite; running: pl.playing && !Look.lite } }
                    MIcon { anchors.centerIn: parent; size: 20; filled: true; name: pl.playing ? "pause" : "play_arrow"; glyph: ""
                        color: isl.pal ? isl.pal.inkPrimary : "black" }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pl.toggle() }
                }
                Btn { icon: "skip_next"; onHit: pl.next() }
            }
            MouseArea { x: parent.width - 40; y: parent.height - 40; width: 30; height: 30; cursorShape: Qt.PointingHandCursor
                visible: isl.pinned; onClicked: isl.pinned = false
                MIcon { anchors.centerIn: parent; size: 16; name: "keyboard_arrow_up"; glyph: ""; color: isl.pal ? isl.pal.dim : "#aaa"; rotation: isl.down ? 0 : 180 } }
        }
    }

    // one face of the island: it shows when its mode is on, after the shape has begun to grow
    component Face: Item {
        id: fc
        property string name: ""
        property bool inCard: false
        readonly property bool act: inCard ? isl.mode === name : isl.pillMode === name
        x: (parent.width - width) / 2
        y: isl.down ? 0 : parent.height - height
        // it comes in once the shape has (nearly) grown to it, so it is never seen cut
        opacity: act && parent.width >= width * 0.82 && parent.height >= height * 0.82 ? 1 : 0
        scale: act ? 1 : 0.94
        visible: opacity > 0.01
        enabled: act
        Behavior on opacity { NumberAnimation { duration: fc.act ? 260 : 90; easing.type: Easing.Linear } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Look.decel } }
    }
    // a small equalizer: round bars in your key color that bounce while music plays
    component Eq: Row {
        id: eq
        property int bars: 4
        property real h: 14
        property bool running: true
        spacing: 2.5
        Repeater {
            model: eq.bars
            delegate: Rectangle {
                id: bb
                width: 3.5; radius: 2; anchors.verticalCenter: parent.verticalCenter
                color: isl.pal ? isl.pal.primary : "white"
                property real lv: 0.4
                height: Math.max(4, eq.h * lv)
                SequentialAnimation on lv {
                    running: eq.running && !Look.lite; loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 260 + index * 70; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.3 + (index % 2) * 0.15; duration: 300 + index * 50; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.75; duration: 220 + index * 90; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 280 + index * 40; easing.type: Easing.InOutSine }
                }
            }
        }
    }
    component Btn: Item {
        id: bt
        property string icon: ""
        signal hit()
        width: 34; height: 34
        Rectangle { anchors.fill: parent; radius: width / 2; color: isl.pal ? isl.pal.fg : "white"; opacity: bm.containsMouse ? 0.1 : 0
            Behavior on opacity { NumberAnimation { duration: 140 } } }
        MIcon { anchors.centerIn: parent; size: 20; filled: true; name: bt.icon; glyph: ""; color: isl.pal ? isl.pal.fg : "white" }
        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bt.hit() }
    }
}
