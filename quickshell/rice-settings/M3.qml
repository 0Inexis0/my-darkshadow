pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The colors of Settings, in the spirit of Material 3: tonal surfaces and one key color taken from your theme
// (the accent of Theme / your wallpaper). Every part of Settings reads them from here.
Singleton {
    id: m
    property string seed: "#9ec9bd"
    // V4.98 Minimal mode (Settings > Look & Feel; rice-minimal): every corner square
    property bool sq: false
    property string frame: "double"
    property bool minSolid: false      // Minimal mode with Solid windows: no blur, no transparency
    FileView {
        path: Quickshell.env("HOME") + "/.config/rice/minimal.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const j = JSON.parse(text()); m.sq = j.on === true; m.frame = j.frame || "double"; m.minSolid = j.on === true && j.solid === true && (j.v || 1) >= 2 } catch (e) { m.sq = false } }
        onLoadFailed: m.sq = false
    }
    // the accent of your theme (matugen writes it with every new wallpaper): read again whenever it changes, so
    // Settings takes the new colors while it is open (it kept the old ones, e.g. green on a black wallpaper)
    FileView {
        path: Quickshell.env("HOME") + "/.config/waybar/colors.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const r = /@define-color accent *(#[0-9a-fA-F]{6})/.exec(text())
            if (r) m.seed = r[1]
        }
    }

    function rgb(c) { const q = Qt.color(c); return [q.r, q.g, q.b] }
    function mix(a, b, k) { const x = rgb(a), y = rgb(b); return Qt.rgba(x[0] + (y[0] - x[0]) * k, x[1] + (y[1] - x[1]) * k, x[2] + (y[2] - x[2]) * k, 1) }
    function lum(c) { const x = rgb(c); return 0.299 * x[0] + 0.587 * x[1] + 0.114 * x[2] }
    function alpha(c, a) { const x = rgb(c); return Qt.rgba(x[0], x[1], x[2], a) }
    // the key color, light enough to read on the dark surfaces
    function lift(c, target) { let k = 0; while (k < 0.9 && lum(mix(c, "#ffffff", k)) < target) k += 0.05; return mix(c, "#ffffff", k) }

    readonly property color primary: lift(seed, 0.62)
    readonly property color inkPrimary: mix(seed, "#000000", 0.82)
    readonly property color primaryContainer: mix(primary, "#151718", 0.68)
    readonly property color inkPrimaryC: mix(primary, "#ffffff", 0.55)
    readonly property color secondaryContainer: mix(primary, "#1b1d1e", 0.8)
    readonly property color inkSecondaryC: mix(primary, "#ffffff", 0.7)
    readonly property color tertiary: lift(mix(seed, "#e8a87c", 0.55), 0.6)

    // surfaces: near black with a hint of the key color, each container a step lighter
    readonly property color surface: mix("#111213", seed, 0.035)
    readonly property color surfaceLow: mix("#17181a", seed, 0.04)
    readonly property color surfaceC: mix("#1f2023", seed, 0.055)
    readonly property color surfaceHigh: mix("#292a2e", seed, 0.065)
    readonly property color surfaceHighest: mix("#333539", seed, 0.075)
    readonly property color ink: "#E5E3E3"
    readonly property color inkDim: "#B6B8BA"
    readonly property color outline: "#8C8F92"
    readonly property color outlineVariant: "#3B3E42"
    readonly property color error: "#FFB4AB"
    // more roles for Appearance > Colors
    readonly property color secondary: mix(primary, "#c8c8c8", 0.45)
    readonly property color tertiaryContainer: mix(tertiary, "#151718", 0.68)
    readonly property color inkTertiaryC: mix(tertiary, "#ffffff", 0.6)
    readonly property color errorContainer: "#93000A"
    readonly property color inkErrorC: "#FFDAD6"
    readonly property color surfaceLowest: mix("#0c0d0e", seed, 0.03)
    readonly property color surfaceBright: mix("#38393c", seed, 0.08)
    readonly property color inverseSurface: "#E3E2E2"
    readonly property color inversePrimary: mix(seed, "#000000", 0.35)
    // the little stage behind live previews
    readonly property color stageTop: mix(surfaceHigh, primary, 0.14)
    readonly property color stageBottom: surfaceLow

    // shape: corner sizes
    readonly property real shapeK: Prefs.cornerScale
    readonly property int rS: Math.round(10 * shapeK)
    readonly property int rM: Math.round(16 * shapeK)
    readonly property int rL: Math.round(24 * shapeK)
    readonly property int rXL: Math.round(30 * shapeK)
    // Rows next to each other join into one group (Material 3 Expressive, like the settings of Android 16):
    // true when the nearest shown item before (d = -1) or after (d = 1) the host in its Column is a row too.
    // Repeaters and empty spacers are skipped; anything else (a title, a card) ends the group.
    function near(h, d) {
        if (!h || !h.parent) return false
        const p = h.parent
        if (p.spacing === undefined || p.layoutDirection !== undefined) return false
        const c = p.children
        let i = -1
        for (let k = 0; k < c.length; k++) if (c[k] === h) { i = k; break }
        if (i < 0) return false
        for (let k = i + d; k >= 0 && k < c.length; k += d) {
            const s = c[k]
            if (!s || !s.visible) continue
            if (s.joinable === true) return true
            if (s.width === 0 || s.height === 0) continue
            return false
        }
        return false
    }
    // the corners of a grouped row: round at the ends of a group, small inside it
    readonly property int rRowOut: Math.round(22 * shapeK)
    readonly property int rRowIn: Math.round(6 * shapeK)
    readonly property int rowGap: 3
    // motion: Material's emphasized curve, or a small spring (Settings > Motion)
    readonly property var emph: [0.2, 0, 0, 1, 1, 1]
    readonly property bool bouncy: Prefs.motion === "expressive"
    function d(ms) { return Math.round(ms / Prefs.motionSpeed) }
    readonly property int springy: bouncy ? Easing.OutBack : Easing.OutCubic
}
