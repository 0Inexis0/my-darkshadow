# Installation

## Arch Linux (and CachyOS, EndeavourOS, Garuda)
```bash
git clone https://github.com/shadowww-dev/DarkShadowShell && cd DarkShadowShell
./install.sh
```
The installer runs `sudo pacman -S --needed` for packages found in the repos and uses `paru` or `yay` for the rest (for example `quickshell`, `awww`). Without an AUR helper it prints the list for you to install.

CachyOS works the same way: its repositories are used and `paru`, which CachyOS ships, installs the AUR packages. Manjaro holds packages back, so its Hyprland can be older than 0.55 (the config needs 0.55); the installer tells you at the end.

## Artix Linux (OpenRC, runit, s6, dinit)
Same commands as Arch. Without systemd the installer also:
- turns on Arch's `[extra]` repository (`artix-archlinux-support`) when Hyprland is not in Artix's own repositories
- installs Artix's service scripts for your init (`networkmanager-openrc`, `bluez-openrc` ...) and turns on D-Bus, elogind, NetworkManager, Bluetooth and power modes
- adds the login sessions **Hyprland (DarkShadow)** and **niri (DarkShadow)**, which start with their own D-Bus. Pick one of them on the login screen; from a text console run `dbus-run-session Hyprland`

PipeWire and the password prompt agent are started by the shell itself at login (`rice-sys session`). With an NVIDIA card add `nvidia-drm.modeset=1` to the kernel command line first.

## Fedora (and Nobara)
```bash
sudo dnf install -y git
git clone https://github.com/shadowww-dev/DarkShadowShell && cd DarkShadowShell
./install.sh
```
Hyprland, its tools and Quickshell come from the `nett00n/hyprland` COPR, `awww` from `scottames/awww`. Packages Fedora does not have are listed and skipped. Fedora Atomic (Bazzite, Silverblue): the installer prints the `rpm-ostree` commands.

## NixOS
Packages are declared in your system configuration, so the installer only prints the snippet.

Without flakes, in `configuration.nix`:
```nix
imports = [ /path/to/DarkShadowShell/nix/module.nix ];
```
With flakes:
```nix
inputs.DarkShadowShell.url = "github:shadowww-dev/DarkShadowShell";
# in your nixosSystem modules list:
DarkShadowShell.nixosModules.default
```
Run `sudo nixos-rebuild switch`, then `./install.sh` and choose Tools, Apps and Dotfiles.

## Backups and undo
Every file the installer replaces is copied to `~/.config/darkshadows-shell-backup-<time>/`. Undo with `./install.sh --restore`.

## Other distros
The installer lists missing programs (Hyprland, Waybar, Quickshell `qs`, swaync, cava, rofi, jq, python3, awww, hyprlock). Install them with your package manager, then run `./install.sh`.
