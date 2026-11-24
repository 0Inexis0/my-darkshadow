import QtQuick

// The colors of the control center and the notification pop-ups (Settings > Notifications > Theme):
//   shell (tonal, from your theme color), graphite, black, slate, white (light) and tinted.
// alpha: how solid the surface is (Settings > Notifications > Transparency); Light mode / gaming make it solid.
QtObject {
    id: np
    property string theme: "shell"
    property real alpha: 0.9
    // a grey key color (a black, white or grey wallpaper): grey everywhere, no made-up blue
    readonly property bool mono: Look.accent.hslHue < 0 || Look.accent.hslSaturation < 0.1
    readonly property real hue: Look.accent.hslHue < 0 ? 0.55 : Look.accent.hslHue
    readonly property real sat: mono ? 0 : Math.max(0.35, Math.min(0.85, Look.accent.hslSaturation))
    readonly property bool light: theme === "white"
    readonly property real a: Look.flat ? 1 : alpha
    // the key color (buttons that are on, sliders, the wave)
    readonly property color primary: light ? Qt.hsla(hue, sat, 0.36, 1) : Qt.hsla(hue, sat, 0.78, 1)
    readonly property color inkPrimary: light ? "#ffffff" : Qt.hsla(hue, Math.min(sat, 0.5), 0.13, 1)
    readonly property color container: light ? Qt.hsla(hue, sat * 0.5, 0.86, 1) : Qt.hsla(hue, sat * (theme === "tinted" ? 0.55 : 0.35), 0.25, 1)
    readonly property color inkContainer: light ? Qt.hsla(hue, sat, 0.2, 1) : Qt.hsla(hue, sat * 0.6, 0.88, 1)
    // the surface and the cards on it
    // V5.02 Minimal mode: the shell theme takes the bar's surface (menus, the control center and pop-ups were near
    // black next to a tinted bar); a theme you picked (graphite, black ...) stays as it is
    readonly property color surface: theme === "shell" && Look.sq ? minSurface : baseSurface
    readonly property color baseSurface: {
        switch (theme) {
        // V5.02: the themes are set further apart (they were all nearly the same black, so picking one seemed to
        // do nothing)
        case "black": return Qt.rgba(0, 0, 0, a)
        case "graphite": return Qt.rgba(0.16, 0.16, 0.17, a)
        case "slate": return Qt.hsla(0.6, 0.22, 0.17, a)
        case "white": return Qt.rgba(0.96, 0.96, 0.965, a)
        case "tinted": return Qt.hsla(hue, mono ? 0 : sat * 0.55, 0.17, a)
        default: return Qt.hsla(hue, mono ? 0 : 0.12, 0.1, a)
        }
    }
    // V5.00 Minimal mode: the surface of the bar, tinted with your wallpaper's color and lighter than black (a grey
    // wallpaper gives graphite), so the square bar matches the wallpaper instead of being a black slab
    readonly property color minSurface: light ? baseSurface : Qt.hsla(hue, mono ? 0 : sat * 0.42, 0.17, a)
    // how solid the cards are (1: solid, as everywhere; the toolbox lets its own Transparency through them too)
    property real cardAlpha: 1
    readonly property color cardBase: light ? Qt.rgba(1, 1, 1, 1) : Qt.lighter(Qt.rgba(surface.r, surface.g, surface.b, 1), theme === "black" ? 2.6 : 1.75)
    readonly property color card: Qt.rgba(cardBase.r, cardBase.g, cardBase.b, Look.flat ? 1 : cardAlpha)
    readonly property color cardHi: light ? Qt.hsla(hue, sat * 0.3, 0.9, 1) : Qt.lighter(card, 1.3)
    readonly property color fg: light ? "#16171a" : "#ECEDEE"
    readonly property color dim: light ? "#5a5e66" : "#A9ADB2"
    readonly property color track: light ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.12)
    readonly property color line: light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.06)
}
