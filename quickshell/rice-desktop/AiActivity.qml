import QtQuick

// Hover is a live activity card, with the same proportions and motion as the player.
Item {
    id: live
    property var pal: null
    property bool animate: visible
    readonly property var agent: AiStatus.current
    readonly property bool busy: AiStatus.active
    readonly property bool waiting: agent.state === "waiting"
    readonly property color accent: pal ? pal.primary : "#b7bfdf"
    readonly property color fg: pal ? pal.fg : "#ECEDEE"
    readonly property color dim: pal ? pal.dim : "#A9ADB2"
    readonly property string activity: waiting ? Tr.t("Waiting for your approval") : (!busy ? Tr.t("Task complete") : AiStatus.activity(agent.action))
    property real now: Date.now() / 1000
    Timer { interval: 1000; running: live.animate && live.busy; repeat: true; triggeredOnStart: true; onTriggered: live.now = Date.now() / 1000 }
    readonly property string elapsed: {
        if (!agent.started) return "—"
        const seconds = Math.max(0, Math.floor((busy ? now : agent.updated) - agent.started))
        return Math.floor(seconds / 60) + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60
    }

    Item {
        x: 20; y: 22; width: 106; height: 106
        // A rotating tonal shape with two orbiting sparks; reduced motion stays still.
        Blob { anchors.fill: parent; anchors.margins: 8; kind: Look.shape
            color: live.pal ? live.pal.container : "#333746"
            SlowSpin { turn: 360; period: 20000; running: live.animate && live.busy && !Look.lite } }
        Item { anchors.fill: parent
            SlowSpin { turn: 360; period: 7000; running: live.animate && live.busy && !Look.lite }
            Rectangle { x: 49; y: 0; width: 8; height: 8; radius: 4; color: live.accent }
            Rectangle { x: 50; y: 100; width: 6; height: 6; radius: 3; color: live.accent; opacity: 0.4 }
        }
        MIcon { anchors.centerIn: parent; size: 42; glyph: ""
            name: live.waiting ? "pause" : (!live.busy ? "check" : (live.agent.provider === "claude" ? "asterisk" : "code"))
            color: live.accent }
    }

    Text { x: 146; y: 20; width: parent.width - 170; elide: Text.ElideRight
        text: live.busy ? AiStatus.label : (live.agent.provider === "claude" ? "Claude" : "Codex")
        color: live.fg; font.family: Fonts.main; font.pixelSize: 21; font.weight: Font.DemiBold }
    Text { x: 146; y: 51; width: parent.width - 170; elide: Text.ElideRight
        text: live.activity; color: live.accent; font.family: Fonts.main; font.pixelSize: 13; font.weight: Font.Medium
        Behavior on color { ColorAnimation { duration: 240 } } }
    Text { x: 146; y: 77; width: parent.width - 170; elide: Text.ElideMiddle; textFormat: Text.PlainText
        text: live.agent.project || Tr.t("Local session"); color: live.dim; font.family: Fonts.main; font.pixelSize: 11 }
    WavyLine { x: 146; y: 103; width: parent.width - 170; height: 18
        value: live.busy ? 1 : 0; activity: live.busy && !live.waiting; handle: false; thick: 3
        moving: live.animate && live.busy && !live.waiting
        color: live.accent; track: live.pal ? live.pal.track : "#444" }

    Row {
        x: 22; y: 144; spacing: 7
        Chip { icon: "schedule"; label: live.elapsed }
        Chip { icon: "terminal"; label: (live.agent.tools || 0) + " " + Tr.t("tool calls") }
        Chip { icon: live.busy ? "sensors" : "check_circle"; label: live.busy ? AiStatus.data.active + " " + Tr.t("active") : Tr.t("Ready") }
    }
    component Chip: Rectangle {
        id: chip
        property string icon: ""
        property string label: ""
        width: content.implicitWidth + 20; height: 25; radius: 12.5
        color: live.pal ? live.pal.card : "#25262d"
        Row { id: content; anchors.centerIn: parent; spacing: 5
            MIcon { anchors.verticalCenter: parent.verticalCenter; name: chip.icon; glyph: ""; size: 12; color: live.accent }
            Text { anchors.verticalCenter: parent.verticalCenter; text: chip.label; color: live.dim; font.family: Fonts.numbers; font.pixelSize: 10 }
        }
    }
}
