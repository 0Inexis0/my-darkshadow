-- keybinds that belong to Shadow's Shell (installed by install.sh, loaded from hyprland.lua)
-- unbind first so only ONE wallpaper menu opens even if another config also binds SUPER + W
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-wallpaper"))
