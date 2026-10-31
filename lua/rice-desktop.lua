-- starts the desktop widgets, dock, hot corner and welcome screen (DarkShadow's Shell)
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-desktop start")
end)
