# Install & update

my-darkshadow is a personal DarkShadowShell fork for NixOS, based on upstream V4.35 (`9109efa`). NixOS and the live ISO provide the complete setup; the original cross-distribution installer is retained.

## Existing NixOS installation

```sh
git clone https://github.com/0Inexis0/my-darkshadow.git
cd my-darkshadow
bash personal/bootstrap.sh --dry-run --system
bash personal/bootstrap.sh --system
```

Run as your normal desktop user. The script asks before installing, requests sudo for system changes, imports `./my-darkshadow.nix` into the existing configuration and runs `nixos-rebuild boot`. Reboot when convenient. Existing hardware configuration, filesystems, bootloader and account names are preserved. An existing display manager can conflict with SDDM; resolve that in your NixOS configuration before rebuilding.

Without `--system`, the bootstrap installs dotfiles and bundled fonts only. On Arch/Fedora it invokes the retained upstream package installer; those paths do not install the NixOS SDDM module.

| Profile | Display | Graphics |
| --- | --- | --- |
| `generic` (default) | Preferred mode; scale 1 until changed in Settings | Host/default graphics configuration |
| `legion` | eDP-1/eDP-2, 2560 × 1600 at 240 Hz, scale 1.6 | Intel microcode; stable open NVIDIA driver; software cursor |

Choose Legion with `--profile legion`. It targets the original laptop and recent NVIDIA hardware supported by the open driver. Change monitors through **SUPER + U**; personal Hyprland overrides belong in `~/.config/hypr/user.lua`.

Existing NixOS flakes can import `nixosModules.personal` and set:

```nix
programs.my-darkshadow = {
  enable = true;
  user = "your-account";
  profile = "generic";
};
```

## Fresh installation from the ISO

Build on x86_64 Linux with Nix enabled:

```sh
nix build .#iso          # generic display and graphics
nix build .#iso-legion   # original Intel/NVIDIA laptop profile
ls result/iso/
```

The flake pins Nixpkgs in `flake.lock`. Write the ISO to a USB drive with your preferred image writer and boot in **UEFI mode**. Secure Boot is not configured by this image.

GitHub limits each release asset to less than 2 GiB. Download every `.iso.part-*` file for your chosen profile, its `PARTSUMS-*` and `SHA256SUMS-*` files, and `assemble-generic.sh` or `assemble-legion.sh`. Put them in one directory and run `bash assemble-generic.sh` (or the Legion equivalent). It checks all parts, joins the ISO and verifies its complete SHA-256 before producing the final file. Locally built ISOs are already a single file. See [GitHub release limits](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas).

The live system logs into the `nixos` account and runs the desktop. Open **Install my-darkshadow** from the launcher, or run `sudo darkshadow-install` in a terminal.

The installer shows unmounted writable disks, asks for an account name and hardware profile, and requires typing `ERASE /dev/your-disk` before writing. It creates GPT, a 512 MiB FAT32 EFI partition, an ext4 root partition and systemd-boot. The account password is entered directly into `passwd`, never into configuration files.

This is a **whole-disk installer**: no dual boot, LUKS encryption or custom partition layout is offered. Mounted disks, including the live boot device, are excluded. For another layout, mount partitions manually and use the normal NixOS installation procedure with `nix/personal.nix` imported.

Internet is required for packages missing from the live Nix store. The desktop configuration, login theme, wallpaper and main fonts are bundled. Only the live installation account has passwordless local installation privileges; installed accounts use your chosen password and root login is locked.

Preview disk selection without writes:

```sh
darkshadow-install --dry-run
```

## Daily use

| Keys | Action |
| --- | --- |
| SUPER + U | Settings |
| SUPER + T | Terminal |
| SUPER + Space | Launcher |
| SUPER + E | Nautilus |
| SUPER + Alt + Space | Toggle floating window |
| SUPER + V | Clipboard |
| SUPER + L | Lock |

The dock pins Nautilus, Brave, Discord and Steam. The bar has four Pac-Man workspaces. Idle times are 10 minutes to lock, 15 to turn displays off and 60 to suspend. Successful Quickshell reloads stay quiet; load errors retain their diagnostic popup.

`rice-scale-sync` follows the main display's scale and publishes XSettings/Xresources DPI for X11 apps. Native Wayland apps keep compositor-managed scaling. Existing X11 apps may need restarting after a DPI change. SDDM reads the same monitor settings through a root service that exports numeric scales to `/run`, without exposing the private home directory.

Clipboard history restores raw text/image bytes without waiting on the background clipboard owner's output pipes. Failed clipboard writes do not trigger a paste of stale content. Opening the panel recovers a missing desktop shell; reopening clears the previous search. Clipboard history and private pins are never part of this repository or its ISO.

The Quickshell recovery fix queries the configuration's instance registry instead of process arguments. Wi-Fi, Bluetooth, sound, power, launcher, gamebar and control-center routing share this check. Stop/restart target only the desktop configuration. `QV4_GC_TIMELIMIT` defaults to `0`, selecting non-incremental garbage collection. It does **not** disable collection; an explicit environment value takes precedence. This is a workaround for observed crashes, not a proven correction of their underlying cause. See [Qt documentation](https://doc.qt.io/qt-6/qtqml-javascript-finetuning.html).

## Update and rollback

For NixOS-managed installations:

```sh
cd ~/my-darkshadow  # or your original checkout
git pull --ff-only
bash personal/bootstrap.sh --system --profile generic
```

Keep the profile used at installation. **Settings → Update Center** checks exact commits on `0Inexis0/my-darkshadow`, branch `main`. On NixOS-managed/ISO installations, **Update now** opens a terminal for your sudo password and build output. It maintains a separate user checkout, preserves the installed hardware profile and runs the bootstrap to stage a new boot generation. Reboot to activate it. Local edits or diverged history in the update checkout stop the update instead of being overwritten. The Nix store is never modified. The manual commands above remain available.

Standalone installs made with `install.sh` use `rice-update` and the same fork's `main`. Update packages with your distribution's package manager. Upstream changes reach this desktop only after they have been integrated into the fork.

The personal deployer backs up replaced files under `~/.local/state/my-darkshadow/backups/`. Later deployments preserve files edited since deployment. `python3 personal/apply.py --force` explicitly replaces edited files while retaining backups. The upstream installer uses its own `~/.config/darkshadows-shell-backup-*` directories. NixOS source backups are stored under `/etc/nixos/before-my-darkshadow-*`.

Boot a previous NixOS generation to roll back packages. Home configuration remains mutable: restore its backup separately if needed. Remove the `./my-darkshadow.nix` import and rebuild to remove the managed desktop.

## Development and releases

```sh
python3 -B -m unittest discover -s tests -v
python3 -B -m unittest discover -s personal/login/tests -p 'test_*.py' -v
python3 personal/check-publication.py
git diff --check
nix flake check --no-build
bash personal/build-iso.sh generic
```

The ISO workflow supports manual builds and `v*` tags, with generic and Legion images and SHA-256 checksums. Files are uploaded directly to a draft release, avoiding intermediate Actions artifact storage. `personal/publish.sh` creates the fork and pushes the reviewed commit when GitHub CLI authentication is available. The fork uses only `main`; upstream history is preserved without force pushes.

Only reviewed configuration is exported. Wi-Fi credentials, browser data, keys, tokens, history, caches, integrity snapshots, private tasks/notes and host filesystem identifiers are excluded. Build products are ignored.

## Credits

Code, logo and original wallpapers: [shadowww-dev](https://github.com/shadowww-dev/DarkShadowShell), MIT. Original credits: [upstream README](docs/UPSTREAM-README.md). Personal integration and login theme: 0Inexis0. Fonts retain their SIL OFL / Apache licenses next to the files in `personal/login/theme/fonts/`.
