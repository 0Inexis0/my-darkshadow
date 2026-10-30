# Customize

Everything is in **Settings** (`SUPER+U`). The same actions exist as commands:

```bash
waybar-set style flat|floating|islands|island
waybar-set group none|pills|segmented
waybar-set opacity 0.9
waybar-set island-width 1000      # width of "One island"
waybar-set power-nudge 14         # gap left of the power button
waybar-set power-size 18          # power button icon size
waybar-set distro-icon on|off     # logo that matches your distro
waybar-set autohide on|off
```

## Rofi
Use **Settings > Rofi**, or the command line:

```bash
rice-rofi set theme shadow|graphite|midnight|rose|paper
rice-rofi set layout list|grid|bar
rice-rofi set position top|center|bottom
rice-rofi set transparency on|off
rice-rofi set blur on|off
rice-rofi reset          # defaults
rice-rofi restore        # give back your original rofi and Hyprland files
```
The theme is written to `~/.config/rofi/shadows.rasi` and loaded from `~/.config/rofi/config.rasi`. Your previous `@theme` lines are commented out (backup: `config.rasi.bak-rice-rofi`).
