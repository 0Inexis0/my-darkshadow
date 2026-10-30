-- starts the desktop widgets and dock (Settings > Desktop / Interface)
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-desktop start")
end)
