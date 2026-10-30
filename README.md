<h1 align="center">Shadow’s Shell</h1>
<p align="center">A Hyprland rice with its own Quickshell settings app, Waybar, desktop widgets and a dock.<br>
Made by <a href="https://www.tiktok.com/@shadoww.dev">shadoww.dev</a>.</p>

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
