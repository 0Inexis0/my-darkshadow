pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The colors, fonts, shapes and motion of the DarkShadow apps (Files, Photos, Player).
// The colors are the Material 3 roles matugen makes from your wallpaper (~/.config/rice/palette.json), read again when
// the wallpaper changes. The Player can lay a color of its own over them (the album cover's: `dyn`).
Singleton {
    id: t
    property var p: ({})
    property string dyn: ""
    readonly property string home: Quickshell.env("HOME")

    FileView {
        path: t.home + "/.config/rice/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { t.p = JSON.parse(text()) } catch (e) { } }
    }
    // without palette.json (matugen never ran): the accent of the bar's colors, like Settings
    property string seed: "#a8c7fa"
    FileView {
        path: t.home + "/.config/waybar/colors.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { const r = /@define-color accent *(#[0-9a-fA-F]{6})/.exec(text()); if (r) t.seed = r[1] }
    }

    function rgb(c) { const q = Qt.color(c); return [q.r, q.g, q.b] }
    function mix(a, b, k) { const x = rgb(a), y = rgb(b); return Qt.rgba(x[0] + (y[0] - x[0]) * k, x[1] + (y[1] - x[1]) * k, x[2] + (y[2] - x[2]) * k, 1) }
    function lum(c) { const x = rgb(c); return 0.299 * x[0] + 0.587 * x[1] + 0.114 * x[2] }
    function alpha(c, a) { const x = rgb(c); return Qt.rgba(x[0], x[1], x[2], a) }
    function lift(c, target) { let k = 0; while (k < 0.9 && lum(mix(c, "#ffffff", k)) < target) k += 0.05; return mix(c, "#ffffff", k) }
    function role(k, d) { const v = p[k]; return (typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)) ? v : d }

    readonly property bool hasPal: role("primary", "") !== ""
    readonly property color key: hasPal ? role("primary", seed) : lift(seed, 0.62)
    // the cover's color (Player) wins over the wallpaper's
    readonly property color primary: dyn !== "" ? lift(dyn, 0.6) : key
    readonly property bool dark: lum(surface) < 0.5
    readonly property color inkPrimary: dyn !== "" ? mix(dyn, "#000000", 0.78) : role("on_primary", mix(primary, "#000000", 0.78))
    readonly property color primaryContainer: dyn !== "" ? mix(primary, "#121316", 0.66) : role("primary_container", mix(primary, "#121316", 0.66))
    readonly property color inkPrimaryC: dyn !== "" ? mix(primary, "#ffffff", 0.6) : role("on_primary_container", mix(primary, "#ffffff", 0.6))
    readonly property color secondary: dyn !== "" ? mix(primary, "#c4c6cc", 0.45) : role("secondary", mix(primary, "#c4c6cc", 0.45))
    readonly property color secondaryContainer: dyn !== "" ? mix(primary, "#1c1d21", 0.78) : role("secondary_container", mix(primary, "#1c1d21", 0.78))
    readonly property color inkSecondaryC: mix(secondaryContainer, "#ffffff", 0.82)
    readonly property color tertiary: dyn !== "" ? lift(mix(dyn, "#e8a87c", 0.5), 0.6) : role("tertiary", lift(mix(seed, "#e8a87c", 0.55), 0.6))
    readonly property color tertiaryContainer: mix(tertiary, "#121316", 0.66)
    readonly property color inkTertiaryC: mix(tertiary, "#ffffff", 0.6)
    readonly property color error: role("error", "#ffb4ab")
    readonly property color errorContainer: "#93000a"
    readonly property color inkErrorC: "#ffdad6"

    function tint(base, k) { return dyn !== "" ? mix(base, dyn, k) : base }
    readonly property color surface: tint(role("surface", mix("#111214", seed, 0.04)), 0.05)
    readonly property color surfaceLowest: mix(surface, "#000000", 0.35)
    readonly property color surfaceLow: tint(role("surface_low", mix("#18191c", seed, 0.05)), 0.05)
    readonly property color surfaceC: tint(role("surface_container", mix("#1d1e22", seed, 0.06)), 0.06)
    readonly property color surfaceHigh: tint(role("surface_high", mix("#27292c", seed, 0.07)), 0.07)
    readonly property color surfaceHighest: tint(role("surface_highest", mix("#323337", seed, 0.08)), 0.08)
    readonly property color ink: role("on_surface", "#e3e2e6")
    readonly property color inkVar: role("on_surface_variant", "#c4c6d0")
    readonly property color outline: role("outline", "#8e9099")
    readonly property color outlineVariant: role("outline_variant", "#44474e")
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.55)
    // little colors for kinds of files (folders take the key color)
    readonly property var kinds: ({ image: "#f2b8b5", video: "#ffb870", audio: "#d0bcff", doc: "#a8c7fa", code: "#9fe0b0",
                                    archive: "#e6c07a", pdf: "#ff8e80", app: "#8fd1ff", other: "#c4c6d0" })
    function kindColor(k) { return mix(kinds[k] || kinds.other, primary, 0.25) }

    // fonts: what Settings > Fonts picked for the interface, else Google Sans Flex, Rubik, Inter
    readonly property var fams: Qt.fontFamilies()
    function has(n) { return fams.indexOf(n) >= 0 }
    property string fontPick: ""
    readonly property string font: fontPick !== "" && has(fontPick) ? fontPick : (has("Google Sans Flex") ? "Google Sans Flex" : (has("Rubik") ? "Rubik" : (has("Inter") ? "Inter" : "sans-serif")))
    readonly property bool symbols: has("Material Symbols Rounded")
    readonly property string mono: has("JetBrainsMono Nerd Font") ? "JetBrainsMono Nerd Font" : "monospace"
    FileView {
        path: t.home + "/.config/rice/fonts.json"
        printErrors: false
        onLoaded: { try { t.fontPick = JSON.parse(text()).main || "" } catch (e) { } }
    }

    // shapes (Settings > Appearance > Shapes scales every corner)
    property real cornerScale: 1
    readonly property int rXS: Math.round(6 * cornerScale)
    readonly property int rS: Math.round(10 * cornerScale)
    readonly property int rM: Math.round(14 * cornerScale)
    readonly property int rL: Math.round(20 * cornerScale)
    readonly property int rXL: Math.round(28 * cornerScale)
    // motion: Material's emphasized curves
    readonly property var emph: [0.2, 0, 0, 1, 1, 1]
    readonly property var decel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accel: [0.3, 0, 0.8, 0.15, 1, 1]
    property real speed: 1
    function d(ms) { return Math.round(ms / speed) }

    // a file's path as a URL for Image and MediaPlayer ("#", "?" and spaces in names would break a plain "file://" + path)
    function url(path) { return path ? "file://" + String(path).split("/").map(encodeURIComponent).join("/") : "" }
    function size(b) {
        if (b === undefined || b === null || b < 0) return ""
        if (b < 1000) return b + " B"
        const u = ["kB", "MB", "GB", "TB"]
        let v = b / 1000, i = 0
        while (v >= 1000 && i < u.length - 1) { v /= 1000; i++ }
        return (v < 10 ? v.toFixed(1) : Math.round(v)) + " " + u[i]
    }
    function when(dt) {
        if (!dt) return ""
        const d = new Date(dt), now = new Date()
        if (isNaN(d.getTime())) return ""
        const day = 86400000
        const t0 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
        if (d.getTime() >= t0) return Qt.formatTime(d, "hh:mm")
        if (d.getTime() >= t0 - day) return "Yesterday " + Qt.formatTime(d, "hh:mm")
        if (d.getFullYear() === now.getFullYear()) return Qt.formatDate(d, "d MMM")
        return Qt.formatDate(d, "d MMM yyyy")
    }
    function clock(s) {
        if (!(s >= 0) || !isFinite(s)) return "0:00"
        s = Math.floor(s)
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = s % 60
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (x < 10 ? "0" : "") + x
    }
    // what kind a file is, from its name
    function kind(name, isDir) {
        if (isDir) return "folder"
        const e = String(name).toLowerCase().replace(/^.*\./, "")
        if (/^(jpe?g|png|webp|gif|bmp|svg|avif|heic|tiff?|ico|jxl)$/.test(e)) return "image"
        if (/^(mp4|mkv|webm|mov|avi|m4v|flv|wmv|ogv)$/.test(e)) return "video"
        if (/^(mp3|flac|ogg|opus|wav|m4a|aac|wma|alac|aiff?)$/.test(e)) return "audio"
        if (/^(zip|tar|gz|tgz|xz|zst|bz2|7z|rar|iso|deb|rpm)$/.test(e)) return "archive"
        if (e === "pdf") return "pdf"
        if (/^(txt|md|odt|docx?|rtf|org|log|csv|ods|xlsx?|odp|pptx?|epub)$/.test(e)) return "doc"
        if (/^(sh|py|js|ts|qml|c|cpp|h|rs|go|java|lua|json|toml|ya?ml|kdl|conf|css|html|xml|ini|nix|fish)$/.test(e)) return "code"
        if (/^(appimage|desktop|exe|flatpakref)$/.test(e)) return "app"
        return "other"
    }
    function kindIcon(k) {
        return ({ folder: "folder", image: "image", video: "movie", audio: "music_note", archive: "folder_zip",
                  pdf: "picture_as_pdf", doc: "description", code: "code", app: "rocket_launch", other: "draft" })[k] || "draft"
    }
}
