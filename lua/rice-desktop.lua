-- starts the desktop widgets, dock, hot corner and welcome screen (DarkShadow's Shell)
hl.on("hyprland.start", function()
    -- without systemd (Void): PipeWire and the password prompt agent are started here
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-sys session")
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-desktop start")
    -- your cursor from Settings > Cursors (Bibata Modern Ice by default)
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-cursor restore")
end)

-- blurred Files (see rice-look) and floating pop-up apps.
-- pcall: if your Hyprland does not know a key, it is skipped instead of breaking the config.
local function rule(r) pcall(hl.window_rule, r) end
-- Files is see-through through its own colors (rice-look: darkshadow.css), so its text stays sharp and the blur shows
rule({ name = "rice-calendar-float", match = { class = "org.gnome.Calendar" }, float = true, center = true, size = "900 650" })

-- full-screen layers that animate themselves: no extra pop-in from Hyprland
pcall(hl.layer_rule, { name = "rice-welcome-noanim", match = { namespace = "rice-welcome" }, no_anim = true })
pcall(hl.layer_rule, { name = "rice-tour-dim-noanim", match = { namespace = "rice-tour-dim" }, no_anim = true })
-- Infinite Desktop's moving wallpaper starts exactly over the wallpaper and animates itself
pcall(hl.layer_rule, { name = "rice-wallcanvas-noanim", match = { namespace = "rice-wallcanvas" }, no_anim = true })

-- the bar and its island: blurred here too (rice-rofi.lua has the same rule, but it is only wired in once Settings >
-- Launcher was used: on a fresh install the bar had no blur at all)
pcall(hl.layer_rule, { name = "rice-bar-blur-desktop", match = { namespace = "rice-bar" }, blur = true, ignore_alpha = 0.25 })
