import QtQuick

// A section: a tonal circle with a symbol for it, its name and a short line under it (V4.88). The symbol comes from
// the words of the name (in English, also when Settings speaks another language); `sym` and `icon` pick one.
Item {
    id: st
    property string text: ""
    property string sub: ""
    property string sym: ""
    property string icon: ""
    property real topPadding: 22
    readonly property var map: [
        [/password|passkey/, "password"], [/account|users\b/, "group"], [/\buser|you\b|profile/, "person"],
        [/\bdock/, "dock_to_bottom"], [/notif|pop-?up/, "notifications"], [/sound|sfx|volume|audio/, "volume_up"],
        [/wallpaper/, "wallpaper"], [/colou?r|palette|theme|tint/, "palette"], [/\bfont|text\b|typeface/, "text_fields"],
        [/shape|corner/, "interests"], [/motion|anim|spring|bounce/, "animation"], [/window|tile|float/, "select_window"],
        [/keybind|shortcut|\bkeys?\b|keyboard/, "keyboard"], [/language|region|translat/, "translate"],
        [/monitor|screen|display|resolution/, "monitor"], [/\bidle|sleep|suspend/, "bedtime"], [/lock/, "lock"],
        [/clock|time|date/, "schedule"], [/weather/, "partly_cloudy_day"], [/music|media|player|song/, "music_note"],
        [/gam(e|ing)/, "sports_esports"], [/perform|light mode|speed|lighter/, "speed"], [/update|version/, "system_update"],
        [/secur|scan|virus|harden/, "shield"], [/privacy|hidden|hide/, "visibility_off"], [/record|capture/, "videocam"],
        [/launcher|search|rofi/, "search"], [/island/, "pill"], [/widget/, "widgets"], [/cursor|pointer|mouse/, "mouse"],
        [/file|folder/, "folder"], [/wi-?fi|network|internet/, "wifi"], [/bluetooth/, "bluetooth"],
        [/battery|power|energy/, "battery_full"], [/start|autostart|login/, "rocket_launch"], [/hyprland|niri|compositor/, "tune"],
        [/about|credit|thank/, "info"], [/reset|danger|remove/, "restart_alt"], [/layout|position|place/, "dashboard"],
        [/icon|app/, "apps"], [/blur|transparen|see-through|opacity/, "blur_on"], [/gap|border/, "border_style"],
        [/tool/, "build"], [/bar\b|panel/, "toolbar"], [/style|look|appearance/, "brush"],
        [/computer|system|hardware|machine/, "computer"], [/made with|open source|project|code/, "code"], [/download|get more|install/, "download"]
    ]
    readonly property string pick: {
        if (sym.length) return sym
        const e = I18n.en(text).toLowerCase()
        for (let i = 0; i < map.length; i++) if (map[i][0].test(e)) return map[i][1]
        return ""
    }
    width: parent ? parent.width : 400
    height: topPadding + Math.max(44, col.implicitHeight) + 6

    // the symbol in a tonal circle; with none found, your shape (Appearance > Shapes) in the key color
    Rectangle {
        id: badge
        x: 4; y: st.topPadding
        width: 44; height: 44; radius: M3.sq ? 0 : (22)
        color: M3.secondaryContainer
        // Minimal mode: a symbol always (the shape turned into a plain square there, which looked like a missing icon)
        Icon { visible: st.pick !== "" || st.icon !== "" || M3.sq; anchors.centerIn: parent; name: st.pick !== "" || st.icon !== "" ? st.pick : "label"; glyph: st.icon; size: 21; color: M3.inkSecondaryC }
        Blob { visible: st.pick === "" && st.icon === "" && !M3.sq; anchors.centerIn: parent; width: 22; height: 22; kind: Prefs.accentShape || "cookie"; color: M3.primary }
    }
    Column {
        id: col
        x: badge.x + badge.width + 14
        y: st.topPadding + (st.sub.length ? 0 : 10)
        width: st.width - x - 4
        spacing: 2
        T { kind: "title"; text: st.text; font.pixelSize: 19; font.weight: Font.DemiBold; color: M3.ink; width: parent.width; elide: Text.ElideRight }
        T { kind: "reading"; visible: st.sub.length > 0; text: st.sub; color: M3.inkDim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap }
    }
}
