# Installation

## Arch Linux (and derivatives)
```bash
git clone https://github.com/shadowww-dev/shadows-shell && cd shadows-shell
./install.sh
```
The installer runs `sudo pacman -S --needed` for packages found in the repos and uses `paru` or `yay` for the rest (for example `quickshell`, `awww`). Without an AUR helper it prints the list for you to install.

## NixOS
Packages are declared in your system configuration, so the installer only prints the snippet.

Without flakes, in `configuration.nix`:
```nix
imports = [ /path/to/shadows-shell/nix/module.nix ];
```
With flakes:
```nix
inputs.shadows-shell.url = "github:shadowww-dev/shadows-shell";
# in your nixosSystem modules list:
shadows-shell.nixosModules.default
```
Run `sudo nixos-rebuild switch`, then `./install.sh` and choose Tools, Apps and Dotfiles.

## Backups and undo
Every file the installer replaces is copied to `~/.config/darkshadows-shell-backup-<time>/`. Undo with `./install.sh --restore`.

## Other distros
The installer lists missing programs (Hyprland, Waybar, Quickshell `qs`, swaync, cava, rofi, jq, python3, awww, hyprlock). Install them with your package manager, then run `./install.sh`.
