-- keybinds that belong to DarkShadow's Shell (installed by install.sh, loaded from hyprland.lua)
local bin = os.getenv("HOME") .. "/.local/bin/"

-- wallpaper picker: unbind first so only ONE menu opens even if another config also binds SUPER + W
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd(bin .. "rice-wallpaper"))

-- volume, microphone and brightness: laptop Fn keys and headset +/- buttons
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(bin .. "rice-media up"),          { locked = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(bin .. "rice-media down"),        { locked = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(bin .. "rice-media mute"),        { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(bin .. "rice-media mic"),         { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(bin .. "rice-media bright-up"),   { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(bin .. "rice-media bright-down"), { locked = true })

-- screenshots and screen recording
hl.bind("Print",               hl.dsp.exec_cmd(bin .. "rice-hotcorner shot region"))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd(bin .. "rice-hotcorner shot full"))
hl.bind("SUPER + SHIFT + R",   hl.dsp.exec_cmd(bin .. "rice-hotcorner record region"))   -- press again to stop
hl.bind("SUPER + A",           hl.dsp.exec_cmd(bin .. "rice-hotcorner open"))
