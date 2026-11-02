pragma Singleton
import Quickshell
import QtQuick

// How see-through the desktop widgets are, and what colors they take. shell.qml fills this in from desktop.json and rice-effects.
Singleton {
    id: look
    // blurred wallpaper behind the cards (Settings > Widgets > Blur)
    property bool blur: true
    // no blur and no transparency at all (Settings > Services: Lite, or gaming mode)
    property bool flat: false
    // Light mode (Settings > Home): the visualizer stops and widgets pause while a window covers them
    property bool lite: false
    // widget style (Settings > Widgets > Theme): shadow (DarkShadow's Shell), google, outline
    property string theme: "shadow"
    // text and cards turn light or dark with the wallpaper behind each widget (Settings > Widgets)
    property bool adapt: true
    // the accent color of your theme (Waybar colors), used by the Google style and the visualizer
    property color accent: "#9ec9bd"

    // brightness of the wallpaper (shell.qml's WallLum reads it): lumW x lumH cells, each 0 (black) .. 1 (white)
    property var lumGrid: []
    property int lumW: 64
    property int lumH: 36
    // average brightness of a rectangle of the screen (x, y, w, h in screen pixels); 0.3 until the wallpaper is read
    function lumAt(x, y, w, h, sw, sh) {
        const g = lumGrid
        if (!g || g.length < lumW * lumH || sw <= 0 || sh <= 0) return 0.3
        const x0 = Math.max(0, Math.min(lumW - 1, Math.floor(x / sw * lumW)))
        const x1 = Math.max(x0, Math.min(lumW - 1, Math.floor((x + w) / sw * lumW)))
        const y0 = Math.max(0, Math.min(lumH - 1, Math.floor(y / sh * lumH)))
        const y1 = Math.max(y0, Math.min(lumH - 1, Math.floor((y + h) / sh * lumH)))
        let s = 0, n = 0
        for (let j = y0; j <= y1; j++)
            for (let i = x0; i <= x1; i++) { s += g[j * lumW + i]; n++ }
        return n > 0 ? s / n : 0.3
    }
}
