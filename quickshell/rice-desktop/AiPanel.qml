import QtQuick

// Same tonal cards, shaped badges and moving wave as the music / system island.
Item {
    id: panel
    property var pal: null
    property var providers: AiStatus.providers
    property bool animate: visible
    readonly property color fg: pal ? pal.fg : "#ECEDEE"
    readonly property color dim: pal ? pal.dim : "#A9ADB2"
    readonly property color accent: pal ? pal.primary : "#b7bfdf"
    Row {
        x: 22; y: 4; width: parent.width - 44; spacing: 10
        Repeater {
            model: 2
            delegate: Rectangle {
                id: tile
                required property int index
                readonly property var entry: panel.providers[index] || ({provider: index === 0 ? "codex" : "claude", state: "offline"})
                readonly property bool busy: (entry.active || 0) > 0
                width: (panel.width - 54) / 2; height: 210; radius: 22
                color: panel.pal ? (busy ? panel.pal.container : panel.pal.card) : "#25262d"
                Behavior on color { ColorAnimation { duration: 300 } }
                Item {
                    x: 14; y: 14; width: 32; height: 32
                    Blob { anchors.fill: parent; kind: Look.shape; color: panel.accent
                        SlowSpin { turn: 360; period: 12000; running: panel.animate && tile.busy && !Look.lite } }
                    MIcon { anchors.centerIn: parent; name: tile.entry.provider === "codex" ? "code" : "asterisk"; size: 19; glyph: ""
                        color: panel.pal ? panel.pal.inkPrimary : "#15151b" }
                }
                Column {
                    x: 55; y: 13; width: parent.width - 69; spacing: 2
                    Text { text: tile.entry.provider === "codex" ? "Codex" : "Claude"; color: panel.fg; font.family: Fonts.main; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Text { width: parent.width; elide: Text.ElideRight; text: AiStatus.state(tile.entry.state); color: panel.accent; font.family: Fonts.main; font.pixelSize: 10 }
                }
                Text { x: 14; y: 57; width: parent.width - 28; elide: Text.ElideMiddle; textFormat: Text.PlainText
                    text: tile.entry.model || (tile.entry.provider === "claude" ? Tr.t("Claude Code · Desktop / CLI") : Tr.t("Desktop / CLI"))
                    color: panel.dim; font.family: Fonts.main; font.pixelSize: 10 }
                Text { x: 14; y: 75; width: parent.width - 28; elide: Text.ElideMiddle; textFormat: Text.PlainText
                    text: tile.entry.project ? tile.entry.project + (tile.entry.active > 1 ? " · " + tile.entry.active + " " + Tr.t("active") : "") : Tr.t("Waiting for a local session")
                    color: panel.fg; font.family: Fonts.main; font.pixelSize: 11 }
                Text { x: 14; y: 105; text: Tr.t("Session tokens"); color: panel.dim; font.family: Fonts.main; font.pixelSize: 10 }
                Text { x: 14; y: 121; width: parent.width - 28; elide: Text.ElideRight
                    text: tile.entry.usage_available ? "↓ " + AiStatus.tokens(tile.entry.input) + "   ↑ " + AiStatus.tokens(tile.entry.output) : "—"
                    color: panel.fg; font.family: Fonts.numbers; font.pixelSize: 21; font.weight: Font.Medium }
                readonly property var limit: entry.limits && entry.limits.length ? entry.limits[0] : null
                readonly property bool hasContext: entry.context !== null && entry.context !== undefined
                Text { x: 14; y: 159; width: parent.width - 28; elide: Text.ElideRight
                    text: tile.limit ? Tr.t("Limit used") + " · " + (tile.limit.minutes >= 1440 ? Math.round(tile.limit.minutes / 1440) + "d" : Math.round(tile.limit.minutes / 60) + "h") + "   " + Math.round(tile.limit.used) + "%"
                        : (tile.hasContext ? Tr.t("Context") + "   " + Math.round(tile.entry.context * 100) + "%" : Tr.t("Local activity"))
                    color: panel.dim; font.family: Fonts.main; font.pixelSize: 10 }
                WavyLine { x: 14; y: 179; width: parent.width - 28; height: 14; handle: false; thick: 3
                    value: tile.limit ? tile.limit.used / 100 : (tile.hasContext ? tile.entry.context : (tile.busy ? 1 : 0))
                    moving: tile.busy && panel.animate; color: panel.accent; track: panel.pal ? panel.pal.track : "#444" }
            }
        }
    }
    Text { x: 22; y: 226; width: parent.width - 44; elide: Text.ElideRight
        text: Tr.t("Local sessions · token counts include cached input")
        color: panel.dim; font.family: Fonts.main; font.pixelSize: 10 }
}
