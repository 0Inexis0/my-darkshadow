-- keybinds that belong to Shadow's Shell (installed by install.sh, loaded from hyprland.lua)
-- unbind first so only ONE wallpaper menu opens even if another config also binds SUPER + W
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-wallpaper"))

-- blur behind the welcome window
hl.layer_rule({
    name  = "rice-welcome-blur",
    match = { namespace = "rice-welcome" },
    blur = true,
    ignore_alpha = 0.1,
})

