<p align="center">
  <img src="assets/banner.svg" alt="Shadow's Shell" width="100%">
</p>

<p align="center">
  <b>A Hyprland rice with its own Quickshell settings app, Waybar, desktop widgets and a dock.</b><br>
  Made by <a href="https://www.tiktok.com/@shadoww.dev">shadoww.dev</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NixOS-supported-5277C3?style=for-the-badge&logo=nixos&logoColor=white" alt="NixOS">
  <img src="https://img.shields.io/badge/Arch_Linux-supported-1793D1?style=for-the-badge&logo=archlinux&logoColor=white" alt="Arch Linux">
  <img src="https://img.shields.io/badge/Hyprland-0.55-58E1FF?style=for-the-badge&logoColor=white" alt="Hyprland">
  <img src="https://img.shields.io/badge/Quickshell-QML-8B7BFF?style=for-the-badge" alt="Quickshell">
</p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#features">Features</a> ·
  <a href="docs/INSTALL.md">Docs</a> ·
  <a href="docs/CUSTOMIZE.md">Customize</a>
</p>

---

## Screenshot
<p align="center">
  <img src="assets/screenshot.png" alt="Shadow's Shell on NixOS" width="100%">
</p>
<p align="center">
  <img src="assets/screenshot-settings.png" alt="The Settings app (SUPER+U)" width="100%"><br>
  <sub>The Settings app (<code>SUPER + U</code>) and the hot corner panel</sub>
</p>

## Features
**Settings app** (`SUPER+U`), twelve pages: Home, Waybar, Hyprland, Rofi, Theme, Notifications, Idle & Lockscreen, Desktop, Hot corners, Interface, Services, About.

| Area | What you get |
| --- | --- |
| **Waybar** | layout editor (move modules between left, center and right), saved presets, position top or bottom, bar height, opacity |
| **Bar styles** | Flat, Floating, Islands, **One island**; group styles None, Pills, Segmented |
| **Autohide** | bar slides in when the pointer touches the screen edge |
| **Distro logo** | NixOS logo on NixOS, Arch logo on Arch, and so on |
| **Hot corner** | touch a screen corner for a panel with Keep Awake, screen recording, screenshots, quick toggles (Wi-Fi, Bluetooth, Do Not Disturb, Gaming mode, microphone, Settings) and now playing; sections, toggles, corner, look and animation are set in Settings > Hot corners |
| **Desktop widgets** | clock (big or small), calendar, weather, media player, resources (CPU, RAM, GPU), user card, audio visualizer; drag them anywhere |
| **Dock** | pinned apps, hover to reveal, media player, tinted icons |
| **Hyprland** | gaps, borders, rounding, blur, shadows and animations from sliders, no config editing |
| **Theme** | 21 color schemes: Auto and Grey from your wallpaper, six monochrome (Mono, Slate, Stone, Steel, Ash, Ink) and thirteen colors (Navy, Ocean, Sky, Teal, Mint, Forest, Lime, Gold, Sunset, Ember, Rose, Orchid, Violet). They recolor Waybar, borders, notifications and the lock screen |
| **Notifications** | swaync popups and panel: position, layout, widgets (title, Do Not Disturb, media, volume, quick buttons), size, timeout, icon size, Glass / Solid / Outline look, opacity, radius, blur, live preview and a test button |
| **Idle & Lockscreen** | lock, screen-off and sleep timers; lock screen with Big / Stacked / Minimal clock, center or left layout, greeting, avatar, Pill / Box / Line password field, power buttons, screenshot / wallpaper / color background and media, resources, weather and notification lines |
| **Rofi** | 5 themes (Shadow, Graphite, Midnight, Rose, Paper), layouts list / grid / full-width bar, position top, center or bottom, width, rows, corner radius, transparency, blur, font size, icons |
| **Fonts** | one place to set the main and icon fonts |
| **Notifications** | swaync with a button that opens Settings |
| **Welcome window** | "Welcome to Shadow's Shell" greeting once per login; turn off with `rice-welcome off` or the link in the window |
| **Installer** | interactive, backs up everything, supports Arch and NixOS |

## Keybinds
`SUPER` is the main modifier.

| Keys | Action |
| --- | --- |
| `SUPER + U` | open **Settings** |
| `SUPER + W` | wallpaper menu |
| `SUPER + Q` | terminal |
| `SUPER + E` | file manager |
| `SUPER + R` | app menu |
| `ALT + Space` | app launcher (rofi) |
| `SUPER + C` | close window |
| `SUPER + V` | toggle floating |
| `SUPER + P` | pseudo-tile |
| `SUPER + J` | toggle split direction |
| `SUPER + M` | exit Hyprland |
| `SUPER + ←/→/↑/↓` | move focus |
| `SUPER + 1 … 0` | go to workspace |
| `SUPER + SHIFT + 1 … 0` | move window to workspace |
| `SUPER + S` | show/hide scratchpad |
| `SUPER + SHIFT + S` | move window to scratchpad |
| `SUPER + scroll` | next/previous workspace |
| `SUPER + left mouse` | drag window |
| `SUPER + right mouse` | resize window |
| `ALT + ]` / `ALT + [` | volume up / down |
| `SUPER + F12` / `F11` / `F10` | volume up / down / mute (with on-screen display) |
| media keys | play/pause, next, previous |

## Install
```bash
git clone https://github.com/shadowww-dev/shadows-shell
cd shadows-shell
./install.sh
```
The installer is interactive (arrow keys + space). Useful flags: `--yes` (no questions), `--dry-run` (change nothing), `--restore` (undo with the last backup).

| System | What happens |
| --- | --- |
| **Arch** and derivatives (CachyOS, EndeavourOS, Manjaro) | packages are installed with `pacman` (+ `paru`/`yay` for AUR) |
| **NixOS** | add `nix/module.nix` (or the flake module) to your config, then `nixos-rebuild switch`; the installer does the rest |
| other | the installer lists the programs you need |

See [docs/INSTALL.md](docs/INSTALL.md) and [docs/CUSTOMIZE.md](docs/CUSTOMIZE.md).

## Layout
| Path | Contents |
| --- | --- |
| `bin/` | helper scripts installed to `~/.local/bin` |
| `quickshell/` | Settings app (`rice-settings`) and widgets/dock (`rice-desktop`) |
| `config/` | dotfiles installed to `~/.config` (Hyprland, Waybar, ...) |
| `install/` | installer UI and distro detection |
| `nix/`, `flake.nix` | NixOS module |
| `.github/` | CI (shellcheck, dry-run install) and issue template |

## Maintainers
`./sync.sh` copies your current setup from this machine into the repo (paths become `@HOME@`, no username is stored) and scans for secrets.

## License
Not chosen yet. Add a `LICENSE` file before sharing widely.
