pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// App icons as plain picture files. Icons.get(name, fallback) gives "file://..." (or "" while it is still being
// looked up, or when there is none): use it in an Image or an IconImage instead of Quickshell.iconPath.
// Why: Quickshell.iconPath goes through Qt's icon theme engine, and with Qt 6.12 (NixOS) that engine crashed
// Quickshell on some icons (the bar, the dock and the widgets went down). Plain files never touch it.
// The lookups run in the background (iconfile.sh), several names at once, and each name only once.
Singleton {
    id: ic
    property var files: ({})          // name -> file ("" = none)
    property int rev: 0               // goes up when new files are known: bindings that use get() look again
    property var pending: []
    property var asked: ({})
    // Edit mode > Icons > Icon pack (V4.89): an icon theme of this computer drawn before the system's one ("" = the system's)
    property string theme: ""
    onThemeChanged: { ic.files = ({}); ic.asked = ({}); ic.pending = []; ic.rev++ }

    // V4.89: the themed looks (Edit mode > Icons): an app drawn as one plain sign in your theme's colors, like the
    // themed icons of Android. Known apps get their own sign (Nerd Font glyphs); others keep their picture, recolored.
    readonly property var glyphRules: [
        [/libreoffice.*writer|writer$/, 0xF37C], [/libreoffice.*calc/, 0xF378], [/libreoffice.*impress/, 0xF37A], [/libreoffice/, 0xF376],
        [/firefox/, 0xF0239], [/chrom(e|ium)/, 0xF02AF], [/msedge|microsoft-edge/, 0xF01E9], [/^opera|\.opera/, 0xF03CE],
        [/discord|vesktop|webcord|armcord|legcord/, 0xF066F], [/spotify/, 0xF04C7], [/steam/, 0xF04D3],
        [/^(code|code-oss|codium|vscodium)$|visual-?studio-?code|com\.visualstudio|vscod/, 0xF0A1E],
        [/kitty|alacritty|^foot|wezterm|ghostty|konsole|terminal|xterm|terminator|tilix|ptyxis|blackbox|console/, 0xF018D],
        [/nautilus|thunar|dolphin|nemo|pcmanfm|file-?manager|darkshadow-files|^files$|yazi/, 0xF024B],
        [/obsidian/, 0xE6BB], [/telegram/, 0xF2C6], [/whatsapp|zapzap/, 0xF05A3], [/thunderbird|betterbird/, 0xF370],
        [/vlc/, 0xF057C], [/^mpv|io\.mpv/, 0xF36E], [/celluloid|haruna|totem|showtime|darkshadow-videos|^videos$/, 0xF0230],
        [/gimp/, 0xF338], [/krita/, 0xF33D], [/inkscape/, 0xF33B], [/blender/, 0xF00AB], [/kdenlive/, 0xF33C],
        [/obs(proj|-studio|$)/, 0xF044B],
        [/settings|control-center|systemsettings|preferences-system/, 0xF0493],
        [/calculator|qalculate|kcalc/, 0xF00EC],
        [/loupe|eog|gthumb|gwenview|^imv|shotwell|darkshadow-photos|^photos$|image-viewer/, 0xF02E9],
        [/rhythmbox|elisa|amberol|lollypop|darkshadow-music|^music$|audio-player/, 0xF075A],
        [/nvim|neovim/, 0xF36F], [/godot/, 0xE7EE], [/minecraft|prismlauncher/, 0xF0373], [/github/, 0xF02A4], [/slack/, 0xF04B1],
        [/heroic|lutris|bottles|retroarch|gamepad|games/, 0xF0297],
        [/btop|htop|system-?monitor|missioncenter|resources/, 0xF0A07], [/pavucontrol|pwvucontrol|volume/, 0xF057E],
        [/text-?editor|gedit|^kate|kwrite|mousepad|notepad|zed/, 0xF021A], [/docker/, 0xF0868], [/android-studio/, 0xF0034],
        [/jetbrains|intellij|idea|pycharm|webstorm|clion|rider|goland/, 0xE808],
        [/mail|geary|evolution/, 0xF01EE], [/calendar/, 0xF00ED], [/weather/, 0xF0595], [/clocks?$|alarm/, 0xF0954],
        [/software|discover|pamac|flathub|bazaar|store/, 0xF04DC], [/camera|cheese|snapshot/, 0xF0100], [/maps/, 0xF034D],
        [/evince|okular|papers|zathura|pdf/, 0xF0226], [/freetube|youtube/, 0xF05C3], [/twitch/, 0xF0543], [/reddit/, 0xF044D],
        [/bitwarden|keepass|password|seahorse|secrets/, 0xF0306], [/blueman|bluetooth/, 0xF00AF],
        [/qbittorrent|transmission|deluge|fragments|torrent/, 0xF01DA], [/file-roller|^ark$|archive/, 0xF03D6], [/dropbox/, 0xF01E3]
    ]
    function glyphOf(keys) {
        for (let k = 0; k < keys.length; k++) {
            const n = String(keys[k] || "").toLowerCase().replace(/\.desktop$/, "")
            if (n === "") continue
            for (let i = 0; i < glyphRules.length; i++) if (glyphRules[i][0].test(n)) return String.fromCodePoint(glyphRules[i][1])
        }
        return ""
    }

    // our own apps (Files, Photos, Music, Videos) are Quickshell windows: their title says which one, so they get
    // their own entry and icon (darkshadow-files ...) instead of Quickshell's
    function appKey(appId, title) {
        const id = String(appId || "").toLowerCase()
        if (id === "" || id.indexOf("quickshell") >= 0) {
            const m = /^(Files|Photos|Music|Videos)( — |$)/.exec(String(title || ""))
            if (m) return "darkshadow-" + m[1].toLowerCase()
        }
        return id
    }
    function get(n, fallback) {
        const r = ic.rev                // (makes the binding depend on new lookups)
        const p = one(n)
        if (p !== "") return p
        if (typeof fallback === "string" && fallback !== "") return one(fallback)
        return ""
    }
    // a tray icon or a menu icon: "image://icon/NAME" (Qt's theme engine) becomes the file; others stay as they are
    function src(u) {
        const r = ic.rev
        if (!u) return ""
        u = String(u)
        if (u.indexOf("image://icon/") !== 0) return u
        let n = u.substring(13), dir = ""
        const q = n.indexOf("?")
        if (q >= 0) {
            // apps like Spotify, Discord or Steam bring their own icon folder: image://icon/NAME?path=FOLDER
            const m = /(?:^|&)path=([^&]*)/.exec(n.substring(q + 1))
            if (m) { try { dir = decodeURIComponent(m[1]) } catch (e) { dir = m[1] } }
            n = n.substring(0, q)
        }
        try { n = decodeURIComponent(n) } catch (e) {}
        // never an empty spot in the tray: the app's own name, then a plain app icon
        const p = one(dir !== "" ? n + "|" + dir : n)
        return p !== "" ? p : one("application-x-executable")
    }
    function one(n) {
        if (!n) return ""
        n = String(n)
        if (n.indexOf("file://") === 0) return n
        if (n.indexOf("://") > 0) return ""          // other providers: not ours to draw
        const f = ic.files[n]
        if (f !== undefined) return f !== "" ? "file://" + f : ""
        if (!ic.asked[n]) { ic.asked[n] = true; ic.pending.push(n); batch.restart() }
        return ""
    }
    Timer { id: batch; interval: 40; onTriggered: ic.next() }
    function next() {
        if (look.running || ic.pending.length === 0) return
        look.names = ic.pending.splice(0, 60)
        look.running = true
    }
    Process {
        id: look
        property var names: []
        command: ["env", "RICE_ICON_THEME=" + ic.theme, "bash", Quickshell.shellPath("iconfile.sh")].concat(names)
        stdout: StdioCollector {
            onStreamFinished: {
                const f = Object.assign({}, ic.files)
                text.split("\n").forEach(function(l) {
                    const i = l.indexOf("\t")
                    if (i > 0) f[l.substring(0, i)] = l.substring(i + 1).trim()
                })
                look.names.forEach(function(n) { if (f[n] === undefined) f[n] = "" })
                ic.files = f
                ic.rev++
                if (ic.pending.length > 0) batch.restart()
            }
        }
    }
}
