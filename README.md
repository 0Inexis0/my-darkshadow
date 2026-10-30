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

## Features
- **Settings app** (`SUPER+U`): Waybar layout editor, bar styles (flat, floating, islands, one island), Hyprland options, desktop widgets, dock, lock screen, fonts, autostart.
- **Desktop widgets**: clock, calendar, weather, media player, resources, user card, audio visualizer. Drag them anywhere.
- **Waybar** with presets, autohide, transparency, and a logo that matches your distro (Arch, NixOS, ...).
- Works for **any username**: everything uses `$HOME` and `$USER`.

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
